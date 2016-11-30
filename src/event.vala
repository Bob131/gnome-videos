// Provides a common API for passing around and getting data from both GstEvent
// and GstMessage
enum EventType {
    UNKNOWN,
    EOS,
    TAG,
    STREAM_START;

    public static EventType from_event_type (Gst.EventType type) {
        switch (type) {
            case Gst.EventType.EOS:
                return EOS;
            case Gst.EventType.TAG:
                return TAG;
            case Gst.EventType.STREAM_START:
                return STREAM_START;
            default:
                return UNKNOWN;
        }
    }

    public static EventType from_message_type (Gst.MessageType type) {
        switch (type) {
            case Gst.MessageType.EOS:
                return EOS;
            case Gst.MessageType.TAG:
                return TAG;
            case Gst.MessageType.STREAM_START:
                return STREAM_START;
            default:
                return UNKNOWN;
        }
    }
}

abstract class Event<T> : Object {
    public T data {construct; get;}
    public abstract EventType event_type {get;}
    public abstract Gst.TagList parse_tags ();
}

class PadEvent : Event<Gst.Event> {
    public override EventType event_type {get {
        return EventType.from_event_type (data.type);
    }}

    public override Gst.TagList parse_tags () {
        Gst.TagList tags;
        data.parse_tag (out tags);
        return (owned) tags;
    }

    public PadEvent (Gst.Event data) {
        Object (data: data);
    }
}

class BusEvent : Event<Gst.Message> {
    public override EventType event_type {get {
        return EventType.from_message_type (data.type);
    }}

    public override Gst.TagList parse_tags () {
        Gst.TagList tags;
        data.parse_tag (out tags);
        return (owned) tags;
    }

    public BusEvent (Gst.Message data) {
        Object (data: data);
    }
}
