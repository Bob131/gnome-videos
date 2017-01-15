class SubOverlayConverter : Gst.Bin {
    public Gst.GhostPad video_sink_pad {private set; get;}
    public Gst.GhostPad sub_sink_pad {private set; get;}
    public Gst.GhostPad src_pad {private set; get;}

    static Gst.PadTemplate sub_sink_template;

    dynamic Gst.Element render;
    dynamic Gst.Element overlay;
    Gst.Element convert;

    public bool enable_subtitles {
        set {
            if (((!) video_sink_pad.get_target ()).parent == render)
                render.enable = value;
            else if (((!) video_sink_pad.get_target ()).parent == overlay)
                overlay.silent = !value;
        }
    }

    void switch_sink (
        Gst.Element target_sink,
        Gst.Pad target_video_sink_pad,
        Gst.Pad? target_sub_sink_pad
    ) {
        ulong p = 0;
        p = video_sink_pad.add_probe (Gst.PadProbeType.BLOCK_DOWNSTREAM, () => {
            video_sink_pad.remove_probe (p);

            var video_sink_sink_pad = (!) video_sink_pad.get_target ();
            var current_video_sink = (Gst.Element) video_sink_sink_pad.parent;
            var video_sink_src_pad = current_video_sink.srcpads.nth_data (0);

            if (target_sink == current_video_sink)
                return Gst.PadProbeReturn.OK;

            video_sink_src_pad.add_probe (
                Gst.PadProbeType.BLOCK | Gst.PadProbeType.EVENT_DOWNSTREAM,
                (pad, info) => {
                    if (info.get_event ().type != Gst.EventType.EOS)
                        return Gst.PadProbeReturn.PASS;

                    video_sink_src_pad.remove_probe (info.id);

                    if (target_sink != convert)
                        this.add (target_sink);

                    if (current_video_sink != convert)
                        current_video_sink.unlink (convert);

                    video_sink_pad.set_target (target_video_sink_pad);
                    sub_sink_pad.set_target (target_sub_sink_pad);

                    if (current_video_sink != convert) {
                        this.remove (current_video_sink);
                        current_video_sink.set_state (Gst.State.NULL);
                    }

                    if (target_sink != convert)
                        target_sink.link (convert);

                    target_sink.set_state (this.current_state);

                    return Gst.PadProbeReturn.DROP;
                }
            );

            video_sink_sink_pad.send_event (new Gst.Event.eos ());

            return Gst.PadProbeReturn.OK;
        });
    }

    void handle_sub_caps (Gst.Caps caps) {
        Gst.Element target_sink;
        Gst.Pad target_video_sink_pad, target_sub_sink_pad;

        var media_type = caps.get_structure (0).get_name ();
        switch (media_type) {
            case "text/x-raw":
            case "subpicture/x-dvd":
            case "subpicture/x-dvb":
            case "subpicture/x-xsub":
            case "subpicture/x-pgs":
                target_sink = overlay;
                target_video_sink_pad =
                    (!) overlay.get_static_pad ("video_sink");
                target_sub_sink_pad =
                    (!) overlay.get_static_pad ("subtitle_sink");
                break;
            case "application/x-ass":
            case "application/x-ssa":
                target_sink = render;
                target_video_sink_pad =
                    (!) render.get_static_pad ("video_sink");
                target_sub_sink_pad = (!) render.get_static_pad ("text_sink");
                break;
            default:
                critical ("Unhandled subtitle caps: %s", media_type);
                return;
        }

        switch_sink (target_sink, target_video_sink_pad, target_sub_sink_pad);
    }

    void unlink_subtitle_element () {
        switch_sink (convert, (!) convert.get_static_pad ("sink"), null);
    }

    public SubOverlayConverter () {
        render = null_cast (Gst.ElementFactory.make ("assrender", null));
        overlay = null_cast (Gst.ElementFactory.make ("subtitleoverlay", null));
        convert = null_cast (Gst.ElementFactory.make ("videoconvert", null));

        this.add (convert);

        video_sink_pad = new Gst.GhostPad ("video_sink",
            convert.sinkpads.nth_data (0));
        this.add_pad (video_sink_pad);

        sub_sink_pad = new Gst.GhostPad.no_target_from_template (null,
            sub_sink_template);
        this.add_pad (sub_sink_pad);

        sub_sink_pad.unlinked.connect (unlink_subtitle_element);

        Gst.pad_set_event_function (sub_sink_pad, (pad, parent, event) => {
            switch (event.type) {
                case Gst.EventType.CAPS:
                    Gst.Caps caps;
                    event.parse_caps (out caps);
                    ((SubOverlayConverter) parent).handle_sub_caps (caps);
                    break;
            }

            return pad.event_default (parent, event);
        });

        src_pad = new Gst.GhostPad ("src", convert.srcpads.nth_data (0));
        this.add_pad (src_pad);
    }

    class construct {
        var sub_caps = Gst.Caps.from_string (
            "application/x-ass; "
            + "application/x-ssa; "
            + "text/x-raw; "
            + "subpicture/x-dvd; "
            + "subpicture/x-dvb; "
            + "subpicture/x-xsub; "
            + "subpicture/x-pgs;"
        );
        sub_sink_template = new Gst.PadTemplate ("sub_sink",
            Gst.PadDirection.SINK, Gst.PadPresence.ALWAYS, sub_caps);
    }
}

