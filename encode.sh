#!/usr/bin/bash

#Set your encode parameters here.
#These default settings may not be the best for quality but are good for getting PGO data.
SVT_AV1AN_COMMAND="--progress 2 --preset 2 --crf 29 --keyint 0 --irefresh-type 1 --film-grain 6 --film-grain-denoise 0 --enable-overlays 1 --scd 0 --tune 2 --chroma-u-dc-qindex-offset -1 --chroma-u-ac-qindex-offset -1 --chroma-v-dc-qindex-offset -1 --chroma-v-ac-qindex-offset -1 --enable-tf 0 --enable-qm 1 --qm-min 5 --qm-max 9"

#Below is not fully needed but it did give a better result having more parameters to use. 
#Can be disabled by setting the variable to "" or removing altogether

SVT_AV1AN_COMMAND_2="--progress 2 --preset 4 --crf 29 --keyint 0 --irefresh-type 1 --enable-overlays 1 --scd 0 --tune 2 --chroma-u-dc-qindex-offset -1 --chroma-u-ac-qindex-offset -1 --chroma-v-dc-qindex-offset -1 --chroma-v-ac-qindex-offset -1 --enable-tf 0 --enable-qm 1 --qm-min 5 --qm-max 9"

SVT_AV1AN_COMMAND_3="--progress 2 --preset 6 --crf 29 --keyint 0 --irefresh-type 1 --enable-overlays 1 --scd 0 --tune 1 --chroma-u-dc-qindex-offset -1 --chroma-u-ac-qindex-offset -1 --chroma-v-dc-qindex-offset -1 --chroma-v-ac-qindex-offset -1 --enable-tf 0 --enable-qm 1 --qm-min 0 --qm-max 15"

SVT_AV1AN_COMMAND_4="--progress 2 --preset 1 --crf 10 --keyint 0 --irefresh-type 1 --enable-overlays 1 --scd 0 --tune 1 --chroma-u-dc-qindex-offset -1 --chroma-u-ac-qindex-offset -1 --chroma-v-dc-qindex-offset -1 --chroma-v-ac-qindex-offset -1 --enable-tf 0 --enable-qm 1 --qm-min 5 --qm-max 9"

SVT_AV1AN_COMMAND_5="--progress 2 --preset 1 --crf 10 --keyint 0 --irefresh-type 1 --film-grain 6 --film-grain-denoise 1 --enable-overlays 1 --scd 0 --tune 2 --chroma-u-dc-qindex-offset -1 --chroma-u-ac-qindex-offset -1 --chroma-v-dc-qindex-offset -1 --chroma-v-ac-qindex-offset -1 --enable-tf 0 --enable-qm 1 --qm-min 0 --qm-max 15"


#color for the script
if ! test "$NO_COLOR"; then
    white="\e[1;37m"
    green="\e[1;32m"
    red="\e[1;31m"
    nc="\e[0m"
fi

if test "$DOWNLOAD_OBJECTIVE_TYPE" == "none"; then
    #Check to see if there's no video files inside video-input
    if test -z "$(ls "$PWD"/video-input/*.{mkv,mp4,y4m} 2> /dev/null)"; then
        echo -e "${red}[ERROR] No video files found inside video-input. Compilation requires at least '1' video inside the folder.${nc}"
        exit 1
    fi
fi

