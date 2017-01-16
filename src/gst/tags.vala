class ValueWrapper : Object {
    public Value @value {construct; get;}

    public ValueWrapper (Value @value) {
        Object (@value: @value);
    }
}

class Tags : Object {
    HashTable<string, List<ValueWrapper>> table =
        new HashTable<string, List<ValueWrapper>> (str_hash, str_equal);

    public new unowned Value @get (string tag) {
        return table[tag].data.@value;
    }

    public unowned List<ValueWrapper> get_list (string tag) {
        return table[tag];
    }

    public signal void tag_updated (string name);

    public void add (Gst.TagList tags) {
        tags.foreach ((_, tag) => {
            var list = table.take (tag);

            Value owned_value;
            Gst.Tags.list_copy_value (out owned_value, tags, tag);

            if (list.length () > 0 && Gst.Tags.is_fixed (tag))
                list.data = new ValueWrapper ((owned) owned_value);
            else
                list.prepend (new ValueWrapper ((owned) owned_value));

            table[tag] = (owned) list;
            tag_updated (tag);
        });
    }
}
