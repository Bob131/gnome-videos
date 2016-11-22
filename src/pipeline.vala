class Pipeline : Gst.Pipeline {
    public ClutterGst.VideoSink video_sink {construct; get;}

    Controller controller = Controller.get_default ();

    Gst.Element source;
    Gst.Element decoder;

    Gst.Element audio_sink;

    weak Media media;

    void handle_decoder_pad (Gst.Pad pad) {
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
        var new_state = (Gst.State) controller.state;
        if (this.set_state (new_state) == Gst.StateChangeReturn.FAILURE)
            warning ("State transition failed: %s -> %s",
                this.current_state.to_string (), new_state.to_string ());
    }

    new void seek (Nanoseconds pos)
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
                controller.stop ();
                break;
        }
    }

    [Signal (run = "last")]
    public virtual signal void error (Error e) {
        controller.stop ();
    }

    public Pipeline () {
        Object (video_sink: new ClutterGst.VideoSink ());

        source = (!) Gst.ElementFactory.make ("urisourcebin", "source");
        decoder = (!) Gst.ElementFactory.make ("decodebin3", "decoder");

        audio_sink = (!) Gst.ElementFactory.make ("autoaudiosink", null);

        this.add_many (source, decoder);

        source.pad_added.connect ((pad) => {
            if (!source.link (decoder))
                warning ("Failed to link source to decoder");
        });

        decoder.pad_added.connect (handle_decoder_pad);

        controller.notify["state"].connect (sync_controller_state);

        controller.seek.connect (seek);

        var bus = this.get_bus ();

        bus.add_signal_watch ();

        bus.message.connect (handle_bus_message);

        controller.media_opened.connect ((media) => {
            this.media = media;
            source["uri"] = media.file.get_uri ();
        });
    }
}
