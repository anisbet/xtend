#!/bin/bash
###############################################################################
#
# xtend.sh extend holds and due dates in Symphony.
# 
#  Copyright 2024 Andrew Nisbet
#  
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#  
#       http://www.apache.org/licenses/LICENSE-2.0
#  
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# Tue 06 Feb 2024 03:34:18 PM EST
#
###############################################################################
set -o pipefail

. ~/.bashrc

VERSION="1.0.0"
APP=$(basename "$0")
WORKING_DIR='.'
EXTEND_DAYS=7
EXTENSION_TYPE=''
PROFILES=''
ITYPES=''
## Set up logging.
LOG_FILE="$WORKING_DIR/${APP}.log"
# Logs messages to STDERR and $LOG file.
# param:  Log file name. The file is expected to be a fully qualified path or the output
#         will be directed to a file in the directory the script's running directory.
# param:  Message to put in the file.
# param:  (Optional) name of a operation that called this function.
logit()
{
    local message="$1"
    local time=''
    time=$(date +"%Y-%m-%d %H:%M:%S")
    if [ -t 0 ]; then
        # If run from an interactive shell message STDERR.
        echo -e "[$time] $message" >&2
    fi
    echo -e "[$time] $message" >>"$LOG_FILE"
}
# Prints out usage message.
usage()
{
    cat << EOFU!
 Usage: $APP [flags]

extend holds and due dates in Symphony. Provisions are made to optionally
exclude profiles, or item types.

Flags:
-d, --days[int] Optional number of days to put off the overdue or
  expire deadline. Default 7.
-e, --extend=["ON_SHELF"|"DUE_DATE"] Required option of either extend ON_SHELF
  expiry, or exend DUE_DATE of items charged to customers.
-h, --help: This help message.
-p, --profiles[profile1,profile2,...] Optional comma separated subset of
  profiles. If none, all profiles are affected. Use '~profile,...' to 
  negate profiles.
-t, --item_types[itemtype1,itemtype2,...] Optional comma separated list of
  item types. If none provided select by all item types. Use '~TYPE,...'
  to negate selection.
-v, --version: Print watcher.sh version and exits.
 Example:
    $APP --extend="ON_SHELF"
    $APP --extend="DUE_DATE" --days=10 --profiles="EPL_XDLOAN"
EOFU!
}

# Function to select active available holds to be extended.
# By default all holds are extended by 'n' days, regardless
# of how many days are left before expiry.
extend_shelf_holds()
{
    echo "on-shelf holds"
}

extend_due_dates()
{
    echo "due dates"
}

### Check input parameters.
# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "days:,extend:,help,profiles:,item_types:,version" -o "d:e:hp:t:v" -a -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"

while true
do
    case $1 in
    -d|--days)
        shift
        EXTEND_DAYS="$1"
        ;;
    -e|--extend)
        shift
        EXTENSION_TYPE="$1"
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    -p|--profiles)
        shift
        PROFILES="$1"
        ;;
    -t|--item_types)
        shift
        ITYPES="$1"
        ;;
    -v|--version)
        echo "$APP version: $VERSION"
        exit 0
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done
# Required EXTENSION_TYPE check.
: "${EXTENSION_TYPE:?Missing -e,--extend\=\'ON_SHELF\|DUE_DATE\'}"
logit "$APP version $VERSION"

## Extend ON_SHELF
if [ "$EXTENSION_TYPE" == "ON_SHELF" ]; then
    logit "extending on shelf holds by $EXTEND_DAYS days"
    [ -n "$ITYPES" ] && logit "item types ($ITYPES)"
    [ -n "$PROFILES" ] && logit "profiles ($PROFILES)"
    extend_shelf_holds
## Extend DUE_DATE
elif [ "$EXTENSION_TYPE" == "DUE_DATE" ]; then
    logit "extending due dates by $EXTEND_DAYS days"
    [ -n "$ITYPES" ] && logit "item types ($ITYPES)"
    [ -n "$PROFILES" ] && logit "profiles ($PROFILES)"
    extend_due_dates
else 
    logit "unrecognized extension type '$EXTENSION_TYPE', exiting."
    exit 1
fi
logit "done"
exit 0
