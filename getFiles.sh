#!/bin/bash
bashPass="\033[32;1mPASSED -"
bashInfo="\033[33;1mINFO -"
bashFail="\033[31;1mFAILED -"
bashEnd="\033[0m"

output=$(getopt -V)
if [[ *"getopt"* == "$output" ]] && [ $# != 0 ]; then
        echo -e "$bashInfo This script cannot parse options from Mac command line's default 'getopt' $bashEnd"
        echo -e "$bashInfo Run \"brew install gnu-getopt\" and then add it to your path using $bashEnd"
        echo -e "$bashInfo export PATH=\"/opt/homebrew/opt/gnu-getopt/bin:\$PATH\" $bashEnd"
        echo -e "$bashInfo At which point you can then use this script with options $bashEnd"
        exit 1;
fi
# Check number of arguments
files=""
file=""
regexPattern="(.(c|h)$)"
if [ $# != 0 ]; then 
    VALID_ARGS=$(getopt --options h --long help, --exclude-dirs::, --exclude-files::, --include-files:: "$0" -- "$@")
    eval set -- "$VALID_ARGS"
    while true ; do
        for arg in "$@"; do
            echo "Argument= $arg"
        done
        case "$1" in
            --exclude-dirs )
                echo -e "$bashInfo Parsed --exclude-dirs as: $2 $bashEnd"
                excludeDirs=$(echo "$2" | tr " " "")
                shift 2
                ;;

            --exclude-files )
                echo -e "$bashInfo Parsed --exclude-files as: $2 $bashEnd"
                excludeFiles=$(echo "$2" | tr " " "")
                shift 2
                ;;

            --include-files )
                echo -e "$bashInfo Parsed --include-files as: $2 $bashEnd"
                includeFiles=$(echo "$2" | tr " " "")
                # By default we do a regex match for any file
                # That ends in a .c or a .h
                regexPattern="(.(c|h)$|("
                # Replace any commas in the includeFiles with a pipe
                regexPattern+=$(echo "$includeFiles" | tr , \|) 
                # Add the end of the regex pattern
                regexPattern+="))"
                shift 2
                ;;

            --help )
                echo "$bashInfo Find all .c and .h files with the Amazon copyright in them $bashEnd"
                echo "$bashInfo It exports this to a bash array variable called \"files\" $bashEnd"
                echo "$bashInfo This script can take in two optional arguments $bashEnd"
                echo "$bashInfo --exclude-files:  A comma seperated list of files to exclude $bashEnd"
                echo "$bashInfo --exclude-dir:    A comma seperated list of directories to exclude $bashEnd"
                echo "$bashInfo --include-files:  Any additional files to search for $bashEnd"
                return 0    
                ;;
            -- )  
                shift
                break
                ;;
            esac
    done
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    grepArgs="-sliE"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    grepArgs="-slie"
fi
# if the host has fd use that
if command -v fd &> /dev/null ; then
    # Use regex to match the pattern
    echo -e "$bashInfo Looking for Files Using Regex: $regexPattern $bashEnd"
    # Exclude any files we were asked to
    # Then perform a grep for the amazon copyright in found files
    echo -e "$bashInfo fd --regex \"$regexPattern\" --exclude \"{$excludeFiles}\" --exclude \"{$excludeDirs}\" -exec grep -slie \"copyright (.*) 20\d\d amazon.com\"\n $bashEnd"
    files=($(fd --regex "$regexPattern" --exclude "{$excludeFiles}" --exclude "{$excludeDirs}" \
                --exec grep $grepArgs "copyright (.*) 20\d\d amazon.com" ))
    return 0
fi
# Adding both OS's here to make it work for local testing on Mac
# So this grep grabs all .c and .h files that have the amazon copyright
# Breaking down the steps:
# --include={*.[ch],$includeFiles,} : Only search for files that end in ".c" and ".h"
# --exclude=${excludeFiles,} : Do not search for files that match the name of any comma-seperated files
# --exclude=${excludeDirs, } : Do not search in any comma-seperated directories
# -l : Return all files found as a list
# -r : Recursively search through all directories
# -i : Do a case insensitive search 
# -e : Use regex for the search

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "$bashInfo Using Grep Search with Command:$bashEnd"
    echo -e "$bashInfo grep --include={*.[ch],$includeFiles,} --exclude={$excludeFiles,} --exclude-dir={$excludeDirs,} -lriE \"copyright (.*) [0-9]{4} amazon.com\"$bashEnd"
    export files=($(grep --include={*.[ch],$includeFiles,} --exclude={$excludeFiles,} --exclude-dir={$excludeDirs,} -lriE "copyright (.*) [0-9]{4} amazon.com" ))
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "$bashInfo Using Grep Search with Command:$bashEnd"
    echo -e "$bashInfo grep '--include='\*{.c,.h,$includeFiles,} '--exclude='{$excludeFiles,} '--exclude-dir='{$excludeDirs,} -rli . -e \"copyright (.*) 20\d\d amazon.com\"$bashEnd"
    # The use of ' characters in the Mac version is to handle globbing
    export files=($(grep '--include='\*{.c,.h,$includeFiles,} '--exclude='{$excludeFiles,} '--exclude-dir='{$excludeDirs,} -rli . -e "copyright (.*) 20\d\d amazon.com"))
    #files=($(grep --include={*.[ch],} --exclude={$excludeFiles,} --exclude-dir={$excludeDirs,} -lriE "copyright (.*) 20\d\d amazon.com" ))
elif [[ "$OSTYPE" == "win32"* ]]; then
    echo -e "$bashInfo Using Grep Search with Command:$bashEnd"
    echo -e "$bashInfo grep --include={*.[ch],$includeFiles,} --exclude={$excludeFiles,} --exclude-dir={$excludeDirs,} -lriE \"copyright (.*) [0-9]{4} amazon.com\"$bashEnd"
    export files=($(grep --include={*.[ch],$includeFiles,} --exclude={$excludeFiles,} --exclude-dir={$excludeDirs,} -lriE "copyright (.*) [0-9]{4} amazon.com" ))
fi

for file in ${files[@]} ; do
    echo "$file"
done

