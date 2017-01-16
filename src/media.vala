class Media : Object {
    public File file {construct; get;}
    public Tags tags {construct; get;}
    public Pipeline pipeline {private set; get;}

    public Nanoseconds duration {private set; get;}

    public virtual signal void got_duration (Nanoseconds duration) {
        this.duration = duration;
    }

    public Media (File file) {
        Object (file: file, tags: new Tags ());

        pipeline = new Pipeline (file);
        Bus.@get ().object_constructed["pipeline"] (pipeline);

        Bus.@get ().pipeline_event["stream-start"].connect ((event) => {
            if (!(event is BusEvent))
                return;

            got_duration (pipeline.get_duration ());
        });
    }
}
