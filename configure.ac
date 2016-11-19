AC_INIT([gnome-videos], [0.0])

AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([foreign subdir-objects])
AM_SILENT_RULES([yes])

AM_PROG_VALAC([0.28])
AM_PROG_CC_C_O

CFLAGS="$CFLAGS -w"

dnl ###########################################################################
dnl Dependencies
dnl ###########################################################################

GLIB_REQUIRED=2.40.0

PKG_CHECK_MODULES(gnome_videos_U, [
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED
])

AC_SUBST([gnome_videos_U_VALAFLAGS], ["--pkg gio-2.0 \
          --target-glib=$GLIB_REQUIRED \
          --fatal-warnings \
          --enable-checking \
          --enable-experimental \
          --enable-experimental-non-null"])

dnl ###########################################################################
dnl Files to generate
dnl ###########################################################################

AC_CONFIG_FILES([
Makefile
src/Makefile
])
AC_OUTPUT
