[GtkTemplate (ui = "/so/bob131/Videos/gtk/window.ui")]
class MainWindow : Gtk.ApplicationWindow {
    Clutter.Actor stage;
    AppController controller = AppController.get_default ();

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

    void media_closed () {
        this.unfullscreen ();
        this.title = "Videos";
        stage.set_content (null);
        stack.visible_child = greeter;
    }

    void update_title (string tag_name) {
        if (tag_name == Gst.Tags.TITLE)
            this.title = (string) controller.playback.now_playing.tags[tag_name]
                .nth_data (0).@value;
    }

    void display_error (Error e) {
        var dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL,
            Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "%s: %s",
            e.domain.to_string (), e.message);
        dialog.run ();
        dialog.destroy ();
    }

    void handle_media (Media media) {
        media.pipeline.error.connect (display_error);

        var content = new ClutterGst.Aspectratio ();
        stage.content = content;
        content.sink = media.pipeline.video_sink;

        media.tags.tag_added.connect (update_title);

        stack.visible_child = overlay;
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

        controller.open_file (File.new_for_uri (uris[0]));
    }

    [GtkCallback]
    bool greeter_click (Gdk.EventButton event) {
        // only handle single left-clicks
        if (event.type != Gdk.EventType.BUTTON_RELEASE || event.button != 1)
            return Gdk.EVENT_PROPAGATE;

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
                controller.open_file (file);
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

        controller.media_opened.connect (handle_media);
        controller.media_closed.connect_after (media_closed);

        stage_embed.event_after.connect ((ev) => {
            if (ev.type == Gdk.EventType.MOTION_NOTIFY)
                controls.activity ();
        });

        var drop_targets = new Gtk.TargetList (null);
        drop_targets.add_uri_targets (0);
        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, {}, Gdk.DragAction.COPY);
        Gtk.drag_dest_set_target_list (this, drop_targets);

        this.destroy.connect (() => controller.media_closed ());

        this.show_all ();
    }
}
