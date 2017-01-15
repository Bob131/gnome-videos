[SimpleType]
[CCode (cname = "gint64", get_value_function = "g_value_get_int64", set_value_function = "g_value_set_int64", default_value = "0LL", has_type_id = false)]
[IntegerType (rank = 10)]
struct Nanoseconds : int64 {}

class ValueWrapper : Object {
    public Value @value {construct; get;}

    public ValueWrapper (Value @value) {
        Object (@value: @value);
    }
}

class Tags : Object {
    HashTable<string, List<ValueWrapper>> table =
        new HashTable<string, List<ValueWrapper>> (str_hash, str_equal);

    public new unowned Value @get (string tag) {
        return table[tag].data.@value;
    }

    public unowned List<ValueWrapper> get_list (string tag) {
        return table[tag];
    }

    public signal void tag_updated (string name);

    public void add (Gst.TagList tags) {
        tags.foreach ((_, tag) => {
            var list = table.take (tag);

            Value owned_value;
            Gst.Tags.list_copy_value (out owned_value, tags, tag);

            if (list.length () > 0 && Gst.Tags.is_fixed (tag))
                list.data = new ValueWrapper ((owned) owned_value);
            else
                list.prepend (new ValueWrapper ((owned) owned_value));

            table[tag] = (owned) list;
            tag_updated (tag);
        });
    }
}

class Media : Object {
    public weak PlaybackController playback_controller {construct; get;}
    public File file {construct; get;}
    public Tags tags {construct; get;}
    public Pipeline pipeline {private set; get;}

    public Nanoseconds duration {private set; get;}
    public Gst.StreamCollection streams {private set; get;}

    public virtual signal void got_duration (Nanoseconds duration) {
        this.duration = duration;
    }

    public virtual signal void got_streams (Gst.StreamCollection streams) {
        this.streams = streams;
    }

    public signal void selected_streams_updated (Gst.StreamCollection streams);

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

    void handle_message (Event event) {
        switch (event.event_type) {
            case EventType.STREAM_START:
                if (!(event is BusEvent))
                    return;

                Nanoseconds tmp;
                return_if_fail (
                    pipeline.query_duration (Gst.Format.TIME, out tmp));
                got_duration (tmp);

                break;

            case EventType.STREAM_COLLECTION:
                var streams = event.parse_streams ();
                fix_ass_stream_type (streams);
                got_streams (streams);
                break;

            case EventType.STREAM_SELECTION:
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
                selected_streams_updated (selected_streams);

                break;

            case EventType.TAG:
                tags.add (event.parse_tags ());
                break;
        }
    }

    public Media (PlaybackController controller, File file) {
        Object (playback_controller: controller, file: file, tags: new Tags ());

        pipeline = new Pipeline (this);

        pipeline.event.connect (handle_message);
    }
}
