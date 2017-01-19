class BluraySource : Gst.Base.PushSrc {
    Bluray.Disc disc;

    const double TIMEBASE = 90000;

    Bluray.TitleInfo get_title_info () {
        var ret = disc.get_title_info (disc.get_current_title (),
            disc.get_current_angle ());
        return_if_fail (ret != null);
        return (!)(owned) ret;
    }

    int64 bd_time_to_gst (uint64 bd_time) {
        return (int64) (bd_time / TIMEBASE * Gst.SECOND);
    }

    void handle_bd_event (Bluray.Event event) {
        switch (event.type) {
            case Bluray.EventType.ERROR:
            case Bluray.EventType.READ_ERROR:
            case Bluray.EventType.ENCRYPTED:
                var error_type_string = event.type.to_string ();
                var error_message = new Gst.Message.error (this,
                    new Gst.StreamError.FAILED (error_type_string),
                    error_type_string);
                this.post_message (error_message);
                break;

            default:
                message (@"Unhandled Bluray event: $(event.type)");
                break;
        }
    }

    public override Gst.FlowReturn fill (Gst.Buffer buffer) {
        Bluray.Event event;
        while (disc.get_event (out event))
            handle_bd_event (event);

        var data = new uint8[buffer.get_size ()];
        var ret = disc.read (data);

        buffer.fill (0, data);

        switch (ret) {
            case -1: return Gst.FlowReturn.ERROR;
            case  0: return Gst.FlowReturn.EOS;
            default: return Gst.FlowReturn.OK;
        }
    }

    public override bool is_seekable () { return true; }

    public override bool do_seek (Gst.Segment segment) {
        message (segment.format.to_string ());
        disc.seek (segment.position);
        return true;
    }

    public override bool query (Gst.Query query) {
        switch (query.type) {
            case Gst.QueryType.DURATION:
                Gst.Format format;
                query.parse_duration (out format, null);

                switch (format) {
                    case Gst.Format.TIME:
                        var title_info = get_title_info ();
                        var duration = bd_time_to_gst (title_info.duration);
                        query.set_duration (format, duration);
                        break;

                    case Gst.Format.BYTES:
                        query.set_duration (format,
                            (int64) disc.get_title_size ());
                        break;

                    default:
                        warning ("Unsupported duration query format: %s",
                            format.to_string ());
                        return false;
                }

                return true;
        }

        return base.query (query);
    }

    public override bool start () {
        // init event queue
        disc.get_event (null);

        disc.get_titles (Bluray.TitleFlags.RELEVANT);
        disc.select_title (disc.get_main_title ());

        return true;
    }

    public BluraySource (owned Bluray.Disc disc) {
        this.disc = (owned) disc;
    }

    class construct {
        Gst.StaticPadTemplate src_factory = {
            "src",
            Gst.PadDirection.SRC,
            Gst.PadPresence.ALWAYS,
            Gst.StaticCaps () { @string = "ANY" }
        };

        add_pad_template (src_factory.@get ());
    }
}

class BlurayDevice : Device {
    Bluray.Disc disc;

    public override Gst.Element make_source () {
        return new BluraySource ((owned) disc);
    }

    public BlurayDevice (File file) throws Error {
        disc = new Bluray.Disc ();

        if (!disc.open (null_cast (file.get_path ()), null))
            throw new DeviceError.READ_FAILURE ("Failed to open Bluray disc %s",
                file.get_uri ());

        unowned Bluray.DiscInfo info = (!) disc.get_info ();

        if (!info.bluray_detected)
            throw new DeviceError.READ_FAILURE ("No Bluray disc found %s %s",
                "for URI", file.get_uri ());

        if (info.aacs_detected)
            if (!info.libaacs_detected)
                throw new DeviceError.READ_FAILURE ("Bluray disc is AACS %s",
                    "encrypted but libaacs is not installed");
            else if (!info.aacs_handled)
                throw new DeviceError.READ_FAILURE ("AACS error: %s",
                    info.aacs_error_code.to_string ());

        if (info.bdplus_detected)
            if (!info.libbdplus_detected)
                throw new DeviceError.READ_FAILURE ("BD+ encryption %s",
                    "detected but libbdplus is not installed");
            else if (!info.bdplus_handled)
                throw new DeviceError.READ_FAILURE (
                    "Failed to decrypt BD+ data");
    }
}
