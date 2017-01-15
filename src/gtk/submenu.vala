[GtkTemplate (ui = "/so/bob131/Videos/gtk/submenu.ui")]
class Submenu : Gtk.Box {
    public string title {set; get;}

    internal Gee.HashMap<Gtk.Widget, bool> permanent_map =
        new Gee.HashMap<Gtk.Widget, bool> ();

    public override void set_child_property (
        Gtk.Widget child,
        uint property_id,
        Value @value,
        ParamSpec pspec
    )
        requires (property_id == 1)
        requires (@value.type () == typeof (bool))
        requires (pspec.value_type == typeof (bool))
    {
        permanent_map[child] = @value.get_boolean ();
    }

    public override void get_child_property (
        Gtk.Widget child,
        uint property_id,
        Value @value,
        ParamSpec pspec
    )
        requires (property_id == 1)
        requires (@value.type () == typeof (bool))
        requires (pspec.value_type == typeof (bool))
    {
        @value.set_boolean (
            permanent_map.has_key (child) ?
                permanent_map[child]
                : ((!) pspec.get_default_value ()).get_boolean ()
        );
    }

    static construct {
        var perm_param = new ParamSpecBoolean ("permanent", "Permanent",
            "Specifies whether widget is a permanent member of this", false,
            ParamFlags.READWRITE);
        install_child_properties ({(ParamSpec) null, perm_param});
    }
}

class RadioSubmenu : Submenu {
    public Gtk.ModelButton selected_child {set; get;}

    new Gee.HashMap<string, Gtk.ModelButton> map =
        new Gee.HashMap<string, Gtk.ModelButton> ();

    public signal void child_activated (string name);

    public bool contains (Gtk.Widget widget) {
        return map.has_key (widget.name);
    }

    public void update (Gtk.ModelButton[] buttons) {
        var new_map = new Gee.HashMap<string, Gtk.ModelButton> ();

        foreach (var button in buttons)
            new_map[button.name] = button;

        var buttons_to_remove = map.filter (
            (e) => !new_map.has_key (e.key) && !permanent_map[e.@value]);

        while (buttons_to_remove.next ())
            remove (buttons_to_remove.@get ().@value);

        foreach (var new_button in buttons)
            if (new_button in this)
                map[new_button.name].text = new_button.text;
            else
                add (new_button);
    }

    public override void add (Gtk.Widget button) {
        return_if_fail (button is Gtk.ModelButton);

        if (button in this)
            return;

        map[button.name] = (Gtk.ModelButton) button;
        ((Gtk.Button) button).clicked.connect (
            () => child_activated (button.name));
        base.add (button);
    }

    public override void remove (Gtk.Widget button) {
        base.remove (button);
        map.unset (button.name);
    }

    public void select_child_by_name (string name)
        requires (map.has_key (name))
    {
        selected_child = map[name];
    }

    construct {
        this.notify["selected-child"].connect (() =>
            map.@foreach ((entry) => {
                entry.@value.active = entry.key == selected_child.name;
                return true;
            })
        );
    }
}
