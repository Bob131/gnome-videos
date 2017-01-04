[GtkTemplate (ui = "/so/bob131/Videos/gtk/controls/fullscreen-button.ui")]
class FullscreenButton : Gtk.Button {
    AppController controller = AppController.get_default ();

    [GtkChild]
    new Gtk.Image image;

    [GtkCallback]
    void toggle_fullscreen () {
        controller.fullscreen = !controller.fullscreen;
    }

    construct {
        controller.notify["fullscreen"].connect (() => {
            image.icon_name = controller.fullscreen ? "view-restore-symbolic"
                : "view-fullscreen-symbolic";
        });
    }
}
