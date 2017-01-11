[GtkTemplate (ui = "/so/bob131/Videos/gtk/about.ui")]
class AboutDialog : Gtk.AboutDialog {
    public AboutDialog (Gtk.Window parent) {
        try {
            this.logo = (!) Gtk.IconTheme.get_default ().load_icon_for_scale (
                "so.bob131.Videos", -1, 128, Gtk.IconLookupFlags.FORCE_SVG);
        } catch (Error e) {
            warning ("Failed to load logo: %s", e.message);
            this.logo_icon_name = "so.bob131.Videos";
        }

        this.set_transient_for (parent);
        this.response.connect (() => this.destroy ());
    }
}
