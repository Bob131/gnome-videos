enum PlayerState {
    PAUSED = Gst.State.PAUSED,
    PLAYING = Gst.State.PLAYING
}

class AppController : Object {
    public PlaybackController playback {private set; get;}

    public bool media_loaded {
        get { return (PlaybackController?) playback != null; }
    }

    public bool fullscreen {set; get;}

    public signal void media_opened (Media media);

    public void open_file (File file) {
        media_closed ();
        playback = new PlaybackController (file);
        media_opened (playback.now_playing);
    }

    [Signal (run = "first")]
    public virtual signal void media_closed () {
        if (!media_loaded)
            return;

        playback.now_playing.pipeline.set_state (Gst.State.NULL);
        playback = (PlaybackController) null;
    }

    AppController () {
        Bus.@get ().pipeline_event["eos"].connect (() => fullscreen = false);
        Bus.@get ().error.connect_after (() => media_closed ());
    }

    static AppController? instance;

    public static AppController get_default () {
        if (instance == null)
            instance = new AppController ();
        return (!) instance;
    }
}

class PlaybackController : Object {
    public PlayerState state {private set; get; default = PlayerState.PAUSED;}
    public Media now_playing {private set; get;}

    public Nanoseconds position {
        set { now_playing.pipeline.seek (value); }
        get { return now_playing.pipeline.get_position (); }
    }

    [CCode (notify = false)]
    public bool paused {
        set { state = value ? PlayerState.PAUSED : PlayerState.PLAYING; }
        get { return state == PlayerState.PAUSED; }
    }

    [CCode (notify = false)]
    public bool playing {
        set { paused = !value; }
        get { return state == PlayerState.PLAYING; }
    }

    bool has_eos;

    public virtual signal void state_changed (PlayerState new_state) {
        // if we're playing from the end of a file, rewind first
        if (new_state == PlayerState.PLAYING && has_eos) {
            now_playing.pipeline.seek (0);
            has_eos = false;
        }

        now_playing.pipeline.set_state ((Gst.State) new_state);
    }

    public PlaybackController (File file) {
        now_playing = new Media (file);
        Bus.@get ().pipeline_event["eos"].connect (() => {
            has_eos = true;
            paused = true;
        });

        this.notify["state"].connect (() => state_changed (state));
        playing = true;
    }
}
