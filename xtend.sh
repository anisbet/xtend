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
APP=$(basename -s .sh "$0")
SERVER=$(hostname)
ILS=true
[ "$SERVER" != 'edpl.sirsidynix.net' ] && ILS=false
WORKING_DIR='.'
EXTEND_DAYS=7
ITEM_TYPES=''
PROFILES=''
ITYPES=''
DRY_RUN=true
RELATIVE_DATE=false
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
  expire deadline. Default $EXTEND_DAYS.
-e, --extend=["ON_SHELF"|"DUE_DATE"] Required option of either extend ON_SHELF
  expiry, or exend DUE_DATE of items charged to customers.
-h, --help: This help message.
-p, --profiles[profile1,profile2,...] Optional comma separated subset of
  profiles. If none, all profiles are affected. Use '~profile,...' to 
  negate profiles.
-r, --relative Extends each selected items'' current due or expire date
  by 'n' --days. By default $APP sets all due or expiry dates to the same date.
-t, --item_types[itemtype1,itemtype2,...] Optional comma separated list of
  item types. If none provided select by all item types. Use '~TYPE,...'
  to negate selection.
-u, --update Actually make changes. By default $APP does a dry run.
-v, --version Print $APP version and exits.
 Example:
    $APP --extend="ON_SHELF"
    $APP --extend="DUE_DATE" --days=10 --profiles="EPL_XDLOAN"
EOFU!
}

# Changes each hold expires date to a specific $EXTEND_DAYS from it's current hold expires date.
# params: pre hold date change, post hold date change, name of the diff file to track changes.
relative_hold_self_extension()
{
    local pre_aa_holds="$1" # 3167781|20240208|
    local post_aa_holds="$2" # 3167781|20240217|
    local receipt="$3"
    local hold_key=''
    local hold_expires_date=''
    local new_hold_expires_date=''
    while read -r LINE; do
        hold_key=$(echo "$LINE" | pipe.pl -oc0 -P)
        hold_expires_date=$(echo "$LINE" | pipe.pl -oc1)
        if [ "$ILS" == true ]; then
            new_hold_expires_date=$(transdate -p "$hold_expires_date"+"$EXTEND_DAYS")
            echo "$hold_key" | edithold -6 "$new_hold_expires_date" 2>>"$LOG_FILE"
        else
            logit "DEV: pretending to run update."
            new_hold_expires_date=$(date -d "$hold_expires_date +$EXTEND_DAYS days" '+%Y%m%d')
            echo "$LINE" | pipe.pl -mc1:"${new_hold_expires_date}_" >>"$post_aa_holds"
        fi
    done <"$pre_aa_holds"
    if [ "$ILS" == true ]; then
        selhold -jACTIVE -aY -oK6 >"$post_aa_holds"
    fi
    echo "== break" >>"$receipt"
    diff -y "$pre_aa_holds" "$post_aa_holds" >>"$receipt"
}

# Changes all hold expires dates to a specific date; $EXTEND_DATE
# params: pre hold date change, post hold date change, name of the diff file to track changes.
absolute_hold_self_extension()
{
    local pre_aa_holds="$1"
    local post_aa_holds="$2"
    local receipt="$3"
    # Update selected records with editcharge
    if [ "$ILS" == true ]; then
        edithold -6 "$EXTEND_DATE" <"$pre_aa_holds" 2>>"$LOG_FILE"
        selhold -jACTIVE -aY -oK6 >"$post_aa_holds"
    else
        logit "DEV: pretending to run update."
        pipe.pl -mc1:"${EXTEND_DATE}_" -P <"$pre_aa_holds" >"$post_aa_holds"
    fi
    echo "== break" >>"$receipt"
    diff -y "$pre_aa_holds" "$post_aa_holds" >>"$receipt"
}

