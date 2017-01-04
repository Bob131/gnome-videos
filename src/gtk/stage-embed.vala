class StageEmbed : GtkClutter.Embed {
    Timer timer;
    AppController controller = AppController.get_default ();

    public signal void motion ();

    void show_cursor () {
        Gdk.Window window = null_cast (this.get_window ());
        window.set_cursor (null);
    }

    void hide_cursor () {
        Gdk.Window window = null_cast (this.get_window ());
        window.cursor = new Gdk.Cursor.for_display (window.get_display (),
            Gdk.CursorType.BLANK_CURSOR);
    }

    void handle_event (Gdk.Event event) {
        switch (event.type) {
            case Gdk.EventType.MOTION_NOTIFY:
            case Gdk.EventType.ENTER_NOTIFY:
                show_cursor ();
                motion ();
                timer.start ();
                break;

            case Gdk.EventType.LEAVE_NOTIFY:
                timer.stop ();
                timer.reset ();
                break;

            case Gdk.EventType.DOUBLE_BUTTON_PRESS:
                uint button;
                event.get_button (out button);

                if (button == 1)
                    controller.fullscreen = !controller.fullscreen;

                break;
        }
    }

    construct {
        timer = new Timer ();
        timer.stop ();
        timer.reset ();

        this.event_after.connect (handle_event);

        Timeout.add (500, () => {
            if (this.visible && timer.elapsed () > 2)
                hide_cursor ();

            return Source.CONTINUE;
        });
    }
}
