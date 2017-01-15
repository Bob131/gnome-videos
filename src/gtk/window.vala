[GtkTemplate (ui = "/so/bob131/Videos/gtk/window.ui")]
class MainWindow : Gtk.ApplicationWindow {
    Clutter.Actor stage;
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

    uint inhibit_cookie;

    void media_closed () {
        this.title = "Videos";
        stage.set_content (null);
        stack.visible_child = greeter;
    }

    void update_title (string tag_name) {
        if (tag_name == Gst.Tags.TITLE)
            this.title =
                (string) controller.playback.now_playing.tags[tag_name];
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

    void handle_streams (Gst.StreamCollection streams) {
        Gtk.ModelButton[] audio_buttons = {};
        Gtk.ModelButton[] subtitle_buttons = {};

        for (var i = 0; i < streams.get_size (); i++) {
            var stream = streams.get_stream (i);

            var model_button = new Gtk.ModelButton ();
            model_button.visible = true;
            model_button.role = Gtk.ButtonRole.RADIO;
            model_button.name = null_cast (stream.get_stream_id ());

            var language = "Unknown";
            string[] stream_desc = {};

            if (stream.get_caps () != null) {
                var caps = (!) stream.get_caps ();
                unowned Gst.Structure structure = (!) caps.get_structure (0);

                int channels;
                if (structure.get_int ("channels", out channels))
                    stream_desc += @"$(channels)ch.";
            }

            if (stream.get_tags () != null) {
                var tags = (!) stream.get_tags ();

                string language_code;
                if (tags.get_string (Gst.Tags.LANGUAGE_CODE, out language_code))
                {
                    string? language_name =
                        Gst.Tag.get_language_name (language_code);
                    language = language_name != null ? (!) language_name
                        : language_code;
                }

                string codec;
                if (tags.get_string (Gst.Tags.CODEC, out codec)
                        || tags.get_string (Gst.Tags.AUDIO_CODEC, out codec)
                        || tags.get_string (Gst.Tags.SUBTITLE_CODEC, out codec))
                    stream_desc += codec;
            }

            model_button.text = stream_desc.length == 0 ? language :
                @"$language ($(string.joinv (" ", (string?[]?) stream_desc)))";

            if (Gst.StreamType.AUDIO in stream.get_stream_type ())
                audio_buttons += model_button;
            else if (Gst.StreamType.TEXT in stream.get_stream_type ())
                subtitle_buttons += model_button;
        }

        audio_track_selection_menu.update (audio_buttons);
        subtitle_selection_menu.update (subtitle_buttons);
    }

    Gst.StreamCollection selected_cache;

    void handle_selected_streams (Gst.StreamCollection streams) {
        selected_cache = streams;

        for (var i = 0; i < streams.get_size (); i++) {
            var stream = streams.get_stream (i);
            string stream_name = null_cast (stream.get_stream_id ());

            if (Gst.StreamType.AUDIO in stream.get_stream_type ())
                audio_track_selection_menu.select_child_by_name (stream_name);
            else if (Gst.StreamType.TEXT in stream.get_stream_type ())
                subtitle_selection_menu.select_child_by_name (stream_name);
        }
    }

    [GtkCallback]
    void stream_selected (RadioSubmenu menu, string selected_name) {
        var stream_list = new List<string> ();

        for (var i = 0; i < selected_cache.get_size (); i++) {
            var stream = selected_cache.get_stream (i);
            string stream_name = null_cast (stream.get_stream_id ());

            if (stream_name == menu.selected_child.name) {
                if (menu == subtitle_selection_menu && selected_name == "none")
                    controller.playback.now_playing.pipeline.subtitle_overlay
                        .enable_subtitles = false;
                else {
                    controller.playback.now_playing.pipeline.subtitle_overlay
                        .enable_subtitles = true;
                    stream_list.append (selected_name);
                    continue;
                }
            }

            stream_list.append (stream_name);
        }

        controller.playback.now_playing.pipeline.select_streams (stream_list);
    }

    void handle_media (Media media) {
        media.pipeline.error.connect (display_error);

        var content = new ClutterGst.Aspectratio ();
        stage.content = content;
        content.sink = media.pipeline.video_sink;

        media.tags.tag_updated.connect (update_title);

        stack.visible_child = stage_embed;
        stage_embed.controls.activity ();

        media.got_streams.connect (handle_streams);
        media.selected_streams_updated.connect (handle_selected_streams);

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

        // bind preferences

        var gtk_settings = this.get_settings ();
        var prefs = new Preferences ();
        prefs.settings.bind ("use-dark-theme", gtk_settings,
            "gtk-application-prefer-dark-theme", SettingsBindFlags.GET);

        // init actions

        var action = new SimpleAction ("preferences", null);
        action.activate.connect (() => build_prefs_dialog (this).run ());
        this.add_action (action);

        action = new SimpleAction ("open", null);
        action.activate.connect (open_file_selection_dialog);
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

        // setup stage

        stage = stage_embed.get_stage ();
        stage.background_color = {0, 0, 0, 0};

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

        this.show_all ();
    }
}