# Function to select active available holds to be extended.
# By default all holds are extended by 'n' days, regardless
# of how many days are left before expiry.
extend_shelf_holds()
{
    # Check if we can suspend active available holds.
    # -1 changes the suspend begin date to the specified value.
    # -2 changes the suspend end date to the specified value.
    # -6 the date available hold expires. Both selhold and edithold.
    local pre_aa_holds_list="$WORKING_DIR/xtend_pre_aa_holds.lst"
    local post_aa_holds_list="$WORKING_DIR/xtend_post_aa_holds.lst"
    local receipt_file="$WORKING_DIR/xtend_hold_changes.diff"
    if [ $ILS == true ]; then
        selhold -jACTIVE -aY -oK6 >"$pre_aa_holds_list"
    else
        echo -e "43167775|20240208|\n43167781|20240224|" >"$pre_aa_holds_list"
    fi
    # It doesn't make sense to exclude holds by profile or item types.
    if [ "$DRY_RUN" == true ]; then
        logit "Dry run mode: check $pre_aa_holds_list for before and $post_aa_holds_list for changes."
    else
        # Update selected records with editcharge
        if [ "$RELATIVE_DATE" == true ]; then
            relative_hold_self_extension "$pre_aa_holds_list" "$post_aa_holds_list" "$receipt_file"
        else
            absolute_hold_self_extension "$pre_aa_holds_list" "$post_aa_holds_list" "$receipt_file"
        fi
    fi
    logit "preserving $pre_aa_holds_list and $post_aa_holds_list, though they will be"
    logit "overwritten next time. See $receipt_file for before / after comparison."
}

# Extends due dates on each item by it's current due date +EXTEND_DAYS.
relative_due_date_extension()
{
    local charges="$1"  # 12345|4567890|21|1|1|202402082359|
    local edit_charges="$2"  # 4567890|21|1|1|
    local receipt="$3"
    local item_key=''
    local item_due_date=''
    local new_due_date=''
    local tmp_file="$WORKING_DIR/xtend_00.tmp"
    while read -r LINE; do
        item_key=$(echo "$LINE" | pipe.pl -oc1,c2,c3 -P)
        item_due_date=$(echo "$LINE" | pipe.pl -oc5 | pipe.pl -mc0:########_)
        # Update selected records with editcharge
        if [ "$ILS" == true ]; then
            new_due_date=$(transdate -p "$item_due_date"+"$EXTEND_DAYS")
            echo "$item_key" | editcharge -d "${new_due_date}2359" 2>>"$LOG_FILE"
        else
            logit "DEV: pretending to run update."
            new_due_date=$(date -d "$item_due_date +$EXTEND_DAYS days" '+%Y%m%d')
            echo "$LINE" | pipe.pl -mc5:"${new_due_date}2359_" >>"$tmp_file"
        fi
    done <"$charges"
    # Save changes for auditing
    if [ "$ILS" == true ]; then
        # Take a snapshot of changes for comparison.
        pipe.pl -oc1,continue <"$charges" | selcharge -iK -oUKd >"$tmp_file"
    fi
    echo "== break" >>"$receipt"
    diff -y "$charges" "$tmp_file" >>"$receipt"
    rm "$tmp_file"
}

# Sets all selected charge due dates to a specific date.
absolute_due_date_extension()
{
    local charges="$1"  # 12345|4567890|21|1|1|202402082359|
    local edit_charges="$2"  # 4567890|21|1|1|
    local receipt="$3"
    local tmp_file="$WORKING_DIR/xtend_00.tmp"
    # Update selected records with editcharge
    if [ $ILS == true ]; then
        editcharge -d "${EXTEND_DATE}2359" <"$edit_charges" 2>>"$LOG_FILE"
        # Take a snapshot of changes for comparison.
        selcharge -tACTIVE -oUKd | pipe.pl -Gc5:NEVER >"$tmp_file"
    else
        logit "DEV: pretending to run update."
        pipe.pl -mc5:"${EXTEND_DATE}2359_" <"$charges_list" >"$tmp_file"
    fi
    echo "== break" >>"$receipt"
    diff -y "$charges_list" "$tmp_file" >>"$receipt_file"
    rm "$tmp_file"
}

# Extends due dates on all materials by default or based on items' types 
# or profiles of borrowers.
# params: None
# Creates xtend_charge_changes.lst - all accumulated changes to changes made to date.
extend_due_dates()
{
    local charges_list="$WORKING_DIR/xtend_charges.lst"
    local edit_charges_list="$WORKING_DIR/xtend_edit_charges.lst"
    local tmp_file="$WORKING_DIR/xtend_tmp.lst"
    local receipt_file="$WORKING_DIR/xtend_charge_changes.diff"
    touch $tmp_file
    # -d change due date and time to the specified value. Default time is midnight. 
    # You need to pass in additional 2359 to make it end of day due date.
    # U=user key, K=charge key, d=due date.
    # Some due dates are 'NEVER' so exclude them with pipe.pl.
    if [ $ILS == true ]; then
        selcharge -tACTIVE -oUKd | pipe.pl -Gc5:NEVER >"$charges_list"
    else
        echo -e "12345|4567890|21|1|1|202402082359|\n12345|2595784|1|1|1|202402242359|" >"$charges_list"
    fi
    # You can now sub-select by profile or item type here
    if [ -n "$PROFILES" ]; then
        if [ $ILS == true ]; then
            seluser -iU -oUS -p"$PROFILES" < "$charges_list" >"$tmp_file"
        else
            cat "$charges_list" >"$tmp_file"
        fi
    fi
    if [ -n "$ITEM_TYPES" ]; then
        if [ $ILS == true ]; then
            pipe.pl -oc1,c2,c3,remaining -P < "$charges_list" | selitem -iI -oIS -t"$ITEM_TYPES" | pipe.pl -oc3,c0,c1,c2,c4,continue >>"$tmp_file"
        else
            # 12345|2595784|12|1|1|202402242359| => 2595784|12|1|12345|1|202402242359| => 2595784|12|1|12345|1|202402242359| => 12345|2595784|12|1|1|202402242359|
            pipe.pl -oc1,c2,c3,remaining -P < "$charges_list" | cat - | pipe.pl -oc3,c0,c1,c2,c4,continue >>"$tmp_file"
        fi
    fi
    if [ -s "$tmp_file" ]; then
        pipe.pl -oc1,c2,c3,c4 -P < "$tmp_file" | sort | uniq  >"$edit_charges_list"
    else
        pipe.pl -oc1,c2,c3,c4 -P < "$charges_list" >"$edit_charges_list"
    fi
    if [ "$DRY_RUN" == true ]; then
        logit "Dry run mode: check $charges_list and $edit_charges_list for changes."
    else
        if [ "$RELATIVE_DATE" == true ]; then
            relative_due_date_extension "$charges_list" "$edit_charges_list" "$receipt_file"
        else
            absolute_due_date_extension "$charges_list" "$edit_charges_list" "$receipt_file"
        fi
    fi
    logit "preserving $charges_list and $edit_charges_list, though they will be"
    logit "overwritten next time. See $receipt_file for before / after comparison."
    rm "$tmp_file"
}

### Check input parameters.
# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "days:,extend:,help,profiles:,relative,item_types:,update,version" -o "d:e:hp:rt:uv" -a -- "$@")
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
        ITEM_TYPES="$1"
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    -p|--profiles)
        shift
        PROFILES="$1"
        ;;
    -r|--relative)
        RELATIVE_DATE=true
        ;;
    -t|--item_types)
        shift
        ITYPES="$1"
        ;;
    -u|--update)
        DRY_RUN=false
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
# Required ITEM_TYPES check.
: "${ITEM_TYPES:?Missing -e,--extend\=\'ON_SHELF\|DUE_DATE\'}"
if [ "$ILS" == true ]; then
    EXTEND_DATE=$(transdate -d+"$EXTEND_DAYS")
