class PlayerStage : Object {
    public Clutter.Stage stage {construct; get;}

    Gst.Pipeline pipeline;

    Gst.Element source;
    Gst.Bin decoder;

    ClutterGst.VideoSink video_sink;
    Gst.Element audio_sink;

    public void play_file (File file) {
        source["uri"] = file.get_uri ();
        pipeline.set_state (Gst.State.PLAYING);
    }

    public PlayerStage (Clutter.Actor stage)
        requires (stage is Clutter.Stage)
    {
        Object (stage: (Clutter.Stage) stage);

        stage.background_color = {0, 0, 0, 0};

        pipeline = new Gst.Pipeline (null);

        source = (!) Gst.ElementFactory.make ("urisourcebin", "source");
        decoder = (Gst.Bin) Gst.ElementFactory.make ("decodebin3", "decoder");

        video_sink = new ClutterGst.VideoSink ();
        audio_sink = (!) Gst.ElementFactory.make ("autoaudiosink", null);

        var content = new ClutterGst.Aspectratio ();
        content.sink = video_sink;
        stage.content = content;

        pipeline.add_many (source, decoder, video_sink, audio_sink);

        source.pad_added.connect (() => assert (source.link (decoder)));

        decoder.pad_added.connect ((pad) => {
            switch (pad.template.name_template) {
                case "audio_%u":
                    assert (decoder.link (audio_sink));
                    break;
                case "video_%u":
                    assert (decoder.link (video_sink));
                    break;
            }
        });
    }
}
