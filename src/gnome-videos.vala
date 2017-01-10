// at run time, T and N should be the same, but valac thinks they differ in
// that N is nullable, whereas T is not (or shouldn't be)
T null_cast<T,N> (N nullable) {
    if (nullable == null)
        critical ("null check for type %s failed", typeof (T).name ());
    return (T) nullable;
}

class Videos : Gtk.Application {
    MainWindow window;

    internal override void activate () {
        if ((void*) window == null)
            this.add_window (window = new MainWindow ());
        else
            window.present ();
    }

    internal override void open (File[] files, string hint) {
        activate ();

        if (files.length > 1)
            warning ("Playlists not (yet) supported. Playing first file");

        AppController.get_default ().open_file (files[0]);
    }

    internal override void startup () {
        base.startup ();

        var action = new SimpleAction ("quit", null);
        action.activate.connect (() => this.quit ());
        this.add_action (action);

        var builder =
            new Gtk.Builder.from_resource ("/so/bob131/Videos/gtk/app-menu.ui");
        this.set_app_menu ((MenuModel) builder.get_object ("appmenu"));
    }

    Videos () {
        Object (application_id: "so.bob131.Videos",
            flags: ApplicationFlags.HANDLES_OPEN);
    }

    static int main (string[] args) {
        // GtkClutter.init sets up Clutter to use the same backend as GDK
        GtkClutter.init (ref args);
        Gst.init (ref args);

#if CPU_x86
        vaapi_workaround ();
#endif

        bcmdec_workaround ();

        return new Videos ().run (args);
    }
}
