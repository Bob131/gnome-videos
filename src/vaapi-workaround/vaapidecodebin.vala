extern string? get_brand_string ();

class VaapiDecodeBin : Gst.Bin {
    public Gst.GhostPad sink_pad {private set; get;}
    public Gst.GhostPad src_pad {private set; get;}

    construct {
        dynamic Gst.Element decoder =
            null_cast (Gst.ElementFactory.make ("vaapidecodebin", null));
        Gst.Element post_processor =
            null_cast (Gst.ElementFactory.make ("vaapipostproc", null));

        decoder.disable_vpp = true;

        this.add_many (decoder, post_processor);

        sink_pad = new Gst.GhostPad ("sink", decoder.sinkpads.nth_data (0));
        this.add_pad (sink_pad);

        src_pad = new Gst.GhostPad ("src", post_processor.srcpads.nth_data (0));
        this.add_pad (src_pad);

        decoder.set_state (this.current_state);
        post_processor.set_state (this.current_state);

        assert (decoder.link (post_processor));
    }

    static string video_caps_with_features (
        owned string features,
        string format
    ) {
        if (features.length != 0)
            features = @"($features)";

        return @"video/x-raw$features, "
            + @"format = (string) $format, "
            + @"width = $(Gst.Video.SIZE_RANGE), "
            + @"height = $(Gst.Video.SIZE_RANGE), "
            + @"framerate = $(Gst.Video.FPS_RANGE)";
    }

    static string stringify_caps (string[] caps) {
        var ret = "";
        foreach (var cap in caps)
            ret += @"$cap; ";
        return ret;
    }

    static string codec_caps;
    static string output_caps;

    class construct {
        var h264_caps = "video/x-h264, profile=(string){main, high, constrained-baseline, stereo-high}";

        if ("Celeron" in null_cast<string, string?> (get_brand_string ()))
            h264_caps += ", width = [1, 1920], height = [1, 1080]";

        codec_caps = stringify_caps ({
            "video/mpeg, mpegversion=2, systemstream=(boolean)false, profile=(string){simple, main}",
            h264_caps,
            "video/x-wmv, wmvversion=3, format=(string){WMV3, WVC1}, profile=(string){simple, main, advanced}"
        });

        output_caps = stringify_caps ({
            video_caps_with_features ("meta:GstVideoGLTextureUploadMeta",
                "{ RGBA, BGRA }"),
        });

        Gst.StaticPadTemplate sink_factory = {
            "sink",
            Gst.PadDirection.SINK,
            Gst.PadPresence.ALWAYS,
            Gst.StaticCaps () {
                @string = codec_caps
            }
        };

        Gst.StaticPadTemplate src_factory = {
            "src",
            Gst.PadDirection.SRC,
            Gst.PadPresence.ALWAYS,
            Gst.StaticCaps () {
                @string = output_caps
            }
        };

        add_pad_template (sink_factory.@get ());
        add_pad_template (src_factory.@get ());

        set_metadata ("GNOME Videos' VA-API decoder bin wrapper",
            "Codec/Decoder/Video",
            "A vaapidecoderbin wrapper",
            "Bob131 <bob@bob131.so>");
    }
}

bool vaapi_plugin_init (Gst.Plugin plugin) {
    Gst.ElementFactory factory =
        null_cast (Gst.ElementFactory.find ("vaapidecodebin"));
    factory.set_rank (0);

    return Gst.Element.register (plugin, "gvvaapidecodebin", 258,
        typeof (VaapiDecodeBin));
}