class Pipeline : Gst.Pipeline {
    public weak Media media {construct; get;}
    public ClutterGst.VideoSink video_sink {construct; get;}

    dynamic Gst.Element source;
    dynamic Gst.Element decoder;

    Gst.Element audio_sink;
    public SubOverlayConverter subtitle_overlay;

    const string extra_subtitle_caps = "application/x-ass; application/x-ssa";

    public signal void event (Event event);

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
                this.event (new PadEvent (event_copy));
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

    public Nanoseconds get_position () {
        Nanoseconds ret;
        this.query_position (Gst.Format.TIME, out ret);
        return ret;
    }

    void sync_controller_state (PlayerState new_controller_state) {
        // if we're playing from the end of a file, rewind first
        if (new_controller_state == PlayerState.PLAYING && media.duration > 0
                && get_position () == media.duration)
            seek (0);

        var new_state = (Gst.State) new_controller_state;
        if (this.set_state (new_state) == Gst.StateChangeReturn.FAILURE)
            warning ("State transition failed: %s -> %s",
                this.current_state.to_string (), new_state.to_string ());
    }

    public new void seek (Nanoseconds pos)
        requires (this.current_state >= Gst.State.PAUSED)
    {
        pos = pos.clamp (0, media.duration);
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
                error (e);
                break;

            case Gst.MessageType.EOS:
                media.playback_controller.paused = true;
                break;
        }

        event (new BusEvent (message));
    }

    bool has_video;

    void detect_video (Gst.StreamCollection streams) {
        has_video = false;

        for (var i = 0; i < streams.get_size (); i++)
            if (Gst.StreamType.VIDEO in streams.get_stream (i).stream_type) {
                has_video = true;
                return;
            }
    }

    void handle_cover (string tag) {
        if (has_video || tag != Gst.Tags.IMAGE)
            return;

        Gst.Sample? cover_sample = null;

        foreach (var sample_wrapper in media.tags.get_list (Gst.Tags.IMAGE)) {
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

    [Signal (run = "last")]
    public virtual signal void error (Error e) {
        AppController.get_default ().media_closed ();
    }

    public Pipeline (Media media) {
        Object (media: media, video_sink: new ClutterGst.VideoSink ());

        source = null_cast (Gst.ElementFactory.make ("urisourcebin", "source"));
        decoder = null_cast (Gst.ElementFactory.make ("decodebin3", "decoder"));

        unowned Gst.Caps decoder_caps = decoder.caps;
        var extra_decoder_caps = Gst.Caps.from_string (extra_subtitle_caps);
        decoder.caps = decoder_caps.merge (extra_decoder_caps);

        audio_sink =
            null_cast (Gst.ElementFactory.make ("autoaudiosink", null));
        subtitle_overlay = new SubOverlayConverter ();

        this.add_many (source, decoder);

        source.pad_added.connect ((pad) => {
            if (!source.link (decoder))
                warning ("Failed to link source to decoder");
        });

        decoder.pad_added.connect (handle_decoder_pad);

        media.playback_controller.state_changed.connect (
            sync_controller_state);

        media.got_streams.connect (detect_video);
        media.tags.tag_updated.connect (handle_cover);

        var bus = this.get_bus ();
        bus.add_signal_watch ();
        bus.message.connect (handle_bus_message);

        source.uri = media.file.get_uri ();
    }
}
