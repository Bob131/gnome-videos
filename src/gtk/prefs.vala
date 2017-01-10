[GtkTemplate (ui = "/so/bob131/Videos/gtk/prefs-content.ui")]
class PrefsContent : Gtk.Grid {
    construct {
        var prefs = new Preferences ();
        var key_names = prefs.schema.list_keys ();

        for (var i = 0; i < key_names.length; i++) {
            var key = prefs.schema.get_key (key_names[i]);

            var label = new Gtk.Label (key.get_summary ());
            this.attach (label, 0, i);

            Gtk.Widget control;
            string bind_property;

            switch (key.get_value_type ().dup_string ()) {
                case "b":
                    control = new Gtk.Switch ();
                    bind_property = "active";
                    break;
                default:
                    warning ("Unhandled property type: %s",
                        key.get_value_type ().dup_string ());
                    continue;
            }

            prefs.settings.bind (key_names[i], control, bind_property,
                SettingsBindFlags.DEFAULT);

            this.attach (control, 1, i);
        }

        this.show_all ();
    }
}

public Gtk.Dialog build_prefs_dialog (Gtk.Window parent_window) {
    var ret = new Gtk.Dialog.with_buttons ("Preferences", parent_window,
        Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT
        | Gtk.DialogFlags.USE_HEADER_BAR);

    ret.get_content_area ().add (new PrefsContent ());

    ret.response.connect (() => ret.destroy ());

    return ret;
}
