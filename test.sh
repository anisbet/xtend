#!/bin/bash
###############################################################################
#
# xtend.sh tests.
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

EXTEND_HOLD_OUTPUT="./xtend_hold_changes.diff"
EXTEND_DUE_DATE="./xtend_charge_changes.diff"
# Test one on-shelf extension --test=1, --update, --relative
make pristine >/dev/null 2>&1 
./xtend.sh --extend=ON_SHELF --update --relative --test=1 >/dev/null
if ! diff "$EXTEND_HOLD_OUTPUT" tests/xtend_hold_changes_01.diff; then
    echo "Test 01 failed"; exit 1
fi
make pristine >/dev/null 2>&1 
# Tests more than one
# Tests --relative 
# Tests absolute (implied).
# Tests --extends=ON_SHELF
# Tests --extneds=DUE_DATE
# Tests --test=1
# Test one on-shelf extension --test=2, --update, --relative
./xtend.sh --extend=ON_SHELF --update --relative --test=2 --days=21 >/dev/null
if ! diff "$EXTEND_HOLD_OUTPUT" tests/xtend_hold_changes_02.diff; then
    echo "Test 02 failed"; exit 1
fi
make pristine >/dev/null 2>&1
# Test Due date extension.
./xtend.sh --extend=DUE_DATE --update --relative --test=2 --days=21 >/dev/null
if ! diff "$EXTEND_DUE_DATE" tests/xtend_charge_changes_01.diff; then
    echo "Test 03 failed"; exit 1
fi
make pristine >/dev/null 2>&1 
# Test Due date extension.
./xtend.sh --extend=DUE_DATE --update --relative >/dev/null
if ! diff "$EXTEND_DUE_DATE" tests/xtend_charge_changes_02.diff; then
    echo "Test 04 failed"; exit 1
fi
make pristine >/dev/null 2>&1 