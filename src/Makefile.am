bin_PROGRAMS = gnome-videos

BUILT_SOURCES = gtk/about.ui gresources.c

gtk/about.ui: gtk/about.ui.in
	$(AM_V_GEN) sed "s/[@]VERSION[@]/$(VERSION)/" < $< > $@

resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(srcdir) gresources.xml)
gresources.c: gresources.xml $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=$(srcdir) --generate-source $<

gnome_videos_SOURCES = \
	gnome-videos.vala \
	bus.vala \
	controller.vala \
	media.vala \
	preferences.vala \
	gresources.c \
	devices/device.vala \
	devices/uri.vala \
	gst/event.vala \
	gst/gst-redefs.vapi \
	gst/nanoseconds.vala \
	gst/pipeline.vala \
	gst/sub-overlay-converter.vala \
	gst/tags.vala \
	gtk/window.vala \
	gtk/prefs.vala \
	gtk/about.vala \
	gtk/shortcut-window.vala \
	gtk/stage-embed.vala \
	gtk/submenu.vala \
	gtk/stream-manager.vala \
	gtk/controls/control-container.vala \
	gtk/controls/play-button.vala \
	gtk/controls/fullscreen-button.vala \
	gtk/controls/seek-bar.vala \
	bcmdec-workaround/crystalhd.vapi \
	bcmdec-workaround/bcmdec-workaround.vala

gnome_videos_VALAFLAGS = \
	--gresources gresources.xml \
	$(gnome_videos_U_VALAFLAGS)

gnome_videos_CFLAGS = $(gnome_videos_U_CFLAGS) -rdynamic

gnome_videos_LDFLAGS = $(gnome_videos_U_LIBS) -lcrystalhd

if CPU_x86
gnome_videos_SOURCES += \
	vaapi-workaround/cpuid.vapi \
	vaapi-workaround/vaapi.vapi \
	vaapi-workaround/wayland.vapi \
	vaapi-workaround/brand-string.c \
	vaapi-workaround/vaapi-workaround.vala \
	vaapi-workaround/vaapidecodebin.vala

gnome_videos_VALAFLAGS += \
	-D CPU_x86 \
	--pkg x11

gnome_videos_CFLAGS += $(va_libs_U_CFLAGS)

gnome_videos_LDFLAGS += $(va_libs_U_LIBS)
endif

-include $(top_srcdir)/git.mk
