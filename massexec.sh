#!/usr/bin/bash

RED=$'\e[31m'
GREEN=$'\e[32m'
ORANGE=$'\e[33m'
CYAN=$'\e[96m'
RESET=$'\e[0m'
BLINK=$'\e[5m'

error_msg() {
    echo "${RED}error:${RESET} $1" >&2 
    echo "Usage: massexec.sh [--path dirpath] [--mask mask] [--number number] command" >&2
    exit 1
}

dirpath="$PWD"; mask="*"; number=$(nproc)
while (($#)); do
    # echo "1: '$1', 2: '$2'"
    case "$1" in
        --path)
            if (($# < 2)); then error_msg "--path requires directory"; fi
            if [[ -z $2 || ! -d $2 ]]; then error_msg "Passed directory '$2' doesn't exist"; fi
            dirpath=$2; shift 2
        ;;
        --mask)
            if (($# < 2)); then error_msg "--mask requires pattern"; fi
            if [[ -z $2 ]]; then error_msg "Mask must not be empty"; fi
            mask=$2; shift 2
        ;;
        --number)
            if (($# < 2 || $2 <= 0)); then error_msg "--number requires positive integer"; fi
            if (($2 > $number)); then error_msg "Maximum number is $number, passed $2"; fi
            number=$2; shift 2;;
        --*) error_msg "Unknown option: $1";;
        *) if [[ $# > 1 || ! -x $(type -p $1) ]]; then error_msg "Incorrect command: '$*'"; fi; command=$1; break;;
    esac
done

echo "dirpath: $dirpath; mask: $mask; number: $number; command: $command"

files=("$dirpath"/$mask)
# declare -p files
declare -i running=0
pids=()
for f in ${files[@]}; do
    if [[ ! -f $f || -L $f ]]; then continue; fi

    cmd="$command $f"
    $cmd &
    pids["$!"]=$cmd
    running+=1

    # declare -p pids
    echo "${GREEN}$cmd &${RESET} ($!)"

    if ((running >= number)); then
        echo "waiting one of ${!pids[*]}"
        wait -n -p pid_f
        running+=-1
        echo "finished $pid_f (${pids[$pid_f]})"
        unset pids[$pid_f]
    fi
done
wait
