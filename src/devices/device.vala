errordomain DeviceError {
    READ_FAILURE,
    UNKNOWN_DEVICE
}

abstract class Device : Object {
    public abstract Gst.Element make_source ();

    public static Device new_from_directory (File file) throws Error
        requires (file.query_file_type (FileQueryInfoFlags.NONE)
            == FileType.DIRECTORY)
    {
        var enumerator = file.enumerate_children (
            FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NONE);

        FileInfo? file_info;
        while ((file_info = enumerator.next_file ()) != null)
            switch (((!) file_info).get_name ().up ()) {
                case "BDMV":
                    message ("Bluray disc detected!");
                    return new BlurayDevice (file);
            }

        throw new DeviceError.UNKNOWN_DEVICE ("Unknown/unsupported %s %s",
            "device for URI", file.get_uri ());
    }
}
