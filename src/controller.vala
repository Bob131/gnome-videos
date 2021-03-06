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
        Device device;

        if (file.query_file_type (FileQueryInfoFlags.NONE)
            == FileType.DIRECTORY)
        {
            try {
                device = Device.new_from_directory (file);
            } catch (Error e) {
                Bus.@get ().error (e);
                return;
            }
        } else
            device = new UriDevice (file);

        media_closed ();
        playback = new PlaybackController (device);
        media_opened (playback.now_playing);
    }

    [Signal (run = "first")]
    public virtual signal void media_closed () {
        if (!media_loaded)
            return;

        playback.state_changed ((PlayerState) Gst.State.NULL);
        playback = (PlaybackController) null;
    }

    AppController () {
        this.notify["fullscreen"].connect (() => Bus.@get ().activity ());
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

    Pipeline pipeline;

    bool has_eos;

    public Nanoseconds position {
        set { has_eos = false; pipeline.seek (value); }
        get { return pipeline.get_position (); }
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

    bool checking_activity = false;
    Timer activity_timer = new Timer ();

    void handle_activity () {
        if (checking_activity) {
            activity_timer.reset ();
            return;
        }

        checking_activity = true;
        activity_timer.start ();

        Timeout.add (500, () => {
            if (activity_timer.elapsed () < 5)
                return Source.CONTINUE;

            checking_activity = false;

            // remain active, but don't waste wake ups re-checking
            if (Bus.@get ().idle_blocker)
                return Source.REMOVE;

            Bus.@get ().inactivity_timeout ();
            return Source.REMOVE;
        });
    }

    public virtual signal void state_changed (PlayerState new_state) {
        // if we're playing from the end of a file, rewind first
        if (new_state == PlayerState.PLAYING && has_eos) {
            pipeline.seek (0);
            has_eos = false;
        }

        if (new_state == PlayerState.PLAYING)
            Bus.@get ().idle_release (this);
        else
            Bus.@get ().idle_hold (this);

        pipeline.set_state ((Gst.State) new_state);
    }

    public PlaybackController (Device device) {
        now_playing = new Media ();
        Bus.@get ().pipeline_event["eos"].connect (() => {
            has_eos = true;
            paused = true;
        });

        pipeline = new Pipeline (device);

        Bus.@get ().activity.connect (handle_activity);
        Bus.@get ().notify["idle-blocker"].connect (handle_activity);

        this.notify["state"].connect (() => state_changed (state));
        playing = true;

        handle_activity ();
    }
}
