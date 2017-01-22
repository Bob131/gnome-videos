class SubOverlayConverter : Gst.Bin {
    public Gst.GhostPad video_sink_pad {private set; get;}
    public Gst.GhostPad sub_sink_pad {private set; get;}
    public Gst.GhostPad src_pad {private set; get;}

    internal static Gst.PadTemplate video_sink_template;
    internal static Gst.PadTemplate sub_sink_template;

    Gst.Element convert;

    dynamic Gst.Element subtitle_output_selector;

    dynamic Gst.Element render;
    dynamic Gst.Element overlay;

    public bool enable_subtitles {
        set {
            render.enable = value;
            overlay.silent = !value;
        }
    }

    void handle_sub_caps (Gst.Caps caps) {
        Gst.Pad target_sub_sink_pad;

        var media_type = caps.get_structure (0).get_name ();
        switch (media_type) {
            case "text/x-raw":
            case "subpicture/x-dvd":
            case "subpicture/x-dvb":
            case "subpicture/x-xsub":
            case "subpicture/x-pgs":
                target_sub_sink_pad =
                    (!) overlay.get_static_pad ("subtitle_sink");
                break;
            case "application/x-ass":
            case "application/x-ssa":
                target_sub_sink_pad = (!) render.get_static_pad ("text_sink");
                break;
            default:
                critical ("Unhandled subtitle caps: %s", media_type);
                return;
        }

        subtitle_output_selector.active_pad = target_sub_sink_pad.get_peer ();
    }

    public SubOverlayConverter () {
        convert = null_cast (Gst.ElementFactory.make ("videoconvert", null));
        render = null_cast (Gst.ElementFactory.make ("assrender", null));
        overlay = null_cast (Gst.ElementFactory.make ("subtitleoverlay", null));

        subtitle_output_selector =
            null_cast (Gst.ElementFactory.make ("output-selector", null));

        this.add_many (convert, render, overlay, subtitle_output_selector);

        convert.link_many (overlay, render);

        subtitle_output_selector.link (overlay);
        subtitle_output_selector.link (render);

        subtitle_output_selector.pad_negotiation_mode = 2;

        video_sink_pad = new Gst.GhostPad.from_template ("video_sink",
            convert.sinkpads.nth_data (0), video_sink_template);
        this.add_pad (video_sink_pad);

        sub_sink_pad = new Gst.GhostPad.from_template ("sub_sink",
            subtitle_output_selector.sinkpads.nth_data (0), sub_sink_template);
        this.add_pad (sub_sink_pad);

        Gst.pad_set_event_function (sub_sink_pad, (pad, parent, event) => {
            switch (event.type) {
                case Gst.EventType.CAPS:
                    Gst.Caps caps;
                    event.parse_caps (out caps);
                    ((SubOverlayConverter) parent).handle_sub_caps (caps);
                    break;
            }

            return pad.event_default (parent, event);
        });

        src_pad = new Gst.GhostPad ("src", render.srcpads.nth_data (0));
        this.add_pad (src_pad);
    }

    class construct {
        var video_caps = Gst.Caps.from_string ("video/x-raw(ANY)");
        video_sink_template = new Gst.PadTemplate ("video_sink",
            Gst.PadDirection.SINK, Gst.PadPresence.ALWAYS, video_caps);

        var sub_caps = Gst.Caps.from_string (
            "application/x-ass; "
            + "application/x-ssa; "
            + "text/x-raw; "
            + "subpicture/x-dvd; "
            + "subpicture/x-dvb; "
            + "subpicture/x-xsub; "
            + "subpicture/x-pgs;"
        );
        sub_sink_template = new Gst.PadTemplate ("sub_sink",
            Gst.PadDirection.SINK, Gst.PadPresence.ALWAYS, sub_caps);
    }
}
