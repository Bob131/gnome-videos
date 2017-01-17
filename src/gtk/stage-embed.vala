class StageEmbed : GtkClutter.Embed {
    public ControlContainer controls {private set; get;}

    Timer timer;
    AppController controller = AppController.get_default ();

    Clutter.Actor stage;
    GtkClutter.Actor controls_actor;

    int controls_preferred_height = 0;

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
                controls.activity ();
                timer.start ();
                break;

            case Gdk.EventType.LEAVE_NOTIFY:
                timer.stop ();
                timer.reset ();
                break;

            case Gdk.EventType.DOUBLE_BUTTON_PRESS:
                uint button;
                event.get_button (out button);

                if (button == 1 && !controls.mouse_over)
                    controller.fullscreen ^= true;

                break;

            case Gdk.EventType.BUTTON_PRESS:
                uint button;
                event.get_button (out button);

                if (button == 3)
                    controller.playback.playing ^= true;

                break;
        }
    }

    void update_controls_actor () {
        Gtk.Requisition natural_size;
        controls.get_preferred_size (null, out natural_size);
        controls_preferred_height = natural_size.height;

        controls_actor.width = stage.width;
        controls_actor.height = controls_preferred_height;
        controls_actor.y = stage.height - controls_preferred_height;

        controls.size_allocate ({0, 0, (int) controls_actor.width,
            (int) controls_actor.height});
    }

    void set_sink (Object sink)
        requires (sink is ClutterGst.VideoSink)
    {
        var content = new ClutterGst.Aspectratio ();
        stage.content = content;
        content.sink = (ClutterGst.VideoSink) sink;
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

        stage = this.get_stage ();
        stage.background_color = {0, 0, 0, 0};

        controls = new ControlContainer ();
        controls_actor = new GtkClutter.Actor.with_contents (controls);

        stage.add_child (controls_actor);
        controls_actor.get_widget ().show_all ();

        stage.notify["size"].connect_after (update_controls_actor);

        Bus.@get ().object_constructed["video-sink"].connect (set_sink);
    }
}
