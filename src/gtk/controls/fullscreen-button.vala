[GtkTemplate (ui = "/so/bob131/Videos/gtk/controls/fullscreen-button.ui")]
class FullscreenButton : Gtk.Button {
    bool fullscreen;
    Gtk.Window window;

    [GtkChild]
    new Gtk.Image image;

    [GtkCallback]
    void toggle_fullscreen ()
        requires ((void*) window != null)
    {
        if (fullscreen)
            window.unfullscreen ();
        else
            window.fullscreen ();
    }

    void handle_realize ()
        requires ((void*) window == null)
    {
        window = (Gtk.Window) this.get_toplevel ();

        window.window_state_event.connect ((ev) => {
            if (Gdk.WindowState.FULLSCREEN in ev.changed_mask)
                fullscreen = !fullscreen;

            image.icon_name = fullscreen ? "view-restore-symbolic"
                : "view-fullscreen-symbolic";

            return false;
        });
    }

    construct {
        this.realize.connect_after (handle_realize);
    }
}
