class PlayerStage : Object {
    public Clutter.Stage stage {construct; get;}

    ClutterGst.Playback player;
    ClutterGst.VideoSink video_sink;
    ClutterGst.Content content;

    public void play_file (File file) {
        player.uri = file.get_uri ();
        player.playing = true;
    }

    public PlayerStage (Clutter.Actor stage)
        requires (stage is Clutter.Stage)
    {
        Object (stage: (Clutter.Stage) stage);

        stage.background_color = {0, 0, 0, 0};

        player = new ClutterGst.Playback ();
        video_sink = new ClutterGst.VideoSink ();
        content = new ClutterGst.Aspectratio ();

        content.sink = video_sink;
        content.player = player;

        stage.content = content;

        player.error.connect ((e) => message (e.message));
    }
}
