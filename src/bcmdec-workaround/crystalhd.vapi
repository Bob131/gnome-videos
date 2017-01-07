// not the real cheader_filename, but it isn't included in the real header
[CCode (cheader_filename = "stdint.h")]
namespace CrystalHD {
    [CCode (cheader_filename = "libcrystalhd/libcrystalhd_if.h", cname = "BC_STATUS", cprefix = "BC_STS_")]
    public enum Status {
        SUCCESS,
        ERROR
    }

    [CCode (cname = "HANDLE", free_function = "DtsDeviceClose")]
    [Compact]
    public class Handle {}

    [CCode (cname = "DtsDeviceOpen")]
    public Status device_open (out Handle device, uint32 mode = 0);
}
