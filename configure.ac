AC_INIT([gnome-videos], [0.2.1])

AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AC_CANONICAL_SYSTEM

AM_INIT_AUTOMAKE([foreign subdir-objects])
AM_SILENT_RULES([yes])

VALA_REQUIRED=0.33.1
AC_SUBST([VALA_REQUIRED], [$VALA_REQUIRED])

AM_PROG_VALAC([$VALA_REQUIRED])

AM_PROG_CC_C_O

CFLAGS="$CFLAGS -w"

AM_CONDITIONAL([CPU_x86], [test "$host_cpu" = "x86_64"])

dnl ###########################################################################
dnl Dependencies
dnl ###########################################################################

GLIB_REQUIRED=2.40.0
GTK_REQUIRED=3.22

AC_SUBST([GTK_REQUIRED], [$GTK_REQUIRED])

PKG_CHECK_MODULES(gnome_videos_U, [
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED
  gtk+-3.0 >= $GTK_REQUIRED
  clutter-gtk-1.0
  clutter-gst-3.0
  gstreamer-tag-1.0
  gstreamer-app-1.0
])

if test "$host_cpu" = "x86_64"; then
  PKG_CHECK_MODULES(va_libs_U, [
    libva-wayland
    libva-x11
  ])
fi

AC_CHECK_HEADER(
  [libcrystalhd/libcrystalhd_if.h],
  [],
  [AC_MSG_ERROR([CrystalHD headers required])]
)
AC_CHECK_LIB(
  [crystalhd], [DtsDeviceOpen],
  [],
  [AC_MSG_ERROR([libcrystalhd not found])]
)

AC_SUBST([gnome_videos_U_VALAFLAGS], ["--pkg gio-2.0 \
          --pkg gtk+-3.0 \
          --pkg clutter-gtk-1.0 \
          --pkg clutter-gst-3.0 \
          --pkg gstreamer-tag-1.0 \
          --pkg gstreamer-app-1.0 \
          --target-glib=$GLIB_REQUIRED \
          --fatal-warnings \
          --enable-checking \
          --enable-experimental \
          --enable-experimental-non-null"])

AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)

GLIB_GSETTINGS

dnl ###########################################################################
dnl Files to generate
dnl ###########################################################################

AC_CONFIG_FILES([
Makefile
gnome-videos.spec
src/Makefile
data/Makefile
data/so.bob131.Videos.desktop
])
AC_OUTPUT
