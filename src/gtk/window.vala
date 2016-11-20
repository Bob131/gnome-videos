[GtkTemplate (ui = "/so/bob131/Videos/gtk/window.ui")]
class MainWindow : Gtk.ApplicationWindow {
    Pipeline pipeline;

    [GtkChild]
    Gtk.Stack stack;
    [GtkChild]
    Gtk.Widget greeter;
    [GtkChild]
    GtkClutter.Embed stage_embed;

    void update_state (PlayerState state) {
        stack.visible_child =
            state == PlayerState.STOPPED ? greeter : stage_embed;
    }

    public MainWindow () {
        Object (application: (Gtk.Application) Application.get_default (),
            title: "Videos");

        var stage = stage_embed.get_stage ();
        stage.background_color = {0, 0, 0, 0};

        var video_sink = new ClutterGst.VideoSink ();
        pipeline = new Pipeline (video_sink);

        var content = new ClutterGst.Aspectratio ();
        content.sink = video_sink;
        stage.content = content;

        Controller.get_default ().state_changed.connect (update_state);

        this.show_all ();
    }
}
