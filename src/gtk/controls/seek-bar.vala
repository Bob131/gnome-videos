// TODO: add textual time label

[GtkTemplate (ui = "/so/bob131/Videos/gtk/controls/seek-bar.ui")]
class SeekBar : Gtk.Scale {
    AppController controller = AppController.get_default ();
    ulong got_duration_handler;

    void update_bar () {
        if (!controller.media_loaded) {
            this.set_value (0);
            this.set_range (0, 0);
            return;
        } else
            this.set_value (controller.playback.position);
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
            controller.playback.position = (Nanoseconds) this.get_value ();
        });

        Timeout.add (200, () => {
            update_bar ();
            return Source.CONTINUE;
        });
    }
}
