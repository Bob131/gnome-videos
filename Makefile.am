AM_MAKEFLAGS = --no-print-directory

SUBDIRS	= src data

EXTRA_DIST = autogen.sh

MAINTAINERCLEANFILES = \
	$(GITIGNORE_MAINTAINERCLEANFILES_TOPLEVEL) \
	$(GITIGNORE_MAINTAINERCLEANFILES_MAKEFILE_IN) \
	m4/gsettings.m4 m4/pkg.m4 \
	gnome-videos.spec

-include git.mk
