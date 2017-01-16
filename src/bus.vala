// A "bus" to facilitate communication between objects without having to walk
// the ownership tree
class Bus : Object {
    [Signal (detailed = true)]
    public signal void object_constructed (Object object);

    Bus () {}

    static Bus? instance;

    public new static Bus @get () {
        if (instance == null)
            instance = new Bus ();
        return (!) instance;
    }
}