else
    # On the dev server there is no transdate, and the ILS doesn't do this command.
    EXTEND_DATE=$(date -d "+$EXTEND_DAYS days" '+%Y%m%d')
fi
[ -n "$EXTEND_DATE" ]|| { logit "**error, date not calculated."; exit 1; }
logit "$APP version $VERSION"
[ "$DRY_RUN" == true ] && logit "Dry run mode. Use --update to make changes."
## Extend ON_SHELF
if [ "$ITEM_TYPES" == "ON_SHELF" ]; then
    if [ "$RELATIVE_DATE" == true ]; then
        logit "extending on-shelf expires date for each hold by '$EXTEND_DAYS' days"
    else
        logit "extending all on-shelf holds to '$EXTEND_DATE'"
    fi
    [ -n "$ITYPES" ] && logit "item types ($ITYPES)"
    [ -n "$PROFILES" ] && logit "profiles ($PROFILES)"
    extend_shelf_holds
## Extend DUE_DATE
elif [ "$ITEM_TYPES" == "DUE_DATE" ]; then
    if [ "$RELATIVE_DATE" == true ]; then
        logit "extending the due date for each charge by '$EXTEND_DAYS' days"
    else
        logit "extending all due dates to '$EXTEND_DATE'"
    fi
    [ -n "$ITYPES" ] && logit "item types ($ITYPES)"
    [ -n "$PROFILES" ] && logit "profiles ($PROFILES)"
    extend_due_dates
else 
    logit "unrecognized extension type '$ITEM_TYPES', exiting."
    exit 1
fi
logit "done"
exit 0
