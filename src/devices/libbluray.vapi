[CCode (cheader_filename = "libbluray/bluray.h", lower_case_cprefix = "bd_")]
namespace Bluray {
    public enum VideoFormat {
        480I,
        576I,
        480P,
        1080I,
        720P,
        1080P,
        576P
    }

    public enum FrameRate {
        [CCode (cname = "BLURAY_VIDEO_RATE_24000_1001")]
        [Description (nick = "23.976Hz")]
        23_976Hz,
        [CCode (cname = "BLURAY_VIDEO_RATE_24")]
        24Hz,
        [CCode (cname = "BLURAY_VIDEO_RATE_25")]
        25Hz,
        [CCode (cname = "BLURAY_VIDEO_RATE_30000_1001")]
        [Description (nick = "29.97Hz")]
        29_97Hz,
        [CCode (cname = "BLURAY_VIDEO_RATE_50")]
        50Hz,
        [CCode (cname = "BLURAY_VIDEO_RATE_60000_1001")]
        [Description (nick = "59.94Hz")]
        59_94Hz
    }

    [CCode (cname = "int", cprefix = "BD_AACS_")]
    public enum AacsError {
        CORRUPTED_DISC,
        NO_CONFIG,
        [CCode (cname = "BD_AACS_NO_PK")]
        NO_PROCESSING_KEY,
        NO_CERT,
        CERT_REVOKED,
        MMC_FAILED;

        public string to_string () {
            switch (this) {
                case CORRUPTED_DISC:
                    return "Failed to read AACS files";
                case NO_CONFIG:
                    return "Missing config file";
                case NO_PROCESSING_KEY:
                    return "Failed to find matching processing key";
                case NO_CERT:
                    return "No valid certificate found";
                case CERT_REVOKED:
                    return "Certificate has been revoked";
                case MMC_FAILED:
                    return "Failed to read data from drive";
                default:
                    return "Unknown error";
            }
        }
    }

    [CCode (cname = "uint32_t", cprefix = "BD_EVENT_", has_type_id = false)]
    public enum EventType {
        NONE,
        ERROR,
        READ_ERROR,
        ENCRYPTED,

        ANGLE,
        TITLE,
        PLAYLIST,
        PLAYITEM,
        CHAPTER,
        PLAYMARK,
        END_OF_TITLE,

        AUDIO_STREAM,
        IG_STREAM,
        PG_TEXTST_STREAM,
        PIP_PG_TEXTST_STREAM,
        SECONDARY_AUDIO_STREAM,
        SECONDARY_VIDEO_STREAM,

        PG_TEXTST,
        PIP_PG_TEXTST,
        SECONDARY_AUDIO,
        SECONDARY_VIDEO,
        SECONDARY_VIDEO_SIZE,

        PLAYLIST_STOP,
        DISCONTINUITY,
        SEEK,
        STILL,
        STILL_TIME,
        SOUND_EFFECT,

        IDLE,
        POPUP,
        MENU,
        STEREOSCOPIC_STATUS,
        KEY_INTEREST_TABLE,
        UO_MASK_CHANGED
    }

    [CCode (cname = "uint8_t", cprefix = "TITLES_")]
    [Flags]
    public enum TitleFlags {
        ALL,
        FILTER_DUP_TITLE,
        FILTER_DUP_CLIP,
        RELEVANT
    }

    [CCode (cname = "BD_EVENT")]
    public struct Event {
        [CCode (cname = "event")]
        EventType type;
        uint32 param;
    }

    [CCode (cname = "BLURAY_TITLE")]
    [Compact]
    public class Title {
        public string? name;
        [CCode (type = "uint8_t")]
        public bool interactive;
        [CCode (type = "uint8_t")]
        public bool accessible;
        [CCode (type = "uint8_t")]
        public bool hidden;
        [CCode (type = "uint8_t")]
        public bool bdj;
        public uint32 id_ref;
    }

    [CCode (cname = "BLURAY_STREAM_INFO")]
    [Compact]
    public class StreamInfo {
        public uint8 coding_type;
        public uint8 format;
        public uint8 rate;
        public uint8 char_code;
        public uint8 lang[4];
        public uint16 pid;
        public uint8 aspect;
        public uint8 subpath_i;
    }

    [CCode (cname = "BLURAY_CLIP_INFO")]
    [Compact]
    public class ClipInfo {
        [CCode (cname = "pkt_count")]
        public uint32 packet_count;
        public uint8 still_mode;
        public uint16 still_time;
        [CCode (array_length_cname = "video_stream_count", array_length_type = "uint8_t")]
        public StreamInfo[] video_streams;
        [CCode (array_length_cname = "audio_stream_count", array_length_type = "uint8_t")]
        public StreamInfo[] audio_streams;
        [CCode (array_length_cname = "pg_stream_count", array_length_type = "uint8_t")]
        public StreamInfo[] pg_streams;
        [CCode (array_length_cname = "ig_stream_count", array_length_type = "uint8_t")]
        public StreamInfo[] ig_streams;
        [CCode (cname = "sec_audio_streams", array_length_cname = "sec_audio_stream_count", array_length_type = "uint8_t")]
        public StreamInfo[] second_audio_streams;
        [CCode (cname = "sec_video_streams", array_length_cname = "sec_video_stream_count", array_length_type = "uint8_t")]
        public StreamInfo[] second_video_streams;
        public uint64 start_time;
        public uint64 in_time;
        public uint64 out_time;
    }

