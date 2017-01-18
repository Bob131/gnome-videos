class UriDevice : Device {
    public File file {construct; get;}

    public override Gst.Element make_source () {
        dynamic Gst.Element ret =
            null_cast (Gst.ElementFactory.make ("urisourcebin", null));
        ret.uri = file.get_uri ();
        return ret;
    }

    public UriDevice (File file) {
        Object (file: file);
    }
}
