[GtkTemplate (ui = "/so/bob131/Videos/gtk/controls/seek-bar.ui")]
class SeekBar : Gtk.Overlay {
    AppController controller = AppController.get_default ();
    Nanoseconds duration;

    [GtkChild]
    Gtk.Scale scale;
    [GtkChild]
    Gtk.Label label;

    string format_time (Nanoseconds time) {
        var ret = time < 0 ? "-" : "";
        time = time.abs ();

        var seconds = (time / Gst.SECOND) % 60,
            minutes = (time / (Gst.SECOND * 60)) % 60,
            hours = time / (Gst.SECOND * 3600);

        if (hours > 0)
            ret += @"%02$(int64.FORMAT):".printf (hours);

        ret += @"%02$(int64.FORMAT):%02$(int64.FORMAT)".printf (minutes,
            seconds);

        return ret;
    }

    void update_label () {
        if (!controller.media_loaded) {
            duration = 0;
            label.label = "";
            return;
        }

        var now = format_time (controller.playback.position),
            till_end = format_time (controller.playback.position - duration);
        label.label = @"<small>$now / $till_end</small>";
    }

    void update_bar () {
        if (!controller.media_loaded) {
            duration = 0;
            scale.set_value (0);
            scale.set_range (0, 0);
            return;
        }

        scale.set_value (controller.playback.position);
    }

    void got_duration_handler (Media media, Nanoseconds duration) {
        this.duration = duration;
        scale.set_range (0, duration);
        media.got_duration.disconnect (got_duration_handler);
    }

    construct {
        controller.media_opened.connect ((media) =>
            media.got_duration.connect (got_duration_handler));

        scale.change_value.connect_after (() => {
            controller.playback.position = (Nanoseconds) scale.get_value ();
            update_label ();
        });

        Timeout.add (200, () => {
            update_bar ();
            return Source.CONTINUE;
        });

        Timeout.add (1000, () => {
            update_label ();
            return Source.CONTINUE;
        });
    }
}
