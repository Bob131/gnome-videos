class Pipeline : Gst.Pipeline {
    Gst.Element source;
    Gst.Element decoder;

    ClutterGst.VideoSink video_sink;
    Gst.Element audio_sink;

    void handle_decoder_pad (Gst.Pad pad) {
        message (pad.template.name_template);
        switch (pad.template.name_template) {
            case "audio_%u":
                assert (decoder.link (audio_sink));
                break;
            case "video_%u":
                assert (decoder.link (video_sink));
                break;
        }
    }

    void play_file (File file) {
        source["uri"] = file.get_uri ();
        Controller.get_default ().state = PlayerState.PLAYING;
    }

    public Pipeline (ClutterGst.VideoSink video_sink) {
        this.video_sink = video_sink;

        source = (!) Gst.ElementFactory.make ("urisourcebin", "source");
        decoder = (!) Gst.ElementFactory.make ("decodebin3", "decoder");

        audio_sink = (!) Gst.ElementFactory.make ("autoaudiosink", null);

        this.add_many (source, decoder, video_sink, audio_sink);

        source.pad_added.connect (() => assert (source.link (decoder)));

        decoder.pad_added.connect (handle_decoder_pad);

        var controller = Controller.get_default ();

        controller.notify["state"].connect (
            () => this.set_state ((Gst.State) controller.state));

        controller.play_file.connect (play_file);
    }
}
