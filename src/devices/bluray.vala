class BluraySource : Gst.Base.PushSrc {
    Bluray.Disc disc;

    bool new_toc;
    Gst.Toc? toc;

    Gee.HashMap<string, string> language_tags =
        new Gee.HashMap<string, string> ();

    const double BD_TIMEBASE = 90000;
    const double GST_TIMEBASE = Gst.SECOND;

    Bluray.TitleInfo get_title_info () {
        var ret = disc.get_title_info (disc.get_current_title (),
            disc.get_current_angle ());
        return_if_fail (ret != null);
        return (!)(owned) ret;
    }

    int64 bd_time_to_gst (uint64 bd_time) {
        return (int64) (bd_time / BD_TIMEBASE * GST_TIMEBASE);
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

            case Bluray.EventType.TITLE:
                var title_info = get_title_info (),
                    toc = new Gst.Toc (Gst.TocScope.CURRENT);

                foreach (unowned Bluray.TitleChapter chapter
                    in title_info.chapters)
                {
                    var toc_entry = new Gst.TocEntry (Gst.TocEntryType.CHAPTER,
                        chapter.index.to_string ());
                    var start = bd_time_to_gst (chapter.start);
                    toc_entry.set_start_stop_times (start,
                        start + bd_time_to_gst (chapter.duration));
                    toc.append_entry ((Gst.TocEntry)
                        Gst.mini_object_make_writable (toc_entry));
                }

                foreach (unowned Bluray.ClipInfo clip in title_info.clips) {
                    foreach (unowned Bluray.StreamInfo info in clip.audio_streams)
                        language_tags["%08x".printf (info.pid)] = info.lang;
                    foreach (unowned Bluray.StreamInfo info in clip.pg_streams)
                        language_tags["%08x".printf (info.pid)] = info.lang;
                    foreach (unowned Bluray.StreamInfo info in clip.ig_streams)
                        language_tags["%08x".printf (info.pid)] = info.lang;
                }

                new_toc = true;
                this.toc = toc;

                break;

            default:
                debug (@"Unhandled Bluray event: $(event.type)");
                break;
        }
    }

    public override Gst.FlowReturn fill (Gst.Buffer buffer) {
        Bluray.Event event;
        while (disc.get_event (out event))
            handle_bd_event (event);

        buffer.pts = disc.tell_time ();
        buffer.offset = disc.tell ();
        buffer.offset_end = buffer.offset + buffer.get_size ();

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
        disc.seek (segment.time);
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

    void correct_stream_language_tags (Gst.Message message) {
        if (message.src == this)
            return;

        Gst.StreamCollection streams;
        message.parse_stream_collection (out streams);

        for (var i = 0; i < streams.get_size (); i++) {
            var stream = streams.get_stream (i);
            string stream_id = null_cast (stream.get_stream_id ());

            if (!("/" in stream_id))
                continue;

            stream_id = stream_id.split ("/")[1];

            if (!language_tags.has_key (stream_id))
                continue;

            var new_tags = new Gst.TagList.empty ();
            new_tags.add_value (Gst.TagMergeMode.REPLACE,
                Gst.Tags.LANGUAGE_CODE, language_tags[stream_id]);

            Gst.TagList tags = null_cast (stream.get_tags ());
            tags = (!) tags.merge (new_tags, Gst.TagMergeMode.KEEP);

            stream.set_tags (tags);
        }

        var new_message = new Gst.Message.stream_collection (this, streams);
        this.post_message (new_message);
    }

    public override bool start () {
        // init event queue
        disc.get_event (null);

        disc.get_titles (Bluray.TitleFlags.RELEVANT);
        disc.select_title (disc.get_main_title ());

        Bus.@get ().pipeline_message["stream-collection"].connect (
            correct_stream_language_tags);

        return true;
    }

    public override void state_changed (
        Gst.State old,
        Gst.State @new,
        Gst.State pending
    ) {
        if (toc != null && @new == Gst.State.PLAYING) {
            var gst_event = new Gst.Event.toc ((!) toc, !new_toc);
            if (new_toc)
                new_toc = false;
            this.srcpads.nth_data (0).push_event (gst_event);
        }
    }

    public BluraySource (owned Bluray.Disc disc) {
        this.disc = (owned) disc;
        this.blocksize = 200 * 192;
    }

    class construct {
        Gst.StaticPadTemplate src_factory = {
            "src",
            Gst.PadDirection.SRC,
            Gst.PadPresence.ALWAYS,
            Gst.StaticCaps () {
                @string = "video/mpegts, systemstream=(boolean)true, packetsize=(int)192"
            }
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