    [CCode (cname = "BLURAY_TITLE_CHAPTER")]
    [Compact]
    public class TitleChapter {
        [CCode (cname = "idx")]
        public uint32 index;
        public uint64 start;
        public uint64 duration;
        public uint64 offset;
        public uint clip_ref;
    }

    [CCode (cname = "BLURAY_TITLE_MARK")]
    [Compact]
    public class TitleMark {
        [CCode (cname = "idx")]
        public uint32 index;
        public int type;
        public uint64 start;
        public uint64 duration;
        public uint64 offset;
        public uint clip_ref;
    }

    [CCode (cname = "BLURAY_TITLE_INFO", free_function = "bd_free_title_info")]
    [Compact]
    public class TitleInfo {
        [CCode (cname = "idx")]
        public uint32 index;
        public uint32 playlist;
        public uint64 duration;
        public uint8 angle_count;
        [CCode (array_length_cname = "clip_count", array_length_type = "uint32")]
        public ClipInfo[] clips;
        [CCode (array_length_cname = "chapter_count", array_length_type = "uint32")]
        public TitleChapter?[] chapters;
        [CCode (array_length_cname = "mark_count", array_length_type = "uint32")]
        public TitleMark[] marks;
    }

    [CCode (cname = "BLURAY_DISC_INFO")]
    [Compact]
    public class DiscInfo {
        [CCode (type = "uint8_t")]
        public bool bluray_detected;

        [CCode (type = "uint8_t")]
        public bool first_play_supported;
        [CCode (type = "uint8_t")]
        public bool top_menu_supported;

        public uint32 num_hdmv_titles;
        public uint32 num_bdj_titles;
        public uint32 num_unsupported_titles;

        [CCode (type = "uint8_t")]
        public bool aacs_detected;
        [CCode (type = "uint8_t")]
        public bool libaacs_detected;
        [CCode (type = "uint8_t")]
        public bool aacs_handled;

        [CCode (type = "uint8_t")]
        public bool bdplus_detected;
        [CCode (type = "uint8_t")]
        public bool libbdplus_detected;
        [CCode (type = "uint8_t")]
        public bool bdplus_handled;

        public AacsError aacs_error_code;
        public int aacs_mkbv;

        public uint8 disc_id[20];

        [CCode (type = "uint8_t")]
        public bool bdj_detected;
        [CCode (type = "uint8_t")]
        public bool bdj_supported;
        [CCode (type = "uint8_t")]
        public bool libjvm_detected;
        [CCode (type = "uint8_t")]
        public bool bdj_handled;

        public uint8 bdplus_gen;
        public uint32 bdplus_date;

        [CCode (type = "uint8_t")]
        public VideoFormat video_format;
        [CCode (type = "uint8_t")]
        public FrameRate frame_rate;
        [CCode (type = "uint8_t")]
        public bool content_exist_3D;
        [CCode (cname = "initial_output_mode_preference", type = "uint8_t")]
        public bool prefer_3D;
        public uint8 provider_data[32];

        [CCode (array_length_cname = "num_titles", array_length_type = "uint32_t")]
        public Title[] titles;
        public unowned Title first_play;
        public unowned Title top_menu;

        public string? bdj_org_id;
        public string? bdj_disc_id;

        public string? udf_volume_id;
    }

    [CCode (cname = "BLURAY", lower_case_cprefix = "bd_", free_function = "bd_close")]
    [Compact]
    public class Disc {
        public uint get_current_angle ();
        public uint32 get_current_title ();
        public uint64 get_title_size ();
        public uint32 get_main_title ();
        public TitleInfo? get_title_info (uint32 title_index, uint angle);

        public uint32 get_titles (
            TitleFlags flags,
            uint32 min_title_length = 0
        );

        public TitleInfo[] get_title_list (
            TitleFlags flags,
            uint32 min_title_length = 0
        ) {
            var length = get_titles (flags, min_title_length);
            var ret = new TitleInfo[length];

            for (var i = 0; i < ret.length; i++)
                ret[i] = (!) get_title_info (i, 0);

            return (owned) ret;
        }

        public bool select_title (uint32 title_index);
        public uint64 tell ();
        public uint64 tell_time ();
        public bool get_event (out Event event);
        public int64 seek (uint64 pos);
        public int64 seek_time (uint64 pos);
        public int read (uint8[] buf);
        [CCode (cname = "bd_open_disc")]
        public bool open (string device_path, string? keyfile_path);
        [CCode (cname = "bd_get_disc_info")]
        public unowned DiscInfo? get_info ();
        [DestroysInstance]
        public void close ();
        [CCode (cname = "bd_init")]
        public Disc ();
    }

    [CCode (cheader_filename = "libbluray/log_control.h")]
    public void set_debug_mask (uint32 mask);
}
