bin_PROGRAMS = gnome-videos

BUILT_SOURCES = gresources.c

resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(srcdir) gresources.xml)
gresources.c: gresources.xml $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=$(srcdir) --generate-source $<

gnome_videos_SOURCES = \
	gnome-videos.vala \
	event.vala \
	controller.vala \
	media.vala \
	pipeline.vala \
	gresources.c \
	gtk/window.vala \
	gtk/stage-embed.vala \
	gtk/controls/control-container.vala \
	gtk/controls/play-button.vala \
	gtk/controls/fullscreen-button.vala \
	gtk/controls/seek-bar.vala

gnome_videos_VALAFLAGS = \
	--gresources gresources.xml \
	$(gnome_videos_U_VALAFLAGS)

gnome_videos_CFLAGS = $(gnome_videos_U_CFLAGS) -rdynamic

gnome_videos_LDFLAGS = $(gnome_videos_U_LIBS)

-include $(top_srcdir)/git.mk