svt_encode() {
shopt -s nullglob
for file in "$PWD"/{video-input,objective-*}/*.{mkv,mp4,y4m}; do
    echo ""
    basename="${file##*/}"
    #Add our new svt-av1 binary to the $PATH because you're unable to tell Av1an what binary to use.
    export PATH="$PWD/$_repo/Bin/Release:$PATH"
    if test "$SVT_AV1AN_COMMAND"; then
        echo -e "${green}Encoding:${nc}${white} $basename${nc} with ${white}SVT_AV1AN_COMMAND${nc}"
        av1an \
        -e svt-av1 \
        --concat mkvmerge \
        --verbose \
        --split-method av-scenechange \
        --sc-method standard \
        --pix-format yuv420p10le \
        --sc-pix-format yuv420p \
        --sc-downscale-height 540 \
        -v " $SVT_AV1AN_COMMAND " \
        -i "$file" \
        -o "$file.1.av1an"

        # shellcheck disable=SC2012
        if ! test "$(ls svt-pgo-data/*.profraw 2>/dev/null | wc -l)" -eq 0; then
            for profraw in svt-pgo-data/*.profraw; do
                basename_profraw="${profraw##*/}"
                mv "$profraw" svt-pgo-data/"$basename_profraw"."$(echo "$RANDOM" | md5sum | head -c 5)".profraw-real
            done
        fi

        #This might not be needed with --instrumentation-file-append-pid
        if test "$BOLT" == "true"; then
            echo -e "${green}Bolt is enabled checking for .fdata file(s)${nc}"
            # shellcheck disable=SC2012
            if ! test "$(ls svt-bolt-data/*.fdata 2>/dev/null | wc -l)" -eq 0; then
                echo -e "${green}Found fdata file in svt-bolt-data${nc}"
                for fdata in svt-bolt-data/*.fdata; do
                    basename_fdata="${fdata##*/}"
                    mv "$fdata" svt-bolt-data/"$basename_fdata"."$(echo "$RANDOM" | md5sum | head -c 5)".fdata-real
                done
            else
                echo -e "${red}No fdata file found in svt-bolt-data${nc}"
            fi
        fi
    fi

    #command 2
    if test "$SVT_AV1AN_COMMAND_2"; then
        echo -e "${green}Encoding:${nc}${white} $basename${nc} with ${white}SVT_AV1AN_COMMAND_2${nc}"
        av1an \
        -e svt-av1 \
        --concat mkvmerge \
        --verbose \
        --split-method av-scenechange \
        --sc-method standard \
        --pix-format yuv420p10le \
        --sc-pix-format yuv420p \
        --sc-downscale-height 540 \
        -v " $SVT_AV1AN_COMMAND_2 " \
        -i "$file" \
        -o "$file.2.av1an"
        
        # shellcheck disable=SC2012
        if ! test "$(ls svt-pgo-data/*.profraw 2>/dev/null | wc -l)" -eq 0; then
            for profraw in svt-pgo-data/*.profraw; do
                basename_profraw="${profraw##*/}"
                mv "$profraw" svt-pgo-data/"$basename_profraw"."$(echo "$RANDOM" | md5sum | head -c 5)".profraw-real
            done
        fi

        #This might not be needed with --instrumentation-file-append-pid
        if test "$BOLT" == "true"; then
            echo -e "${green}Bolt is enabled checking for .fdata file(s)${nc}"
            # shellcheck disable=SC2012
            if ! test "$(ls svt-bolt-data/*.fdata 2>/dev/null | wc -l)" -eq 0; then
                echo -e "${green}Found fdata file in svt-bolt-data${nc}"
                for fdata in svt-bolt-data/*.fdata; do
                    basename_fdata="${fdata##*/}"
                    mv "$fdata" svt-bolt-data/"$basename_fdata"."$(echo "$RANDOM" | md5sum | head -c 5)".fdata-real
                done
            else
                echo -e "${red}No fdata file found in svt-bolt-data${nc}"
            fi
        fi

    fi

    #command 3
    if test "$SVT_AV1AN_COMMAND_3"; then
        echo -e "${green}Encoding:${nc}${white} $basename${nc} with ${white}SVT_AV1AN_COMMAND_3${nc}"
        av1an \
        -e svt-av1 \
        --concat mkvmerge \
        --verbose \
        --split-method av-scenechange \
        --sc-method standard \
        --pix-format yuv420p10le \
        --sc-pix-format yuv420p \
        --sc-downscale-height 540 \
        -v " $SVT_AV1AN_COMMAND_3 " \
        -i "$file" \
        -o "$file.3.av1an"

        # shellcheck disable=SC2012
        if ! test "$(ls svt-pgo-data/*.profraw 2>/dev/null | wc -l)" -eq 0; then
            for profraw in svt-pgo-data/*.profraw; do
                basename_profraw="${profraw##*/}"
                mv "$profraw" svt-pgo-data/"$basename_profraw"."$(echo "$RANDOM" | md5sum | head -c 5)".profraw-real
            done
        fi

        #This might not be needed with --instrumentation-file-append-pid
        if test "$BOLT" == "true"; then
            echo -e "${green}Bolt is enabled checking for .fdata file(s)${nc}"
            # shellcheck disable=SC2012
            if ! test "$(ls svt-bolt-data/*.fdata 2>/dev/null | wc -l)" -eq 0; then
                echo -e "${green}Found fdata file in svt-bolt-data${nc}"
                for fdata in svt-bolt-data/*.fdata; do
                    basename_fdata="${fdata##*/}"
                    mv "$fdata" svt-bolt-data/"$basename_fdata"."$(echo "$RANDOM" | md5sum | head -c 5)".fdata-real
                done
            else
                echo -e "${red}No fdata file found in svt-bolt-data${nc}"
            fi
        fi

    fi

    #command 4
    if test "$SVT_AV1AN_COMMAND_4"; then
        echo -e "${green}Encoding:${nc}${white} $basename${nc} with ${white}SVT_AV1AN_COMMAND_4${nc}"
        av1an \
        -e svt-av1 \
        --concat mkvmerge \
        --verbose \
        --split-method av-scenechange \
        --sc-method standard \
        --pix-format yuv420p10le \
        --sc-pix-format yuv420p \
        --sc-downscale-height 540 \
        -v " $SVT_AV1AN_COMMAND_4 " \
        -i "$file" \
        -o "$file.4.av1an"

        # shellcheck disable=SC2012
        if ! test "$(ls svt-pgo-data/*.profraw 2>/dev/null | wc -l)" -eq 0; then
            for profraw in svt-pgo-data/*.profraw; do
                basename_profraw="${profraw##*/}"
                mv "$profraw" svt-pgo-data/"$basename_profraw"."$(echo "$RANDOM" | md5sum | head -c 5)".profraw-real
            done
        fi

        #This might not be needed with --instrumentation-file-append-pid
        if test "$BOLT" == "true"; then
            echo -e "${green}Bolt is enabled checking for .fdata file(s)${nc}"
            # shellcheck disable=SC2012
            if ! test "$(ls svt-bolt-data/*.fdata 2>/dev/null | wc -l)" -eq 0; then
                echo -e "${green}Found fdata file in svt-bolt-data${nc}"
                for fdata in svt-bolt-data/*.fdata; do
                    basename_fdata="${fdata##*/}"
                    mv "$fdata" svt-bolt-data/"$basename_fdata"."$(echo "$RANDOM" | md5sum | head -c 5)".fdata-real
                done
            else
                echo -e "${red}No fdata file found in svt-bolt-data${nc}"
            fi
        fi

    fi

    #command 5
    if test "$SVT_AV1AN_COMMAND_5"; then
        echo -e "${green}Encoding:${nc}${white} $basename${nc} with ${white}SVT_AV1AN_COMMAND_5${nc}"
        av1an \
        -e svt-av1 \
        --concat mkvmerge \
        --verbose \
        --split-method av-scenechange \
        --sc-method standard \
        --pix-format yuv420p10le \
        --sc-pix-format yuv420p \
        --sc-downscale-height 540 \
        -v " $SVT_AV1AN_COMMAND_5 " \
        -i "$file" \
        -o "$file.5.av1an"

        # shellcheck disable=SC2012
        if ! test "$(ls svt-pgo-data/*.profraw 2>/dev/null | wc -l)" -eq 0; then
            for profraw in svt-pgo-data/*.profraw; do
                basename_profraw="${profraw##*/}"
                mv "$profraw" svt-pgo-data/"$basename_profraw"."$(echo "$RANDOM" | md5sum | head -c 5)".profraw-real
            done
        fi

        #This might not be needed with --instrumentation-file-append-pid
        if test "$BOLT" == "true"; then
            echo -e "${green}Bolt is enabled checking for .fdata file(s)${nc}"
            # shellcheck disable=SC2012
            if ! test "$(ls svt-bolt-data/*.fdata 2>/dev/null | wc -l)" -eq 0; then
                echo -e "${green}Found fdata file in svt-bolt-data${nc}"
                for fdata in svt-bolt-data/*.fdata; do
                    basename_fdata="${fdata##*/}"
                    mv "$fdata" svt-bolt-data/"$basename_fdata"."$(echo "$RANDOM" | md5sum | head -c 5)".fdata-real
                done
            else
                echo -e "${red}No fdata file found in svt-bolt-data${nc}"
            fi
        fi

    fi
done

exit 0
}

svt_encode
