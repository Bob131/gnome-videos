[CCode (has_target = false)]
delegate VA.Display? Initializer ();

VA.Display? open_display_wayland () {
    var wayland_display = Wayland.Display.connect (null);
    if (wayland_display == null)
        return null;
    return VA.get_display_wayland ((!)(owned) wayland_display);
}

VA.Display? open_display_x11 () {
    var x_display = new X.Display ();
    if ((void*) x_display == null)
        return null;
    return VA.get_display ((owned) x_display);
}

void vaapi_workaround () {
    // only relevant for consumer Sandy Bridge hardware
    uint cpuid, _, __, ___;
    assert (get_cpuid (1, out cpuid, out _, out __, out ___));
    if (cpuid != 0x206a7)
        return;

    Initializer[] initializers = {
        open_display_wayland,
        open_display_x11
    };

    VA.Display? display = null;

    for (var i = 0; i < initializers.length && display == null; i++)
        display = initializers[i] ();

    if (display == null) {
        warning ("VAAPI workaround failed: Could not open display");
        return;
    }

    int major, minor;
    VA.initialize ((!) display, out major, out minor);

    unowned VA.DisplayContext context = (VA.DisplayContext) display;
    string driver_name;
    context.get_driver_name (out driver_name);

    if (driver_name != "i965")
        return;

    message ("Hardware video acceleration is currently broken on %s",
        "Sandy Bridge hardware. Using dummy libva driver instead");
    message ("See https://bugs.freedesktop.org/show_bug.cgi?id=97086");
    Environment.set_variable ("LIBVA_DRIVER_NAME", "dummy", true);
}
