{ stdenv
, fetchurl
, meson
, nasm
, ninja
, pkgconfig
, python3
, gst-plugins-base
, orc
, bzip2
, gettext
, libv4l
, libdv
, libavc1394
, libiec61883
, libvpx
, speex
, flac
, taglib
, libshout
, cairo
, gdk-pixbuf
, aalib
, libcaca
, libsoup
, libpulseaudio
, libintl
, darwin
, lame
, mpg123
, twolame
, gtkSupport ? false, gtk3 ? null
, enableJack ? true, libjack2
, libXdamage
, libXext
, libXfixes
, ncurses
, wayland
, wayland-protocols
, xorg
, libgudev
, wavpack
}:

assert gtkSupport -> gtk3 != null;

let
  inherit (stdenv.lib) optionals;
in
stdenv.mkDerivation rec {
  pname = "gst-plugins-good";
  version = "1.18.0";

  outputs = [ "out" "dev" ];

  src = fetchurl {
    url = "${meta.homepage}/src/${pname}/${pname}-${version}.tar.xz";
    sha256 = "1b4b3a6fm2wyqpnx300pg1sz01m9qhfajadk3b7sbzisg8vvqab3";
  };

  nativeBuildInputs = [
    pkgconfig
    python3
    meson
    ninja
    gettext
    nasm
  ] ++ optionals stdenv.isLinux [
    wayland-protocols
  ];

  buildInputs = [
    gst-plugins-base
    orc
    bzip2
    libdv
    libvpx
    speex
    flac
    taglib
    cairo
    gdk-pixbuf
    aalib
    libcaca
    libsoup
    libshout
    lame
    mpg123
    twolame
    libintl
    libXdamage
    libXext
    libXfixes
    ncurses
    xorg.libXfixes
    xorg.libXdamage
    wavpack
  ] ++ optionals gtkSupport [
    # for gtksink
    gtk3
  ] ++ optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Cocoa
  ] ++ optionals stdenv.isLinux [
    libv4l
    libpulseaudio
    libavc1394
    libiec61883
    libgudev
    wayland
  ] ++ optionals enableJack [
    libjack2
  ];

  mesonFlags = [
    "-Dexamples=disabled" # requires many dependencies and probably not useful for our users
    "-Ddoc=disabled" # `hotdoc` not packaged in nixpkgs as of writing
    "-Dqt5=disabled" # not clear as of writing how to correctly pass in the required qt5 deps

    # only works on Linux aarch64 and needs a particular header file? doesn't seem to be present in Nixpkgs, so disabled for now
    # see https://gitlab.freedesktop.org/gstreamer/gst-plugins-good/-/blob/428c9b60532917c0ac49c9d48b15bdcd00a1370b/sys/rpicamsrc/meson.build#L10
    "-Drpicamsrc=disabled"
  ] ++ optionals (!gtkSupport) [
    "-Dgtk3=disabled"
  ] ++ optionals (!enableJack) [
    "-Djack=disabled"
  ] ++ optionals (!stdenv.isLinux) [
    "-Ddv1394=disabled" # Linux only
    "-Doss4=disabled" # Linux only
    "-Doss=disabled" # Linux only
    "-Dpulse=disabled" # TODO check if we can keep this enabled
    "-Dv4l2-gudev=disabled" # Linux-only
    "-Dv4l2=disabled" # Linux-only
    "-Dximagesrc=disabled" # Linux-only
    "-Dpulse=disabled" # TODO check if we can keep this enabled
  ];

  postPatch = ''
    patchShebangs \
      scripts/extract-release-date-from-doap-file.py
  '';

  NIX_LDFLAGS = [
    # linking error on Darwin
    # https://github.com/NixOS/nixpkgs/pull/70690#issuecomment-553694896
    "-lncurses"
  ];

  # fails 1 tests with "Unexpected critical/warning: g_object_set_is_valid_property: object class 'GstRtpStorage' has no property named ''"
  doCheck = false;

  meta = with stdenv.lib; {
    description = "GStreamer Good Plugins";
    homepage = "https://gstreamer.freedesktop.org";
    longDescription = ''
      a set of plug-ins that we consider to have good quality code,
      correct functionality, our preferred license (LGPL for the plug-in
      code, LGPL or LGPL-compatible for the supporting library).
    '';
    license = licenses.lgpl2Plus;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [ matthewbauer ];
  };
}
