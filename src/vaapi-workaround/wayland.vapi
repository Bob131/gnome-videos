[CCode (cheader_filename = "wayland-client.h", lower_case_cprefix = "wl_")]
namespace Wayland {
    [CCode (cname = "struct wl_display", free_function = "wl_display_disconnect")]
    [Compact]
    public class Display {
        public static Display? connect (string? name);
    }
}
