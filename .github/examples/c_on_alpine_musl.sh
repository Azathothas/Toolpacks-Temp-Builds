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
    #coreutils : GNU CoreUtils
     export BIN="coreutils" #Name of final binary/pkg/cli, sometimes differs from $REPO
     export SOURCE_URL="https://github.com/coreutils/coreutils" #github/gitlab/homepage/etc for $BIN
     echo -e "\n\n [+] (Building | Fetching) $BIN :: $SOURCE_URL\n"
     #-------------------------------------------------------#    
      ##Build (MUSL) 
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       docker stop "alpine-builder" 2>/dev/null ; docker rm "alpine-builder" 2>/dev/null
       docker run --privileged --net="host" --name "alpine-builder" "azathothas/alpine-builder:latest" \
        bash -c '
        #Get SRC
         mkdir -p "/build-bins" && pushd "$(mktemp -d)" >/dev/null 2>&1
         #curl -qfsSLJO "https://ftp.gnu.org/gnu/coreutils/$(curl -qfsSL "https://ftp.gnu.org/gnu/coreutils/" | grep -oP "(?<=href=\")[^\"]+\.tar\.xz(?=\")" | sort -V | tail -n 1)"
         #find "./" -type f -iname "*tar.xz" -exec tar -xvf {} \; && find "./" -type f -iname "*tar.xz" -exec rm -rf {} \;
         #cd $(find . -maxdepth 1 -type d | grep -v "^.$")
         git clone --filter="blob:none" "https://github.com/coreutils/coreutils" && cd "./coreutils"
        #Configure
         export CFLAGS="-O2 -flto=auto -static -w -pipe ${CFLAGS}"
         export CXXFLAGS="${CFLAGS}"
         export CPPFLAGS="${CFLAGS}"
         export LDFLAGS="-static -s -Wl,-S -Wl,--build-id=none ${LDFLAGS}"
         export FORCE_UNSAFE_CONFIGURE="1"
         ulimit -n unlimited
        #Build
         make dist clean 2>/dev/null ; make clean 2>/dev/null
         "./configure" --enable-single-binary --disable-shared --enable-static
         #https://github.com/moby/moby/issues/13451
         if [ -d "./confdir3/confdir3" ]; then
             ulimit -n unlimited 2>/dev/null
             timeout -k 05 05 apk del busybox 2>/dev/null
             while [[ -e "./confdir3/confdir3" ]]; do mv "./confdir3/confdir3" "./confdir3a"; rmdir "./confdir3"; mv "./confdir3a" "./confdir3"; done; rmdir "./confdir3"
             "./configure" --disable-shared --enable-static
         fi
         "./configure" --enable-single-binary --disable-shared --enable-static
         make --jobs="$(($(nproc)+1))" --keep-going
         find "./src" -type f -executable -exec cp {} "/build-bins/" \;
        #Build Single Applets
         make dist clean 2>/dev/null ; make clean 2>/dev/null
         "./configure" --disable-shared --enable-static
         #https://github.com/moby/moby/issues/13451
         if [ -d "./confdir3/confdir3" ]; then
             ulimit -n unlimited 2>/dev/null
             timeout -k 05 05 apk del busybox 2>/dev/null
             while [[ -e "./confdir3/confdir3" ]]; do mv "./confdir3/confdir3" "./confdir3a"; rmdir "./confdir3"; mv "./confdir3a" "./confdir3"; done; rmdir "./confdir3"
             "./configure" --disable-shared --enable-static
         fi
         "./configure" --disable-shared --enable-static
         make --jobs="$(($(nproc)+1))" --keep-going
         find "./src" -type f -executable -exec cp {} "/build-bins/" \;
         popd >/dev/null 2>&1
        '
       #Copy 
       docker cp "alpine-builder:/build-bins/." "$(pwd)/"
       find "./" -type d -exec rm -rf {} + 2>/dev/null
       find "./" -type f -exec sh -c 'file "{}" | grep -q "text" && rm -f "{}"' \;
       mkdir -p "$BASEUTILSDIR/coreutils"
       [ "$(find ./ -mindepth 1 -maxdepth 1)" ] && sudo rsync -av --copy-links "./." "$BASEUTILSDIR/coreutils"
       sudo chown -R "$(whoami):$(whoami)" "$BASEUTILSDIR/coreutils/" && chmod -R 755 "$BASEUTILSDIR/coreutils/"
       #Strip
       find "$BASEUTILSDIR/coreutils" -type f ! -name "*.AppImage" -exec strip --strip-debug --strip-dwo --strip-unneeded --preserve-dates "{}" \; 2>/dev/null       
      #-------------------------------------------------------#       
      ##Meta
       file "$BASEUTILSDIR/coreutils/"*
       unset TMP_METADIR B3SUM DESCRIPTION EXTRA_BINS REPO_URL SHA256 WEB_URL
       docker stop "alpine-builder" 2>/dev/null ; docker rm "alpine-builder"
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
