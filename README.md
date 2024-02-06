# xtend
Project to extend holds and due dates in Symphony.

The reason for this is due to (potential) strike action by workers. These scripts will ensure that items checked out don't become due during the strike, and that items that are on-shelf don't expire until the strike is over.

The script must allow the following parameters.
* --extend_days[int] Optional number of days to put off the overdue or expire deadline. Default 7.
* --ignore_profiles[profile1,profile2,...] Optional comma separated list of profiles not affected by extensions. None by default.
* --ignore_itypes[itemtype1,itemtype2,...] Optional comma separated list of item types to ignore. None by default.
* --extend=["ON_SHELF"|"DUE_DATE"] Required option of either extend ON_SHELF expiry, or exend `DUE_DATE` of items charged to customers.
