#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils curl gnused common-updater-scripts

set -e

jami_dir="$( dirname "${BASH_SOURCE[0]}" )"

# Update src version and hash
version=$(curl -s 'https://dl.jami.net/release/tarballs/?C=M;O=D' | sed -n -E 's/^.*jami_([0-9.a-f]+)\.tar\.gz.*$/\1/p' | head -n 1)
update-source-version jami-libclient "$version" --file=pkgs/applications/networking/instant-messengers/jami/default.nix

src=$(nix-build --no-out-link -A jami-libclient.src)

config_dir="$jami_dir/config"
mkdir -p $config_dir

ffmpeg_rules="${src}/daemon/contrib/src/ffmpeg/rules.mak"

# Update FFmpeg patches
ffmpeg_patches=$(sed -n '/.sum-ffmpeg:/,/HAVE_IOS/p' ${ffmpeg_rules} | sed -n -E 's/.*ffmpeg\/(.*patch).*/\1/p')
echo -e "Patches for FFmpeg:\n${ffmpeg_patches}\n"
echo "${ffmpeg_patches}" > "$config_dir/ffmpeg_patches"

# Update FFmpeg args
ffmpeg_args_common=$(sed -n '/#disable everything/,/#platform specific options/p' ${ffmpeg_rules} | sed -n -E 's/.*(--[0-9a-z=_-]+).*/\1/p')
echo -e "Common args for FFmpeg:\n${ffmpeg_args_common}\n"
echo "${ffmpeg_args_common}" > "$config_dir/ffmpeg_args_common"

ffmpeg_args_linux1=$(sed -n '/ifdef HAVE_LINUX/,/ifdef HAVE_ANDROID/p' ${ffmpeg_rules} | sed -n -E 's/.*(--[0-9a-z=_-]+).*/\1/p')
ffmpeg_args_linux2=$(sed -n '/# Desktop Linux/,/i386 x86_64/p' ${ffmpeg_rules} | sed -n -E 's/.*(--[0-9a-z=_-]+).*/\1/p')
echo -e "Linux args for FFmpeg:\n${ffmpeg_args_linux1}\n${ffmpeg_args_linux2}\n"
echo "${ffmpeg_args_linux1}" > "$config_dir/ffmpeg_args_linux"
echo "${ffmpeg_args_linux2}" >> "$config_dir/ffmpeg_args_linux"

ffmpeg_args_x86=$(sed -n '/i386 x86_64/,/# End Desktop Linux:/p' ${ffmpeg_rules} | sed -n -E 's/.*(--[0-9a-z=_-]+).*/\1/p')
echo -e "x86 args for FFmpeg:\n${ffmpeg_args_x86}\n"
echo "${ffmpeg_args_x86}" > "$config_dir/ffmpeg_args_x86"

# Update pjsip patches
pjsip_patches=$(sed -n '/UNPACK/,/HAVE_ANDROID/p' ${src}/daemon/contrib/src/pjproject/rules.mak | sed -n -E 's/.*pjproject\/(00.*patch).*/\1/p')
echo -e "Patches for pjsip:\n${pjsip_patches}\n"
echo "${pjsip_patches}" > "$config_dir/pjsip_patches"
