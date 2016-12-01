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

    public new unowned List<ValueWrapper> @get (string tag) {
        return table[tag];
    }

    public signal void tag_added (string name);

    public void add (Gst.TagList tags) {
        tags.foreach ((_, tag) => {
            var list = table.take (tag);
            unowned Value? @value;
            for (var i = 0; (@value = tags.get_value_index (tag, i)) != null;
                i++)
            {
                var owned_value = Value (((!) @value).type ());
                ((!) @value).copy (ref owned_value);
                list.prepend (new ValueWrapper (owned_value));
            }
            table[tag] = (owned) list;
            tag_added (tag);
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

    void handle_message (Event event) {
        switch (event.event_type) {
            case EventType.STREAM_START:
                if (!(event is BusEvent))
                    return;

                return_if_fail (duration == 0);

                Nanoseconds tmp;
                return_if_fail (
                    pipeline.query_duration (Gst.Format.TIME, out tmp));
                got_duration (tmp);

                break;

            case EventType.STREAM_COLLECTION:
                got_streams (event.parse_streams ());
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
