[GtkTemplate (ui = "/so/bob131/Videos/gtk/controls/control-container.ui")]
class ControlContainer : Gtk.Revealer {
    public bool mouse_over {private set; get;}

    AppController controller = AppController.get_default ();

    [GtkCallback]
    void show_controls () {
        this.reveal_child = true;
        this.grab_focus ();
    }

    [GtkCallback]
    void handle_event (Gdk.Event event) {
        if (event.type == Gdk.EventType.ENTER_NOTIFY
                || event.type == Gdk.EventType.LEAVE_NOTIFY)
            mouse_over = event.type == Gdk.EventType.ENTER_NOTIFY;
    }

    // signals for CSS key binds

    [Signal (action = true)]
    public virtual signal void pause_toggle () {
        controller.playback.paused ^= true;
        Bus.@get ().activity ();
    }

    [Signal (action = true)]
    public virtual signal void fullscreen_toggle () {
        controller.fullscreen ^= true;
    }

    [Signal (action = true)]
    public virtual signal void unfullscreen () {
        controller.fullscreen = false;
    }

    [Signal (action = true)]
    public virtual signal void seek_delta (int seconds) {
        controller.playback.position += seconds * Gst.SECOND;
        Bus.@get ().activity ();
    }

    [Signal (action = true)]
    public virtual signal void seek_frame (int frames) {
        controller.playback.paused = true;
        Bus.@get ().get_instance<Pipeline> ().frame_step (frames);
        Bus.@get ().activity ();
    }

    [Signal (action = true)]
    public virtual signal void quit () {
        Application.get_default ().quit ();
    }

    construct {
        Bus.@get ().activity.connect (show_controls);
        Bus.@get ().inactivity_timeout.connect (
            () => this.reveal_child = false);

        this.notify["mouse-over"].connect (() => {
            if (mouse_over)
                Bus.@get ().idle_hold (this);
            else
                Bus.@get ().idle_release (this);
        });

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource (
            "/so/bob131/Videos/data/key-bindings.css");
        this.get_style_context ().add_provider (css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}
