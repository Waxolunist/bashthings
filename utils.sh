#!/bin/bash

TIMEFORMAT=%R

tmpFile=$(mktemp) 
echo "NR,TIME (s),TIME sub (s),CMD" >> "$tmpFile"
counter=0

trap cleanStat SIGTERM SIGHUP SIGINT EXIT

cleanStat() {
    echo "-----,-----,-----,-----" >> "$tmpFile"
    awk -F"," '{print;x+=$2}END{print "Total," x ",,"}' "${tmpFile}" | tail -n 1 >> "$tmpFile"
    printTable ',' "$(cat "${tmpFile}")"
    counter=0
    rm "${tmpFile}"
}

# piping from https://stackoverflow.com/a/963857/534858
stat() {
    local realtime="0"
    local starttime="0"
    local endtime="0"
    local isSubProcess

    if [ "$1" == "-s" ]; then
        isSubProcess=true
        shift
    fi
    #exec 3>&1 4>&2
    #realtime=$( { time "$@" 2>&4 1>&3; } 2>&1 )
    #exec 3>&- 4>&-
    starttime="$(date +%s)"
    "$@"
    endtime=$(date +%s)
    ((counter=counter+1))
    ((realtime=endtime-starttime))
    if [ $isSubProcess ]; then
        echo "${counter},,${realtime},\"$*\"" >> "$tmpFile"
    else
        echo "${counter},${realtime},,\"$*\"" >> "$tmpFile"
    fi
}

trim() {
    local trimmed="$1"
    echo "$trimmed" | xargs
}

#### Copied from https://github.com/gdbtek/linux-cookbooks/blob/master/libraries/util.bash
removeEmptyLines() {
    local -r content="${1}"

    echo -e "${content}" | sed '/^\s*$/d'
}

isPositiveInteger() {
    local -r string="${1}"

    if [[ "${string}" =~ ^[1-9][0-9]*$ ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

repeatString() {
    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "$(isPositiveInteger "${numberToRepeat}")" = 'true' ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

isEmptyString() {
    local -r string="${1}"

    if [[ "$(trim "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

printTable() {
    local -r delimiter="${1}"
    local -r tableData="$(removeEmptyLines "${2}")"
    local -r colorHeader="${3}"
    local -r displayTotalCount="${4}"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${tableData}")" = 'false' ]]
    then
        local -r numberOfLines="$(trim "$(wc -l <<< "${tableData}")")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${tableData}")"

                local numberOfColumns=0
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                # Add Header Or Body

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#|  %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                local output=''
                output="$(echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1')"

                if [[ "${colorHeader}" = 'true' ]]
                then
                    echo -e "\033[1;32m$(head -n 3 <<< "${output}")\033[0m"
                    tail -n +4 <<< "${output}"
                else
                    echo "${output}"
                fi
            fi
        fi

        if [[ "${displayTotalCount}" = 'true' && "${numberOfLines}" -ge '0' ]]
        then
            echo -e "\n\033[1;36mTOTAL ROWS : $((numberOfLines - 1))\033[0m"
        fi
    fi
}