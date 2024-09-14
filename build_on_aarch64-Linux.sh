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
SKIP_BUILD="NO" #Takes > 1 HR
if [ "$SKIP_BUILD" == "NO" ]; then
    #imagemagick : A software suite to create, edit, compose, or convert bitmap images
     export BIN="imagemagick"
     export SOURCE_URL="https://github.com/ImageMagick/ImageMagick"
     echo -e "\n\n [+] (Building | Fetching) $BIN :: $SOURCE_URL\n"
     #-------------------------------------------------------#
      ##Build:
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       docker stop "alpine-builder" 2>/dev/null ; docker rm "alpine-builder" 2>/dev/null
       docker run --privileged --net="host" --name "alpine-builder" "alpine:latest" \
        sh -c '
        #Setup ENV
         mkdir -p "/build-bins" && cd "$(mktemp -d)" >/dev/null 2>&1
         apk update && apk upgrade --no-interactive 2>/dev/null
        #CoreUtils 
         apk add alpine-base coreutils croc curl file git jq moreutils nano ncdu rsync sudo tar util-linux 7zip --latest --upgrade --no-interactive 2>/dev/null
        #https://github.com/leleliu008/ppkg
        #https://github.com/leleliu008/ppkg-package-manually-build/blob/master/.github/workflows/manually-build-for-linux-musl.yml
         sudo curl -qfsSL "https://raw.githubusercontent.com/leleliu008/ppkg/master/ppkg" -o "/usr/local/bin/ppkg" && sudo chmod a+x "/usr/local/bin/ppkg"
         ppkg setup --syspm ; ppkg setup ; ppkg update
         ppkg formula-repo-add "main-core" "https://github.com/leleliu008/ppkg-formula-repository-official-core" --enable
         ppkg formula-repo-conf "main-core" --url="https://github.com/leleliu008/ppkg-formula-repository-official-core" --enable --pin ; ppkg formula-repo-list
        #Build
         ppkg install "imagemagick" --profile="release" -j "$(($(nproc)+1))" --static
         ppkg tree "imagemagick" --dirsfirst -L 5
        #Copy
         ppkg tree "imagemagick" --dirsfirst -L 1 | grep -o "/.*/.*" 2>/dev/null | tail -n1 | xargs realpath |xargs -I{} sudo rsync -av --copy-links --exclude="*/" "{}/bin/." "/build-bins/."
        '
      #Copy & Meta
       mkdir -p "$BASEUTILSDIR/imagemagick"
       docker cp "alpine-builder:/build-bins/." "$(pwd)/"
       find "." -maxdepth 1 -type f -exec file -i "{}" \; | grep "application/.*executable" | cut -d":" -f1 | xargs realpath
       #Meta
       find "." -maxdepth 1 -type f -exec sh -c 'file "{}"; du -sh "{}"' \;
       sudo rsync -av --copy-links --exclude="*/" "./." "$BASEUTILSDIR/imagemagick/"
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