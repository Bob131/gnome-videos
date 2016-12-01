[GtkTemplate (ui = "/so/bob131/Videos/gtk/controls/play-button.ui")]
class PlayButton : Gtk.Button {
    AppController controller = AppController.get_default ();

    [GtkChild]
    new Gtk.Image image;

    [GtkCallback]
    void state_toggle () {
        if (controller.playback.state == PlayerState.PLAYING)
            controller.playback.pause ();
        else
            controller.playback.play ();
    }

    construct {
        controller.media_opened.connect (() =>
            controller.playback.state_changed.connect ((state) => {
                image.icon_name = state == PlayerState.PLAYING
                    ? "media-playback-pause-symbolic"
                    : "media-playback-start-symbolic";
            }));
    }
}
