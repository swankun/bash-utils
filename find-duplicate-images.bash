#!/usr/bin/env bash

# Default values
DIFF_THRESHOLD=0.4
NJOBS=4

get_diff_metric() {
    declare -a diff_metric
    magick_out=($(
        magick compare -metric PAE \
        $1 \
        $2 \
        /dev/null \
        2>&1 > /dev/null
    ))
    diff_metric="${magick_out[1]}"
    diff_metric="${diff_metric#*(}" # Strip ( parentheses
    diff_metric="${diff_metric%)*}" # Strip ) parentheses
    echo "${diff_metric}"
}

identify_duplicate() {
    if [[ "$(get_diff_metric $1 $2)" < $DIFF_THRESHOLD ]]; then
        echo "$2"
    fi
}

find_all_duplicates() {
    input_list=("$@")
    num_images="${#input_list[@]}"
    for ((count=0; count<$num_images-1; count++)); do
        ((i=i%NJOBS)); ((i++==0)) && wait
        {
            local next_count
            (( next_count = count+1 ))
            # echo "${input_list[$count]}" "${input_list[$next_count]}"
            identify_duplicate "${input_list[$count]}" "${input_list[$next_count]}"
        } &
    done
    wait
}

help() {
    echo "USAGE: ${0} File1 File2 [FileN]..."
    echo ""
    echo "OPTIONS"
    printf "\n%10s, %-20s %s" \
        "-h" "--help" \
        "Print this message and exit."
    printf "\n%10s, %-20s %s" \
        "-j [N]" "--jobs[=N]" \
        "Allow N jobs at once; Default is N=4."
    printf "\n%10s, %-20s %s" \
        "-t [V]" "--threshold[=V]" \
        "Difference threshold for images to be considered different.Default is V=0.4"
    exit 2
}


SHORTOPTS=h,j:,t:
LONGOPTS=help,jobs:,threshold:
OPTS=$(getopt -a -n "find-duplicate-images" --options $SHORTOPTS --longoptions $LONGOPTS -- "$@")
[ $? -ne 0 ] && help
eval set -- "$OPTS"
while : 
do
    case "$1" in
        "-h" | "--help" ) # display help
            help
            ;;
        "-j" | "--jobs" ) # set number of jobs
            NJOBS="$2"
            shift 2
            ;;
        "-t" | "--threshold" ) # set number of jobs
            DIFF_THRESHOLD="$2"
            shift 2
            ;;
        -- )
            shift;
            break
            ;;
        *)
            echo "Unexpected option: $1"
            help
            ;;
   esac
done

[ $# -lt 2 ] && help
find_all_duplicates "$@"
# to_remove=($(find_all_duplicates))
# for file in "${to_remove[@]}"; do
#     rm "${file%.color.png}"*
# done

