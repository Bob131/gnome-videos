Videos
===

_Videos_ is a new media player application for the GNOME Desktop leveraging a
bunch of new technologies available in the GNOME ecosystem that are currently
under-utilised by more established applications like [Totem].

_Videos_ aims to fit into the GNOME/GTK application space with a user-friendly
UI, use of modern GTK3 widgets and a similar look-and-feel common to GNOME
appliance applications.

[Totem]: https://wiki.gnome.org/Apps/Videos

---

**Asset licensing**: The lovely initial state graphic was lifted from an [old
mock-up for Totem by Allan Day][totem-mockup]. The contents of that repository
are licensed under [CC BY-SA 3.0], so to make things a little more
straight-forward all the graphics included in this repository are under the same
license.

**About the name**: `gnome-videos` is mostly a working name, to be changed in
the future. The implication of endorsement from/cooperation with the GNOME
Foundation, whist obvious, is unintended.

Drop us a line if you have an idea for a name!

[totem-mockup]: https://github.com/gnome-design-team/gnome-mockups/blob/master/videos/1366-initial-state.png
[CC BY-SA 3.0]: http://creativecommons.org/licenses/by-sa/3.0/

## Known Bugs

_Videos_ uses the new `decodebin3` GStreamer element, currently described in the
documentation as 'experimental'. As of GStreamer 1.10, this element doesn't yet
support decoder fallback. As such, if something like a high-ranking
hardware-accelerated decode element fails, the application too will fail to play
the media even if a working lower-ranked decoder is available.

_Videos_ contains several workarounds to get playback working on Sandy Bridge
and machines with the CrystalHD GStreamer plugin installed, but these are hacks
and there is likely many more machines for which _Videos_ will fail to work as
intended. This should only be temporary, pending fixes to `decodebin3` upstream,
but in the meantime feel free to open a bug/pull request regarding additional
required workarounds.
