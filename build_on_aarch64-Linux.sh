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
export SKIP_BUILD="NO" #YES, in case of deleted repos, broken builds etc
if [ "$SKIP_BUILD" == "NO" ]; then
    #simplex-chat : SimpleX Chat terminal (console) app
     export BIN="simplex-chat"
     export SOURCE_URL="https://github.com/simplex-chat/simplex-chat"
     echo -e "\n\n [+] (Building | Fetching) $BIN :: $SOURCE_URL\n"
      ##Build:
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       docker stop "alpine-builder" 2>/dev/null ; docker rm "alpine-builder" 2>/dev/null
       docker run --privileged --net="host" --name "alpine-builder" "alpine:latest" \
        sh -c '
        #Setup ENV
         mkdir -p "/build-bins" && cd "$(mktemp -d)" >/dev/null 2>&1
         apk update && apk upgrade --no-interactive 2>/dev/null
        #CoreUtils 
         apk add autoconf binutils build-base clang clang-static cmake coreutils croc curl elfutils file gawk gcc gettext git iputils jq linux-tools make mold moreutils musl musl-dev musl-utils nano ncdu perl pkgconfig procps python3 rsync sudo tar util-linux xz zig zstd 7zip --no-interactive 2>/dev/null
        #https://github.com/leleliu008/ppkg
        #https://github.com/leleliu008/ppkg-package-manually-build/blob/master/.github/workflows/manually-build-for-linux-musl.yml
         sudo curl -qfsSL "https://raw.githubusercontent.com/leleliu008/ppkg/master/ppkg" -o "/usr/local/bin/ppkg" && sudo chmod a+x "/usr/local/bin/ppkg"
         ppkg setup --syspm ; ppkg setup ; ppkg update
         ppkg formula-repo-add "main-core" "https://github.com/leleliu008/ppkg-formula-repository-official-core" --enable
         ppkg formula-repo-conf "main-core" --url="https://github.com/leleliu008/ppkg-formula-repository-official-core" --enable --pin ; ppkg formula-repo-list 
        #Build
         ppkg install "simplex-chat" --profile="release" -j "$(($(nproc)+1))" --static
         ppkg tree "simplex-chat" --dirsfirst -L 5
        #Copy
         ppkg tree "simplex-chat" --dirsfirst -L 1 | grep -o "/.*/.*" 2>/dev/null | tail -n1 | xargs realpath |xargs -I{} sudo rsync -av --copy-links --exclude="*/" "{}/bin/." "/build-bins/."
         popd >/dev/null 2>&1
        '
      #Copy & Meta
       docker cp "alpine-builder:/build-bins/." "$(pwd)/"
       find "." -maxdepth 1 -type f -exec file -i "{}" \; | grep "application/.*executable" | cut -d":" -f1 | xargs realpath
       #Meta
       find "." -maxdepth 1 -type f -exec sh -c 'file "{}"; du -sh "{}"' \;
       sudo rsync -av --copy-links --exclude="*/" "./." "$BINDIR"
      #Delete Containers
       docker stop "alpine-builder" 2>/dev/null ; docker rm "alpine-builder"
       popd >/dev/null 2>&1

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
