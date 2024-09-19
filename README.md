- ### Toolpacks-Temp-Builds
> - This repo is to test build scripts for https://github.com/Azathothas/Toolpacks
> - To get started: [Fork this Repo](https://github.com/Azathothas/Toolpacks-Temp-Builds/fork) `>>` Make changes to the <ins>Releated Build Script</ins> & <ins>Commit</ins> `>>` Run the <ins>Workflow</ins>
> - After the workflow finishes, check the <ins>`Releases`</ins> for Artifacts & Uploaded Binaries.
> > - Examples:
> > > - [C/C++ etc (Alpine MUSL)](https://github.com/Azathothas/Toolpacks-Temp-Builds/blob/main/.github/examples/c_on_alpine_musl.sh) (Works both on `aarch64` & `x86_64`)
> > > - [C/C++ etc (Debian GLIBC)](https://github.com/Azathothas/Toolpacks-Temp-Builds/blob/main/.github/examples/c_on_debian_glibc.sh) (Works both on `aarch64` & `x86_64`)
> > > - [C/C++ etc (Using ppkg aarch64 Alpine MUSL)](https://github.com/Azathothas/Toolpacks/blob/main/.github/scripts/aarch64_Linux/bins/proot.sh)
> > > - [C/C++ etc (Using ppkg x86_64 Alpine MUSL)](https://github.com/Azathothas/Toolpacks/blob/main/.github/scripts/x86_64_Linux/bins/proot.sh)
> > > - [Go (Static-Pie on amd64 Alpine MUSL)](https://github.com/Azathothas/Toolpacks/blob/main/.github/scripts/x86_64_Linux/bins/wush.sh)
> > > - [Go (Static-Pie on arm64 Alpine MUSL)](https://github.com/Azathothas/Toolpacks/blob/main/.github/scripts/aarch64_Linux/bins/wush.sh)
> > > - [Nix (PKGs with single Binaries)](https://github.com/Azathothas/Toolpacks/blob/main/.github/scripts/x86_64_Linux/bins/slirp4netns.sh) (Works both on `aarch64` & `x86_64`)
> > > - [Nix (PKGs with multiple Binaries)](https://github.com/Azathothas/Toolpacks-Temp-Builds/blob/main/.github/examples/nix_multiple_binaries.sh) (Works both on `aarch64` & `x86_64`)
> > > - [PyInstaller (Staticx Debian GLIBC)](https://github.com/Azathothas/Toolpacks/blob/main/.github/scripts/x86_64_Linux/bins/huggingface-cli.sh) (Works both on `aarch64` & `x86_64`)
> > > - [PyInstaller with spec file (Staticx Debian GLIBC)](https://github.com/Azathothas/Toolpacks/blob/main/.github/scripts/x86_64_Linux/bins/netexec.sh) (Works both on `aarch64` & `x86_64`)
> > > - [Rust (Static-Pie on Alpine aarch64-unknown-linux-musl)](https://github.com/Azathothas/Toolpacks/blob/main/.github/scripts/aarch64_Linux/bins/wormhole-rs.sh)
> > > - [Rust (Static-Pie on Alpine x86_64-unknown-linux-musl)](https://github.com/Azathothas/Toolpacks/blob/main/.github/scripts/x86_64_Linux/bins/wormhole-rs.sh)
> > > - [Staticx (x86_64 Alpine MUSL)](https://github.com/Azathothas/Toolpacks/blob/main/.github/scripts/x86_64_Linux/bins/xhost.sh)
> > > - [Staticx (aarch64 Alpine MUSL)](https://github.com/Azathothas/Toolpacks/blob/main/.github/scripts/aarch64_Linux/bins/xhost.sh) 
> - The binaries are usually renamed (`$(uname -m)-$(uname -s)`) & also contain `.upx` versions. They are <ins>never stripped</ins> to [avoid accidental corruption.](https://github.com/Azathothas/Toolpacks/blob/main/Docs/APPIMAGES.md#strip--objcopy) 
> - You can [submit a PR](https://github.com/Azathothas/Toolpacks/compare) if the workflow runs successfully and the Released Binaries are Statically Linked & Work as expected.
> - If the workflow fails, you can inspect the CI logs to check what went wrong. You can also [contact me](https://ajam.dev/contact) if additional help is required.

- #### Under the Hood
> - The worklfow runs the same [containers](https://github.com/Azathothas/Toolpacks/tree/main/.github/runners) that [Toolpacks'](https://github.com/Azathothas/Toolpacks) servers run.
> - This means, it contains the same Build Environment, thus is perfect for testing whether a script runs & builds successfully.
> - You can just copy paste any of the [build scripts](https://github.com/Azathothas/Toolpacks/tree/main/.github/scripts) here and they will 100% run exactly like they do on [Toolpacks'](https://github.com/Azathothas/Toolpacks) servers.
> - If you don't want to use [Github-Actions](https://github.com/Azathothas/Toolpacks-Temp-Builds/actions), You can also do this manually on your machine by following the [Instruction](https://github.com/Azathothas/Toolpacks/tree/main/Docs#how-to-setup--configure-local-build-environment) here: https://github.com/Azathothas/Toolpacks/tree/main/Docs#how-to-setup--configure-local-build-environment

- #### Things that don't work
> - You will have to <ins>comment-out/remove-sections</ins> from the script if they contain reference to <ins>using rclone to upload</ins> to [bin.ajam.dev](https://bin.ajam.dev/)
> - As of now, Github hasn't released their aarch64 runners to the public, so Podman uses QEMU to emulate it. This means build (aarch64) will take much longer & may not work as expected.
