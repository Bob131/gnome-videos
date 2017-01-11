[GtkTemplate (ui = "/so/bob131/Videos/gtk/shortcut-window.ui")]
class ShortcutWindow : Gtk.ShortcutsWindow {
    public ShortcutWindow (Gtk.Window parent) {
        this.set_transient_for (parent);
        this.show_all ();
        this.section_name = "player";
    }
}
