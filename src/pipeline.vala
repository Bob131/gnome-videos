class Pipeline : Gst.Pipeline {
    public weak Media media {construct; get;}
    public ClutterGst.VideoSink video_sink {construct; get;}

    Gst.Element source;
    Gst.Element decoder;

    Gst.Element audio_sink;

    public signal void event (Event event);

    void handle_decoder_pad (Gst.Pad pad) {
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

        Gst.Element? sink = null;
        Gst.Element? convert = null;

        switch (pad.template.name_template) {
            case "video_%u":
                sink = video_sink;
                convert = (!) Gst.ElementFactory.make ("videoconvert", null);
                break;
            case "audio_%u":
                sink = audio_sink;
                convert = (!) Gst.ElementFactory.make ("audioconvert", null);
                break;
        }

        if (sink != null) {
            var sink_ = (!) sink,
                convert_ = (!) convert;
            this.add_many (sink_, convert_);
            sink_.set_state (this.current_state);
            convert_.set_state (this.current_state);
            if (decoder.link (convert_) && convert_.link (sink_))
                return;
        }

        warning ("Failed to link sink for type '%s'",
            pad.template.name_template.replace ("_%u", ""));
    }

    void sync_controller_state () {
        var new_state = (Gst.State) media.playback_controller.state;
        if (this.set_state (new_state) == Gst.StateChangeReturn.FAILURE)
            warning ("State transition failed: %s -> %s",
                this.current_state.to_string (), new_state.to_string ());
    }

    public new void seek (Nanoseconds pos)
        requires (this.current_state >= Gst.State.PAUSED)
        requires (pos <= media.duration)
    {
        if (!this.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH, pos))
            warning ("Seek failed!");
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
                media.playback_controller.pause ();
                break;
        }

        event (new BusEvent (message));
    }

    [Signal (run = "last")]
    public virtual signal void error (Error e) {
        AppController.get_default ().media_closed ();
    }

    public Pipeline (Media media) {
        Object (media: media, video_sink: new ClutterGst.VideoSink ());

        source = (!) Gst.ElementFactory.make ("urisourcebin", "source");
        decoder = (!) Gst.ElementFactory.make ("decodebin3", "decoder");

        audio_sink = (!) Gst.ElementFactory.make ("autoaudiosink", null);

        this.add_many (source, decoder);

        source.pad_added.connect ((pad) => {
            if (!source.link (decoder))
                warning ("Failed to link source to decoder");
        });

        decoder.pad_added.connect (handle_decoder_pad);

        media.playback_controller.notify["state"].connect (
            sync_controller_state);

        var bus = this.get_bus ();
        bus.add_signal_watch ();
        bus.message.connect (handle_bus_message);

        source["uri"] = media.file.get_uri ();
    }
}
