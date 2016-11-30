enum PlayerState {
    PAUSED = Gst.State.PAUSED,
    PLAYING = Gst.State.PLAYING
}

class AppController : Object {
    public PlaybackController playback {private set; get;}

    public bool media_loaded {
        get { return (PlaybackController?) playback != null; }
    }

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

    AppController () {}

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
        get {
            Nanoseconds ret;
            now_playing.pipeline.query_position (Gst.Format.TIME, out ret);
            return ret;
        }
    }

    public signal void state_changed (PlayerState new_state);

    public void pause () {
        state = PlayerState.PAUSED;
    }

    public void play () {
        // if we're playing from the end of a file, rewind first
        if (now_playing.duration > 0 && position == now_playing.duration - 1)
            position = 0;

        state = PlayerState.PLAYING;
    }

    public PlaybackController (File file) {
        now_playing = new Media (this, file);
        this.notify["state"].connect (() => state_changed (state));
        this.play ();
    }
}
