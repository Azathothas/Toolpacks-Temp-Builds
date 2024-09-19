#!/usr/bin/env bash

#-------------------------------------------------------#
#Sanity Checks
if [ "$BUILD" != "YES" ] || \
   [ -z "$BINDIR" ] || \
   [ -z "$EGET_EXCLUDE" ] || \
   [ -z "$EGET_TIMEOUT" ] || \
   [ -z "$GIT_TERMINAL_PROMPT" ] || \
   [ -z "$GIT_ASKPASS" ] || \
   [ -z "$GITHUB_TOKEN" ] || \
   [ -z "$SYSTMP" ] || \
   [ -z "$TMPDIRS" ]; then
 #exit
  echo -e "\n[+]Skipping Builds...\n"
  exit 1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Main
SKIP_BUILD="NO" #YES, in case of deleted repos, broken builds etc
if [ "$SKIP_BUILD" == "NO" ]; then
    #s6-dns : A suite of DNS client programs and libraries for Unix systems
     export BIN="s6-dns"
     export SOURCE_URL="https://github.com/skarnet/s6-dns"
     echo -e "\n\n [+] (Building | Fetching) $BIN :: $SOURCE_URL\n"
     #-------------------------------------------------------#
      ##Build (s6-dns)
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       NIXPKGS_ALLOW_BROKEN="1" NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM="1" nix-build '<nixpkgs>' --attr "pkgsStatic.s6-dns" --cores "$(($(nproc)+1))" --max-jobs "$(($(nproc)+1))" --log-format bar-with-logs
       mkdir -p "$BASEUTILSDIR/s6-dns" ; sudo rsync -av --copy-links "./result-bin/bin/." "$BASEUTILSDIR/s6-dns"
       sudo chown -R "$(whoami):$(whoami)" "$BASEUTILSDIR/s6-dns/" && chmod -R 755 "$BASEUTILSDIR/s6-dns/"
       #Strip
       find "$BASEUTILSDIR/s6-dns" -type f ! -name "*.AppImage" -exec strip --strip-debug --strip-dwo --strip-unneeded --preserve-dates "{}" \; 2>/dev/null
       nix-collect-garbage >/dev/null 2>&1 ; popd >/dev/null 2>&1
      #-------------------------------------------------------#
      ##Meta
       file "$BASEUTILSDIR/s6-dns/"*
       unset TMP_METADIR B3SUM DESCRIPTION EXTRA_BINS REPO_URL SHA256 WEB_URL
       find "$BASEUTILSDIR" -type f -size 0 -delete ; popd >/dev/null 2>&1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Cleanup
unset SKIP_BUILD ; export BUILT="YES"
#In case of zig polluted env
unset AR CC CFLAGS CXX CPPFLAGS CXXFLAGS DLLTOOL HOST_CC HOST_CXX LDFLAGS LIBS OBJCOPY RANLIB
#In case of go polluted env
unset GOARCH GOOS CGO_ENABLED CGO_CFLAGS
#PKG Config
unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_SYSTEM_INCLUDE_PATH PKG_CONFIG_SYSTEM_LIBRARY_PATH
#-------------------------------------------------------#
