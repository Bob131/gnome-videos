class Media : Object {
    public Tags tags {construct; get;}
    public Nanoseconds duration {private set; get;}

    public virtual signal void got_duration (Nanoseconds duration) {
        this.duration = duration;
    }

    public Media () {
        Object (tags: new Tags ());

        Bus.@get ().pipeline_message["stream-start"].connect (() => {
            Pipeline pipeline = Bus.@get ().get_instance ();
            got_duration (pipeline.get_duration ());
        });
    }
}
