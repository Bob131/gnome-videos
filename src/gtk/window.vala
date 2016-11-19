enum AppState {
    STOPPED,
    PAUSED,
    PLAYING
}

[GtkTemplate (ui = "/so/bob131/Videos/gtk/window.ui")]
class MainWindow : Gtk.ApplicationWindow {
    public AppState state {set; get;}

    PlayerStage stage;

    [GtkChild]
    Gtk.Stack stack;
    [GtkChild]
    Gtk.Widget greeter;
    [GtkChild]
    GtkClutter.Embed stage_embed;

    public void play_file (File file) {
        stage.play_file (file);
        state = AppState.PLAYING;
    }

    void update_state () {
        stack.visible_child = state == AppState.STOPPED ? greeter : stage_embed;
    }

    public MainWindow () {
        Object (application: (Gtk.Application) Application.get_default (),
            title: "Videos");

        stage = new PlayerStage (stage_embed.get_stage ());

        this.notify["state"].connect (() => update_state ());

        this.show_all ();
    }
}
