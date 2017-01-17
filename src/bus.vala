// A "bus" to facilitate communication between objects without having to walk
// the ownership tree
class Bus : Object {
    [Signal (detailed = true)]
    public signal void object_constructed (Object object);

    [Signal (detailed = true)]
    public signal void pipeline_pad_event (Gst.Event event);
    [Signal (detailed = true)]
    public signal void pipeline_message (Gst.Message message);
    [Signal (detailed = true)]
    public signal void pipeline_event (Event event);

    public void emit_pipeline_event (Event event) {
        if (event is PadEvent) {
            var pad_event = ((PadEvent) event).data;
            pipeline_pad_event[Gst.EventType.get_name (pad_event.type)] (
                pad_event);
        } else if (event is BusEvent) {
            var message = ((BusEvent) event).data;
            pipeline_message[Gst.MessageType.get_name (message.type)] (message);
        }

        pipeline_event[event.event_type.to_nick ()] (event);
    }

    [Signal (detailed = true)]
    public signal void tag_updated (List<ValueWrapper> values);

    public signal void error (Error e);

    Bus () {}

    static Bus? instance;

    public new static Bus @get () {
        if (instance == null)
            instance = new Bus ();
        return (!) instance;
    }
}
