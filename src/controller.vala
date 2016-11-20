enum PlayerState {
    STOPPED = Gst.State.NULL,
    PAUSED = Gst.State.PAUSED,
    PLAYING = Gst.State.PLAYING
}

class Controller : Object {
    public PlayerState state {set; get; default = PlayerState.STOPPED;}

    public signal void play_file (File file);
    public signal void state_changed (PlayerState new_state);

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
