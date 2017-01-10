class Preferences : Object {
    static Settings _settings;

    public Settings settings {
        get {
            return _settings;
        }
    }

    public SettingsSchema schema {
        owned get {
            return settings.settings_schema;
        }
    }

    /* public new Value @get (string key) { */
    /*     return DBus.gvariant_to_gvalue (settings.get_value (key)); */
    /* } */

    /* public new void @set (string key, Value @value) { */
    /*     warn_if_fail (settings.set_value (key, DBus.gvalue_to_gvariant ( */
    /*         @value, schema.get_key (key).get_value_type ()))); */
    /* } */

    static construct {
        _settings = new Settings ("so.bob131.Videos");
    }
}
