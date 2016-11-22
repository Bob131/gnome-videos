// TODO: add textual time label

[GtkTemplate (ui = "/so/bob131/Videos/gtk/controls/seek-bar.ui")]
class SeekBar : Gtk.Scale {
    Controller controller = Controller.get_default ();
    ulong got_duration_handler;

    void update_bar () {
        if (controller.state == PlayerState.STOPPED) {
            this.set_value (0);
            this.set_range (0, 0);
            return;
        }

        this.set_value (controller.position);
    }

    construct {
        controller.media_opened.connect ((media) => {
            got_duration_handler = media.got_duration.connect ((duration) => {
                this.set_range (0, duration);
                SignalHandler.disconnect (media, got_duration_handler);
                got_duration_handler = 0;
            });
        });

        this.change_value.connect_after (() => {
            controller.position = (Nanoseconds) this.get_value ();
        });

        Timeout.add (200, () => {
            update_bar ();
            return Source.CONTINUE;
        });
    }
}
