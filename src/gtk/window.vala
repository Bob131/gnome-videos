[GtkTemplate (ui = "/so/bob131/Videos/gtk/window.ui")]
class MainWindow : Gtk.ApplicationWindow {
    AppController controller = AppController.get_default ();

    [GtkChild]
    Gtk.Stack stack;
    [GtkChild]
    Gtk.Widget greeter;

    [GtkChild]
    StageEmbed stage_embed;

    [GtkChild]
    Gtk.Revealer video_menu_revealer;

    [GtkChild]
    RadioSubmenu audio_track_selection_menu;
    [GtkChild]
    RadioSubmenu subtitle_selection_menu;

    StreamManager stream_manager;

    uint inhibit_cookie;

    void media_closed () {
        this.title = "Videos";
        stack.visible_child = greeter;
    }

    void display_error (Error e) {
        var dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL,
            Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "%s: %s",
            e.domain.to_string (), e.message);
        dialog.run ();
        dialog.destroy ();
    }

    void inhibit_toggle (PlayerState state) {
        if (state == PlayerState.PLAYING) {
            return_if_fail (inhibit_cookie == 0);
            inhibit_cookie = this.application.inhibit (this,
                Gtk.ApplicationInhibitFlags.IDLE, "Media playing");
            warn_if_fail (inhibit_cookie != 0);
        } else {
            return_if_fail (inhibit_cookie != 0);
            this.application.uninhibit (inhibit_cookie);
            inhibit_cookie = 0;
        }
    }

    void handle_media (Media media) {
        stack.visible_child = stage_embed;

        controller.playback.state_changed.connect (inhibit_toggle);
        inhibit_toggle (PlayerState.PLAYING);
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

    void open_file_selection_dialog () {
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
    }

    void open_device_selection_dialog () {
        var chooser = new Gtk.FileChooserDialog ("Browse to device", this,
            Gtk.FileChooserAction.SELECT_FOLDER,
            "_Cancel", Gtk.ResponseType.CANCEL,
            "_Open", Gtk.ResponseType.ACCEPT);

        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            var file = chooser.get_file ();
            Idle.add (() => {
                controller.open_file (file);
                return Source.REMOVE;
            });
        }

        chooser.destroy ();
    }

    [GtkCallback]
    bool greeter_click (Gdk.EventButton event) {
        // only handle single left-clicks
        if (event.type != Gdk.EventType.BUTTON_RELEASE || event.button != 1)
            return Gdk.EVENT_PROPAGATE;

        open_file_selection_dialog ();

        return true;
    }

    public MainWindow () {
        Object (application: (Gtk.Application) Application.get_default (),
            title: "Videos");

        Bus.@get ().tag_updated[Gst.Tags.TITLE].connect ((values) => {
            return_if_fail (values.length () > 0);
            this.title = values.data.@value.get_string ();
        });

        Bus.@get ().error.connect (display_error);

        // bind preferences

        var gtk_settings = this.get_settings ();
        var prefs = new Preferences ();
        prefs.settings.bind ("use-dark-theme", gtk_settings,
            "gtk-application-prefer-dark-theme", SettingsBindFlags.GET);

        // init actions

        var action = new SimpleAction ("preferences", null);
        action.activate.connect (() => build_prefs_dialog (this).run ());
        this.add_action (action);

        action = new SimpleAction ("open-file", null);
        action.activate.connect (open_file_selection_dialog);
        this.add_action (action);

        action = new SimpleAction ("open-device", null);
        action.activate.connect (open_device_selection_dialog);
        this.add_action (action);

        action = new SimpleAction ("about", null);
        action.activate.connect (() => new AboutDialog (this).run ());
        this.add_action (action);

        action = new SimpleAction ("shortcuts", null);
        action.activate.connect (() => new ShortcutWindow (this));
        this.add_action (action);

        action = new SimpleAction ("close-media", null);
        action.activate.connect (() => controller.media_closed ());
        this.add_action (action);

        // handle controller events

        controller.media_opened.connect (handle_media);
        controller.media_closed.connect_after (media_closed);

        controller.notify["fullscreen"].connect (() => {
            if (controller.fullscreen)
                this.fullscreen ();
            else
                this.unfullscreen ();
        });

        // drag'n'drop

        var drop_targets = new Gtk.TargetList (null);
        drop_targets.add_uri_targets (0);
        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, {}, Gdk.DragAction.COPY);
        Gtk.drag_dest_set_target_list (this, drop_targets);

        // window setup

        this.destroy.connect (() => controller.media_closed ());

        Gtk.Window.set_default_icon_name ("so.bob131.Videos");

        stack.notify["visible-child"].connect (
            () => video_menu_revealer.reveal_child
                = stack.visible_child == stage_embed);

        stream_manager = new StreamManager (audio_track_selection_menu,
            subtitle_selection_menu);

        this.show_all ();
    }
}
