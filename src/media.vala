[SimpleType]
[CCode (cname = "gint64", get_value_function = "g_value_get_int64", set_value_function = "g_value_set_int64", default_value = "0LL", has_type_id = false)]
[IntegerType (rank = 10)]
struct Nanoseconds : int64 {}

class Media : Object {
    public File file {construct; get;}
    public weak Pipeline pipeline {construct; get;}

    public Nanoseconds duration {private set; get;}

    public virtual signal void got_duration (Nanoseconds duration) {
        this.duration = duration;
    }

    // TODO: Handle tag parsing
    public signal void got_title (string title);

    void handle_message (Gst.Message message) {
        switch (message.type) {
            case Gst.MessageType.STREAM_START:
                return_if_fail (duration == 0);
                Nanoseconds tmp;
                return_if_fail (
                    pipeline.query_duration (Gst.Format.TIME, out tmp));
                got_duration (tmp);
                break;
        }
    }

    public Media (File file, Pipeline pipeline) {
        Object (file: file, pipeline: pipeline);

        pipeline.get_bus ().message.connect (handle_message);
    }
}
