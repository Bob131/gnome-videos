[GtkTemplate (ui = "/so/bob131/Videos/gtk/controls/play-button.ui")]
class PlayButton : Gtk.Button {
    Controller controller = Controller.get_default ();

    [GtkChild]
    new Gtk.Image image;

    [GtkCallback]
    void state_toggle () {
        if (controller.state == PlayerState.PLAYING)
            controller.pause ();
        else
            controller.play ();
    }

    construct {
        controller.state_changed.connect ((state) => {
            image.icon_name = state == PlayerState.PLAYING
                ? "media-playback-pause-symbolic"
                : "media-playback-start-symbolic";
        });
    }
}
