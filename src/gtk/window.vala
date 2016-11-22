[GtkTemplate (ui = "/so/bob131/Videos/gtk/window.ui")]
class MainWindow : Gtk.ApplicationWindow {
    Pipeline pipeline;
    Clutter.Actor stage;
    Controller controller = Controller.get_default ();

    [GtkChild]
    Gtk.Stack stack;
    [GtkChild]
    Gtk.Widget greeter;
    [GtkChild]
    Gtk.Overlay overlay;

    [GtkChild]
    GtkClutter.Embed stage_embed;

    [GtkChild]
    ControlContainer controls;

    void update_state (PlayerState state) {
        if (state == PlayerState.STOPPED)
            this.unfullscreen ();
        stack.visible_child = state == PlayerState.STOPPED ? greeter : overlay;
    }

    void update_title () {
        this.title = controller.now_playing == null ? "Videos"
            : (!) ((!) controller.now_playing).file.get_basename ();
    }

    void display_error (Error e) {
        var dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL,
            Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "%s: %s",
            e.domain.to_string (), e.message);
        dialog.run ();
        dialog.destroy ();
    }

    void clean_up_pipeline () {
        if ((void*) pipeline != null)
            pipeline.set_state (Gst.State.NULL);
    }

    void open_file (File file) {
        clean_up_pipeline ();

        pipeline = new Pipeline ();
        pipeline.error.connect (display_error);

        var content = new ClutterGst.Aspectratio ();
        stage.content = content;
        content.sink = pipeline.video_sink;

        var media = new Media (file, pipeline);
        media.got_title.connect (update_title);

        controller.media_opened (media);

        controls.activity ();
    }

    internal override void drag_data_received (
        Gdk.DragContext context,
        int _,
        int __,
        Gtk.SelectionData data,
        uint ___,
        uint time)
    {
        Gtk.drag_finish (context, true, false, time);

        var uris = data.get_uris ();

        if (uris.length > 1)
            warning ("Playlists not (yet) supported. Playing first file");

        Controller.get_default ().open_file (File.new_for_uri (uris[0]));
    }

    [GtkCallback]
    bool greeter_click (Gdk.EventButton event) {
        // only handle single left-clicks
        if (event.type != Gdk.EventType.BUTTON_RELEASE || event.button != 1)
            return false; // propagate event

        var chooser = new Gtk.FileChooserDialog ("Open media", this,
            Gtk.FileChooserAction.OPEN,
            "_Cancel", Gtk.ResponseType.CANCEL,
            "_Open", Gtk.ResponseType.ACCEPT);

        // TODO: enumerate supported file types from Gst.Registry

        var filter = new Gtk.FileFilter ();
        filter.add_mime_type ("video/*");
        filter.set_filter_name ("Videos");
        chooser.add_filter (filter);

        filter = new Gtk.FileFilter ();
        filter.add_mime_type ("audio/*");
        filter.set_filter_name ("Audio files");
        chooser.add_filter (filter);

        // TODO: thumbnail preview

        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            var file = chooser.get_file ();
            Idle.add (() => {
                open_file (file);
                return Source.REMOVE;
            });
        }

        chooser.destroy ();

        return true;
    }

    public MainWindow () {
        Object (application: (Gtk.Application) Application.get_default (),
            title: "Videos");

        stage = stage_embed.get_stage ();
        stage.background_color = {0, 0, 0, 0};

        controller.state_changed.connect (update_state);

        controller.open_file.connect (open_file);

        stage_embed.event_after.connect ((ev) => {
            if (ev.type == Gdk.EventType.MOTION_NOTIFY)
                controls.activity ();
        });

        var drop_targets = new Gtk.TargetList (null);
        drop_targets.add_uri_targets (0);
        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, {}, Gdk.DragAction.COPY);
        Gtk.drag_dest_set_target_list (this, drop_targets);

        this.destroy.connect (clean_up_pipeline);

        this.show_all ();
    }
}
