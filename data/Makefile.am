gsettings_SCHEMAS = settings.gschema.xml
@GSETTINGS_RULES@

icondir = $(datadir)/icons/hicolor
name = so.bob131.Videos

scalabledir = $(icondir)/scalable/apps
scalable_DATA = $(name).svg

symbolicdir = $(icondir)/symbolic/apps
symbolic_DATA = $(name)-symbolic.svg

16pxdir  = $(icondir)/16x16/apps
22pxdir  = $(icondir)/22x22/apps
24pxdir  = $(icondir)/24x24/apps
32pxdir  = $(icondir)/32x32/apps
48pxdir  = $(icondir)/48x48/apps
64pxdir  = $(icondir)/64x64/apps
96pxdir  = $(icondir)/96x96/apps
128pxdir = $(icondir)/128x128/apps
256pxdir = $(icondir)/256x256/apps
16px_DATA  =  16/$(name).png
22px_DATA  =  22/$(name).png
24px_DATA  =  24/$(name).png
32px_DATA  =  32/$(name).png
48px_DATA  =  48/$(name).png
64px_DATA  =  64/$(name).png
96px_DATA  =  96/$(name).png
128px_DATA = 128/$(name).png
256px_DATA = 256/$(name).png

desktopdir = $(datadir)/applications
desktop_DATA = $(name).desktop

BUILT_SOURCES = \
	 16/$(name).png \
	 22/$(name).png \
	 24/$(name).png \
	 32/$(name).png \
	 48/$(name).png \
	 64/$(name).png \
	 96/$(name).png \
	128/$(name).png \
	256/$(name).png \
	so.bob131.Videos.desktop

%/so.bob131.Videos.svg: so.bob131.Videos-lteq-256px.svg generate-icons.py
	$(AM_V_GEN) python3 -B generate-icons.py $< $@

%/so.bob131.Videos.png: %/so.bob131.Videos.svg rasterize-icons.py
	$(AM_V_GEN) ./rasterize-icons.py $< $@

gtk_update_icon_cache = gtk-update-icon-cache -f -t $(icondir)

install-data-hook: update-icon-cache
uninstall-hook: update-icon-cache
update-icon-cache:
	@-if test -z "$(DESTDIR)"; then \
		@echo "Updating GTK icon cache"; \
		$(gtk_update_icon_cache); \
	else \
		echo "*** Icon cache not updated. After (un)install, run this:"; \
		echo "*** $(gtk_update_icon_cache)"; \
	fi

-include $(top_srcdir)/git.mk
