[CCode (cheader_filename = "gst/gst.h")]
namespace Gst {
    public void pad_set_event_function (
        Pad self,
        owned PadEventFunction function
    );
}
