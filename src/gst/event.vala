// Provides a common API for passing around and getting data from both GstEvent
// and GstMessage
enum EventType {
    UNKNOWN,
    EOS,
    TAG,
    STREAM_START,
    STREAM_COLLECTION,
    STREAM_SELECTION,
    TOC;

    public string to_nick () {
        EnumClass @class = (EnumClass) typeof (EventType).class_ref ();
        unowned EnumValue? @value = @class.get_value (this);
        return_if_fail (@value != null);
        return ((!) @value).value_nick;
    }

    public static EventType from_event_type (Gst.EventType type) {
        switch (type) {
            case Gst.EventType.EOS:
                return EOS;
            case Gst.EventType.TAG:
                return TAG;
            case Gst.EventType.STREAM_START:
                return STREAM_START;
            case Gst.EventType.STREAM_COLLECTION:
                return STREAM_COLLECTION;
            case Gst.EventType.SELECT_STREAMS:
                return STREAM_SELECTION;
            case Gst.EventType.TOC:
                return TOC;
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
            case Gst.MessageType.STREAM_COLLECTION:
                return STREAM_COLLECTION;
            case Gst.MessageType.STREAMS_SELECTED:
                return STREAM_SELECTION;
            case Gst.MessageType.TOC:
                return TOC;
            default:
                return UNKNOWN;
        }
    }
}

abstract class Event<T> : Object {
    public T data {construct; get;}
    public abstract EventType event_type {get;}
    public abstract Gst.TagList parse_tags ();
    public abstract Gst.StreamCollection parse_streams ();
}

class PadEvent : Event<Gst.Event> {
    public override EventType event_type {get {
        return EventType.from_event_type (data.type);
    }}

    public override Gst.TagList parse_tags ()
        requires (event_type == EventType.TAG)
    {
        Gst.TagList tags;
        data.parse_tag (out tags);
        return (owned) tags;
    }

    public override Gst.StreamCollection parse_streams ()
        requires (event_type == EventType.STREAM_COLLECTION)
    {
        Gst.StreamCollection streams;
        data.parse_stream_collection (out streams);
        return streams;
    }

    public PadEvent (Gst.Event data) {
        Object (data: data);
    }
}

class BusEvent : Event<Gst.Message> {
    public override EventType event_type {get {
        return EventType.from_message_type (data.type);
    }}

    public override Gst.TagList parse_tags ()
        requires (event_type == EventType.TAG)
    {
        Gst.TagList tags;
        data.parse_tag (out tags);
        return (owned) tags;
    }

    public override Gst.StreamCollection parse_streams ()
        requires (event_type == EventType.STREAM_COLLECTION)
    {
        Gst.StreamCollection streams;
        data.parse_stream_collection (out streams);
        return streams;
    }

    public BusEvent (Gst.Message data) {
        Object (data: data);
    }
}
