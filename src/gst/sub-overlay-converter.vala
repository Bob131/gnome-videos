class SubOverlayConverter : Gst.Bin {
    public Gst.GhostPad video_sink_pad {private set; get;}
    public Gst.GhostPad sub_sink_pad {private set; get;}
    public Gst.GhostPad src_pad {private set; get;}

    static Gst.PadTemplate sub_sink_template;

    dynamic Gst.Element render;
    dynamic Gst.Element overlay;
    Gst.Element convert;

    public bool enable_subtitles {
        set {
            if (((!) video_sink_pad.get_target ()).parent == render)
                render.enable = value;
            else if (((!) video_sink_pad.get_target ()).parent == overlay)
                overlay.silent = !value;
        }
    }

    void switch_sink (
        Gst.Element target_sink,
        Gst.Pad target_video_sink_pad,
        Gst.Pad? target_sub_sink_pad
    ) {
        ulong p = 0;
        p = video_sink_pad.add_probe (Gst.PadProbeType.BLOCK_DOWNSTREAM, () => {
            video_sink_pad.remove_probe (p);

            var video_sink_sink_pad = (!) video_sink_pad.get_target ();
            var current_video_sink = (Gst.Element) video_sink_sink_pad.parent;
            var video_sink_src_pad = current_video_sink.srcpads.nth_data (0);

            if (target_sink == current_video_sink)
                return Gst.PadProbeReturn.OK;

            video_sink_src_pad.add_probe (
                Gst.PadProbeType.BLOCK | Gst.PadProbeType.EVENT_DOWNSTREAM,
                (pad, info) => {
                    if (info.get_event ().type != Gst.EventType.EOS)
                        return Gst.PadProbeReturn.PASS;

                    video_sink_src_pad.remove_probe (info.id);

                    if (target_sink != convert)
                        this.add (target_sink);

                    if (current_video_sink != convert)
                        current_video_sink.unlink (convert);

                    video_sink_pad.set_target (target_video_sink_pad);
                    sub_sink_pad.set_target (target_sub_sink_pad);

                    if (current_video_sink != convert) {
                        this.remove (current_video_sink);
                        current_video_sink.set_state (Gst.State.NULL);
                    }

                    if (target_sink != convert)
                        target_sink.link (convert);

                    target_sink.set_state (this.current_state);

                    return Gst.PadProbeReturn.DROP;
                }
            );

            video_sink_sink_pad.send_event (new Gst.Event.eos ());

            return Gst.PadProbeReturn.OK;
        });
    }

    void handle_sub_caps (Gst.Caps caps) {
        Gst.Element target_sink;
        Gst.Pad target_video_sink_pad, target_sub_sink_pad;

        var media_type = caps.get_structure (0).get_name ();
        switch (media_type) {
            case "text/x-raw":
            case "subpicture/x-dvd":
            case "subpicture/x-dvb":
            case "subpicture/x-xsub":
            case "subpicture/x-pgs":
                target_sink = overlay;
                target_video_sink_pad =
                    (!) overlay.get_static_pad ("video_sink");
                target_sub_sink_pad =
                    (!) overlay.get_static_pad ("subtitle_sink");
                break;
            case "application/x-ass":
            case "application/x-ssa":
                target_sink = render;
                target_video_sink_pad =
                    (!) render.get_static_pad ("video_sink");
                target_sub_sink_pad = (!) render.get_static_pad ("text_sink");
                break;
            default:
                critical ("Unhandled subtitle caps: %s", media_type);
                return;
        }

        switch_sink (target_sink, target_video_sink_pad, target_sub_sink_pad);
    }

    void unlink_subtitle_element () {
        switch_sink (convert, (!) convert.get_static_pad ("sink"), null);
    }

    public SubOverlayConverter () {
        render = null_cast (Gst.ElementFactory.make ("assrender", null));
        overlay = null_cast (Gst.ElementFactory.make ("subtitleoverlay", null));
        convert = null_cast (Gst.ElementFactory.make ("videoconvert", null));

        this.add (convert);

        video_sink_pad = new Gst.GhostPad ("video_sink",
            convert.sinkpads.nth_data (0));
        this.add_pad (video_sink_pad);

        sub_sink_pad = new Gst.GhostPad.no_target_from_template (null,
            sub_sink_template);
        this.add_pad (sub_sink_pad);

        sub_sink_pad.unlinked.connect (unlink_subtitle_element);

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

        src_pad = new Gst.GhostPad ("src", convert.srcpads.nth_data (0));
        this.add_pad (src_pad);
    }

    class construct {
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
