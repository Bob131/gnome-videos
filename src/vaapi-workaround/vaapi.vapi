[CCode (cheader_filename = "va/va.h")]
namespace VA {
    [CCode (cname = "VADisplay", free_function = "vaTerminate")]
    [Compact]
    public class Display {}

    [CCode (cname = "struct VADisplayContext")]
    [Compact]
    public class DisplayContext {
        [CCode (cheader_filename = "va-display-context.h")]
        public int get_driver_name (out string driver_name);
    }

    [CCode (cheader_filename = "va/va_x11.h", cname = "vaGetDisplay")]
    public Display get_display (owned X.Display display);
    [CCode (cheader_filename = "va/va_wayland.h", cname = "vaGetDisplayWl")]
    public Display get_display_wayland (owned Wayland.Display display);
    [CCode (cname = "vaInitialize")]
    public int initialize (
        Display display,
        out int major_version,
        out int minor_version
    );
}
