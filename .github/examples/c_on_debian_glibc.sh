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
    #coreutils : GNU CoreUtils (GLIBC)
     export BIN="coreutils"
     export SOURCE_URL="https://github.com/coreutils/coreutils"
     echo -e "\n\n [+] (Building | Fetching) $BIN :: $SOURCE_URL\n"
     #-------------------------------------------------------#    
      ##Build: (GLIBC)
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       docker stop "debian-builder-unstable" 2>/dev/null ; docker rm "debian-builder-unstable" 2>/dev/null
       docker run --privileged --net="host" --name "debian-builder-unstable" "azathothas/debian-builder-unstable:latest" \
        bash -c '
        #Setup ENV
         mkdir -p "/build-bins"
         sudo apt update -y -qq
         sudo apt install autopoint bison gettext gperf libacl1 libacl1-dev libcap-dev -y -qq
        #Build
         pushd "$(mktemp -d)" >/dev/null 2>&1 && git clone --filter="blob:none" "https://github.com/coreutils/coreutils" && cd "./coreutils"
         export CFLAGS="-Os -ffunction-sections -fdata-sections -flto=auto -static -w -pipe"
         export CXXFLAGS="${CFLAGS}"
         export CPPFLAGS="${CFLAGS}"
         export LDFLAGS="-static -s -Wl,-S -Wl,--build-id=none -Wl,--gc-sections"
         export FORCE_UNSAFE_CONFIGURE="1"
         bash "./bootstrap"
        #Single Applets
         make dist clean 2>/dev/null ; make clean 2>/dev/null
         "./configure" --disable-shared --enable-static
         #https://github.com/moby/moby/issues/13451
         if [ -d "./confdir3/confdir3" ]; then
             ulimit -n unlimited 2>/dev/null
             while [[ -e "./confdir3/confdir3" ]]; do mv "./confdir3/confdir3" "./confdir3a"; rmdir "./confdir3"; mv "./confdir3a" "./confdir3"; done; rmdir "./confdir3"
             "./configure" --disable-shared --enable-static
         fi
         make --jobs="$(($(nproc)+1))" --keep-going
         find "./src" -maxdepth 1 -type f -exec file -i "{}" \; | grep "application/.*executable" | cut -d":" -f1 | xargs realpath | xargs -I {} rsync -av --copy-links {} "/build-bins/"
        #Multicall
         make dist clean 2>/dev/null ; make clean 2>/dev/null
        "./configure" --disable-shared --enable-static --enable-single-binary
         #https://github.com/moby/moby/issues/13451
         if [ -d "./confdir3/confdir3" ]; then
             ulimit -n unlimited 2>/dev/null
             while [[ -e "./confdir3/confdir3" ]]; do mv "./confdir3/confdir3" "./confdir3a"; rmdir "./confdir3"; mv "./confdir3a" "./confdir3"; done; rmdir "./confdir3"
             "./configure" --disable-shared --enable-static --enable-single-binary
         fi
         make --jobs="$(($(nproc)+1))" --keep-going
         find "./src" -maxdepth 1 -type f -exec file -i "{}" \; | grep "application/.*executable" | cut -d":" -f1 | xargs realpath | xargs -I {} rsync -av --copy-links {} "/build-bins/"
         popd >/dev/null 2>&1
        '
      #Copy & Meta
       mkdir -p "$BASEUTILSDIR/coreutils"
       docker cp "debian-builder-unstable:/build-bins/." "$(pwd)/"
       find "./" -type d -exec rm -rf {} + 2>/dev/null
       find "./" -type f -exec sh -c 'file "{}" | grep -q "text" && rm -f "{}"' \;
       find "." -maxdepth 1 -type f -exec file -i "{}" \; | grep "application/.*executable" | cut -d":" -f1 | xargs realpath
       #Meta
       find "." -maxdepth 1 -type f -exec sh -c 'file "{}"; du -sh "{}"' \;
       sudo rsync -av --copy-links --exclude="*/" "./." "$BASEUTILSDIR/coreutils/"
      #Strip 
       find "$BASEUTILSDIR/coreutils" -type f -exec objcopy --remove-section=".comment" --remove-section=".note.*" "{}" \;
       find "$BASEUTILSDIR/coreutils" -type f ! -name "*.AppImage" -exec strip --strip-debug --strip-dwo --strip-unneeded --preserve-dates "{}" \; 2>/dev/null
      #-------------------------------------------------------#
      ##Meta
       file "$BASEUTILSDIR/coreutils/"*
       unset TMP_METADIR B3SUM DESCRIPTION EXTRA_BINS REPO_URL SHA256 WEB_URL
       docker stop "debian-builder-unstable" 2>/dev/null ; docker rm "debian-builder-unstable"
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
