errordomain DeviceError {
    READ_FAILURE,
    UNKNOWN_DEVICE
}

abstract class Device : Object {
    public abstract Gst.Element make_source ();
}
