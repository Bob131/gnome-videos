class Pipeline : Gst.Pipeline {
    dynamic Gst.Element source;
    dynamic Gst.Element decoder;

    Gst.Element audio_sink;
    ClutterGst.VideoSink video_sink;
    public SubOverlayConverter subtitle_overlay;

    const string extra_subtitle_caps = "application/x-ass; application/x-ssa";

    void handle_decoder_pad (Gst.Pad pad) {
        if ((void*) pad.template == null)
            return;

        pad.add_probe (Gst.PadProbeType.EVENT_BOTH, (pad, info) => {
            var event = info.get_event ();

            unowned Gst.Structure event_structure =
                (Gst.Structure?) event.get_structure () != null ?
                    event.get_structure ().copy ()
                    : new Gst.Structure.empty ("empty");

            var event_copy = new Gst.Event.custom (event.type,
                event_structure.copy ());
            event_copy.seqnum = event.seqnum;
            event_copy.timestamp = event.timestamp;

            Idle.add (() => {
                var ev = new PadEvent (event_copy);
                Bus.@get ().pipeline_event[ev.event_type.to_nick ()] (ev);
                return Source.REMOVE;
            });

            return Gst.PadProbeReturn.OK;
        });

        Gst.Element sink;
        Gst.Element? convert = null;

        switch (pad.template.name_template) {
            case "video_%u":
                sink = video_sink;
                convert = subtitle_overlay;
                break;
            case "audio_%u":
                sink = audio_sink;
                convert =
                    null_cast (Gst.ElementFactory.make ("audioconvert", null));
                break;
            case "text_%u":
                sink = subtitle_overlay;
                break;
            default:
                var subtitle_caps = Gst.Caps.from_string (extra_subtitle_caps);
                var pad_caps = pad.query_caps (null);
                if (subtitle_caps.can_intersect (pad_caps)) {
                    sink = subtitle_overlay;
                    break;
                }

                warning ("Failed to link sink for type '%s'",
                    pad.template.name_template.replace ("_%u", ""));
                return;
        }

        if (sink.get_parent () == null)
            this.add (sink);

        sink.set_state (this.current_state);

        if (convert == null)
            warn_if_fail (decoder.link (sink));
        else {
            this.add ((!) convert);
            ((!) convert).set_state (this.current_state);

            warn_if_fail (decoder.link ((!) convert)
                && ((!) convert).link (sink));
        }
    }

    public void select_streams (List<string> stream_list) {
        var event = new Gst.Event.select_streams ((List<char>) stream_list);
        decoder.send_event (event);
    }

    public Nanoseconds get_duration () {
        Nanoseconds ret;
        return_if_fail (this.query_duration (Gst.Format.TIME, out ret));
        return ret;
    }

    public Nanoseconds get_position () {
        Nanoseconds ret;
        this.query_position (Gst.Format.TIME, out ret);
        return ret;
    }

    public new void seek (Nanoseconds pos)
        requires (this.current_state >= Gst.State.PAUSED)
    {
        pos = pos.clamp (0, get_duration ());
        if (!this.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH, pos))
            warning ("Seek failed!");
    }

    public void frame_step (int frames)
        requires (frames != 0)
    {
        // TODO: Calculate time based on video frame rate instead of assuming
        // 24 fps.
        seek (get_position () + frames * Gst.SECOND / 24);
    }

    void handle_bus_message (Gst.Message message) {
        switch (message.type) {
            case Gst.MessageType.ERROR:
                Error e; string debug;
                message.parse_error (out e, out debug);
                warning (debug);
                Bus.@get ().error (e);
                break;
        }

        var event = new BusEvent (message);
        Bus.@get ().pipeline_event[event.event_type.to_nick ()] (event);
    }

    bool has_video;

    void detect_video (Event event) {
        has_video = false;

        var streams = event.parse_streams ();

        for (var i = 0; i < streams.get_size (); i++)
            if (Gst.StreamType.VIDEO in streams.get_stream (i).stream_type) {
                has_video = true;
                return;
            }
    }

    void handle_cover (List<ValueWrapper> values) {
        if (has_video)
            return;

        Gst.Sample? cover_sample = null;

        foreach (var sample_wrapper in values) {
            var sample = (Gst.Sample) sample_wrapper.@value;

            Gst.Caps caps = null_cast (sample.get_caps ());

            int image_type = Gst.Tag.ImageType.UNDEFINED;
            caps.get_structure (0).get_enum ("image-type",
                typeof (Gst.Tag.ImageType), out image_type);

            if (image_type == Gst.Tag.ImageType.FRONT_COVER) {
                cover_sample = sample;
                break;
            } else if (image_type == Gst.Tag.ImageType.UNDEFINED
                    && cover_sample == null)
                cover_sample = sample;
        }

        if (cover_sample == null || ((!) cover_sample).get_buffer () == null)
            return;

        has_video = true;

        // TODO: fix seek failed warning

        Gst.App.Src source = null_cast (
            Gst.ElementFactory.make ("appsrc", null));

        var template = new Gst.PadTemplate ("sink_%u", Gst.PadDirection.SINK,
            Gst.PadPresence.REQUEST, (!) ((!) cover_sample).get_caps ());
        decoder.request_pad (template, null, null);

        this.add (source);
        return_if_fail (source.link (decoder));

        source.set_state (this.current_state);

        source.push_sample ((!) cover_sample);
    }

    public Pipeline (File file) {
        source = null_cast (Gst.ElementFactory.make ("urisourcebin", "source"));
        decoder = null_cast (Gst.ElementFactory.make ("decodebin3", "decoder"));

        unowned Gst.Caps decoder_caps = decoder.caps;
        var extra_decoder_caps = Gst.Caps.from_string (extra_subtitle_caps);
        decoder.caps = decoder_caps.merge (extra_decoder_caps);

        video_sink = new ClutterGst.VideoSink ();
        audio_sink =
            null_cast (Gst.ElementFactory.make ("autoaudiosink", null));
        subtitle_overlay = new SubOverlayConverter ();

        Bus.@get ().object_constructed["video-sink"] (video_sink);

        this.add_many (source, decoder);

        source.pad_added.connect ((pad) => {
            if (!source.link (decoder))
                warning ("Failed to link source to decoder");
        });

        decoder.pad_added.connect (handle_decoder_pad);

        Bus.@get ().pipeline_event["stream-collection"].connect (detect_video);
        Bus.@get ().tag_updated[Gst.Tags.IMAGE].connect (handle_cover);

        var bus = this.get_bus ();
        bus.add_signal_watch ();
        bus.message.connect (handle_bus_message);

        source.uri = file.get_uri ();
    }
}
