class StreamManager : Object {
    public RadioSubmenu audio {construct; get;}
    public RadioSubmenu subtitles {construct; get;}

    unowned Pipeline pipeline;
    unowned SubOverlayConverter subtitle_sink;

    Gst.StreamCollection selected_cache;

    void handle_streams (Gst.StreamCollection streams) {
        Gtk.ModelButton[] audio_buttons = {};
        Gtk.ModelButton[] subtitle_buttons = {};

        for (var i = 0; i < streams.get_size (); i++) {
            var stream = streams.get_stream (i);

            var model_button = new Gtk.ModelButton ();
            model_button.visible = true;
            model_button.role = Gtk.ButtonRole.RADIO;
            model_button.name = null_cast (stream.get_stream_id ());

            var language = "Unknown";
            string[] stream_desc = {};

            if (stream.get_caps () != null) {
                var caps = (!) stream.get_caps ();
                unowned Gst.Structure structure = (!) caps.get_structure (0);

                int channels;
                if (structure.get_int ("channels", out channels))
                    stream_desc += @"$(channels)ch.";
            }

            if (stream.get_tags () != null) {
                var tags = (!) stream.get_tags ();

                string language_code;
                if (tags.get_string (Gst.Tags.LANGUAGE_CODE, out language_code))
                {
                    string? language_name =
                        Gst.Tag.get_language_name (language_code);
                    language = language_name != null ? (!) language_name
                        : language_code;
                }

                string codec;
                if (tags.get_string (Gst.Tags.CODEC, out codec)
                        || tags.get_string (Gst.Tags.AUDIO_CODEC, out codec)
                        || tags.get_string (Gst.Tags.SUBTITLE_CODEC, out codec))
                    stream_desc += codec;
            }

            model_button.text = stream_desc.length == 0 ? language :
                @"$language ($(string.joinv (" ", (string?[]?) stream_desc)))";

            if (Gst.StreamType.AUDIO in stream.get_stream_type ())
                audio_buttons += model_button;
            else if (Gst.StreamType.TEXT in stream.get_stream_type ())
                subtitle_buttons += model_button;
        }

        audio.update (audio_buttons);
        subtitles.update (subtitle_buttons);
    }

    void handle_selected_streams (Gst.StreamCollection streams) {
        selected_cache = streams;

        for (var i = 0; i < streams.get_size (); i++) {
            var stream = streams.get_stream (i);
            string stream_name = null_cast (stream.get_stream_id ());

            if (Gst.StreamType.AUDIO in stream.get_stream_type ())
                audio.select_child_by_name (stream_name);
            else if (Gst.StreamType.TEXT in stream.get_stream_type ())
                subtitles.select_child_by_name (stream_name);
        }
    }

    void stream_selected (RadioSubmenu menu, string selected_name) {
        var stream_list = new List<string> ();

        for (var i = 0; i < selected_cache.get_size (); i++) {
            var stream = selected_cache.get_stream (i);
            string stream_name = null_cast (stream.get_stream_id ());

            if (stream_name == menu.selected_child.name)
                stream_list.append (selected_name);
            else
                stream_list.append (stream_name);
        }

        pipeline.select_streams (stream_list);
    }

    void fix_ass_stream_type (Gst.StreamCollection streams) {
        for (var i = 0; i < streams.get_size (); i++) {
            var stream = streams.get_stream (i);

            if (!(Gst.StreamType.UNKNOWN in stream.get_stream_type ()))
                continue;

            if (stream.get_caps () == null)
                continue;

            Gst.Caps stream_caps = null_cast (stream.get_caps ());
            var media_type = stream_caps.get_structure (0).get_name ();

            switch (media_type) {
                case "application/x-ass":
                case "application/x-ssa":
                    break;
                default:
                    continue;
            }

            stream.set_stream_type (stream.get_stream_type ()
                | Gst.StreamType.TEXT);
        }
    }

    public StreamManager (RadioSubmenu audio, RadioSubmenu subtitles) {
        Object (audio: audio, subtitles: subtitles);

        Bus.@get ().object_constructed["pipeline"].connect (
            (object) => pipeline = (!) (object as Pipeline));
        Bus.@get ().object_constructed["subtitle-sink"].connect (
            (object) => subtitle_sink = (!) (object as SubOverlayConverter));

        Bus.@get ().pipeline_event["stream-collection"].connect ((event) => {
            var streams = event.parse_streams ();
            fix_ass_stream_type (streams);
            handle_streams (streams);
        });

        Bus.@get ().pipeline_event["stream-selection"].connect ((event) => {
            if (!(event is BusEvent))
                return;

            unowned Gst.Structure structure =
                ((BusEvent) event).data.get_structure ();
            return_if_fail (structure.has_field ("streams"));
            unowned Value @value = (!) structure.get_value ("streams");

            var selected_streams = new Gst.StreamCollection (null);

            for (var i = 0; i < Gst.ValueArray.get_size (@value); i++) {
                unowned Value stream_value =
                    (!) Gst.ValueArray.get_value (@value, i);
                selected_streams.add_stream (
                    (Gst.Stream) stream_value.get_object ());
            }

            fix_ass_stream_type (selected_streams);
            handle_selected_streams (selected_streams);
        });

        audio.child_activated.connect (stream_selected);

        subtitles.child_activated.connect ((selected_name) => {
            if (selected_name == "none") {
                subtitle_sink.enable_subtitles = false;
                subtitles.select_child_by_name ("none");
                return;
            }

            subtitle_sink.enable_subtitles = true;

            stream_selected (subtitles, selected_name);

            subtitles.select_child_by_name (selected_name);
        });
    }
}
