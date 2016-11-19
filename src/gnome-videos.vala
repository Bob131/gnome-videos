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

        window.play_file (files[0]);
    }

    Videos () {
        Object (application_id: "so.bob131.Videos",
            flags: ApplicationFlags.HANDLES_OPEN);
    }

    static int main (string[] args) {
        ClutterGst.init (ref args);
        return new Videos ().run (args);
    }
}
