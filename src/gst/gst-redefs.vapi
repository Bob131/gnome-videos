[CCode (cheader_filename = "gst/gst.h")]
namespace Gst {
    public void pad_set_event_function (
        Pad self,
        owned PadEventFunction function
    );

    public MiniObject mini_object_make_writable (owned MiniObject object);
}
