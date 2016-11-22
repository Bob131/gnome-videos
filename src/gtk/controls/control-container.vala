[GtkTemplate (ui = "/so/bob131/Videos/gtk/controls/control-container.ui")]
class ControlContainer : Gtk.Revealer {
    bool should_reveal = true;
    bool mouse_over = false;

    Controller controller = Controller.get_default ();

    [GtkCallback]
    void show_controls () {
        should_reveal = true;
        this.reveal_child = true;
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

    construct {
        Timeout.add (500, () => {
            this.reveal_child = should_reveal;

            if (should_reveal && controller.state == PlayerState.PLAYING
                    && !mouse_over)
                should_reveal = false;

            return Source.CONTINUE;
        });
    }
}
