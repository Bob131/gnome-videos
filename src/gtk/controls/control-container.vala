[GtkTemplate (ui = "/so/bob131/Videos/gtk/controls/control-container.ui")]
class ControlContainer : Gtk.Revealer {
    public bool mouse_over {private set; get;}

    bool should_reveal = true;

    AppController controller = AppController.get_default ();

    [GtkCallback]
    void show_controls () {
        should_reveal = true;
        this.reveal_child = true;
        this.grab_focus ();
    }

    public virtual signal void activity () {
        show_controls ();
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
        activity ();
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
        activity ();
    }

    [Signal (action = true)]
    public virtual signal void seek_frame (int frames) {
        controller.playback.paused = true;
        controller.playback.now_playing.pipeline.frame_step (frames);
        activity ();
    }

    [Signal (action = true)]
    public virtual signal void quit () {
        Application.get_default ().quit ();
    }

    construct {
        Timeout.add (500, () => {
            this.reveal_child = should_reveal;

            if (should_reveal && controller.media_loaded
                    && controller.playback.state == PlayerState.PLAYING
                    && !mouse_over)
                should_reveal = false;

            return Source.CONTINUE;
        });

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource (
            "/so/bob131/Videos/data/key-bindings.css");
        this.get_style_context ().add_provider (css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        Bus.@get ().pipeline_event["eos"].connect (() => show_controls ());
    }
}
