// A "bus" to facilitate communication between objects without having to walk
// the ownership tree
class Bus : Object {
    // Whether any application state should prevent us from considering the user
    // as 'idly watching'
    public bool idle_blocker {private set; get;}

    Gee.HashMap<Type, unowned Object> instances =
        new Gee.HashMap<Type, unowned Object> ();

    [Signal (detailed = true)]
    public virtual signal void object_constructed (Object object) {
        var type = object.get_type ();
        return_if_fail (!instances.has_key (type));
        object.weak_ref (() => instances.unset (type));
        instances[type] = object;
    }

    public unowned T get_instance<T> ()
        requires (typeof (T).is_a (typeof (Object)))
        requires (instances.has_key (typeof (T)))
    {
        return instances[typeof (T)];
    }

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

    public signal void activity ();
    public signal void inactivity_timeout ();

    uint total_holds;
    Gee.HashMap<Object, uint> idle_holds = new Gee.HashMap<Object, int> ();

    public void idle_hold (Object object) {
        if (!idle_holds.has_key (object))
            idle_holds[object] = 0;

        idle_holds[object] = idle_holds[object] + 1;
        total_holds++;

        if (!idle_blocker)
            activity ();

        idle_blocker = true;
    }

    public void idle_release (Object object) {
        if (!idle_holds.has_key (object))
            return;

        idle_holds[object] = idle_holds[object] - 1;
        if (idle_holds[object] == 0)
            idle_holds.unset (object);

        total_holds--;
        if (total_holds == 0)
            idle_blocker = false;
    }

    Bus () {}

    static Bus? instance;

    public new static Bus @get () {
        if (instance == null)
            instance = new Bus ();
        return (!) instance;
    }
}
