enum PlayerState {
    STOPPED = Gst.State.NULL,
    PAUSED = Gst.State.PAUSED,
    PLAYING = Gst.State.PLAYING
}

class Controller : Object {
    public PlayerState state {private set; get; default = PlayerState.STOPPED;}
    public Media? now_playing {private set; get;}

    public Nanoseconds position {
        set {
            return_if_fail (state != PlayerState.STOPPED);
            return_if_fail (now_playing != null);
            seek (value);
        }
        get {
            if (state == PlayerState.STOPPED || now_playing == null)
                return 0;

            Nanoseconds ret;
            ((!) now_playing).pipeline.query_position (Gst.Format.TIME,
                out ret);
            return ret;
        }}

    public virtual signal void state_changed (PlayerState new_state) {
        if (new_state == PlayerState.STOPPED)
            now_playing = null;
    }

    public void stop () {
        state = PlayerState.STOPPED;
    }

    public void pause () {
        state = PlayerState.PAUSED;
    }

    public void play () {
        state = PlayerState.PLAYING;
    }

    [Signal (run = "last")]
    public virtual signal void media_opened (Media media) {
        now_playing = media;
        play ();
    }

    public signal void open_file (File file);

    public signal void seek (Nanoseconds new_offset);

    Controller () {
        this.notify["state"].connect (() => state_changed (state));
    }

    static Controller? instance;

    public static Controller get_default () {
        if (instance == null)
            instance = new Controller ();
        return (!) instance;
    }
}
