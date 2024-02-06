# xtend
Project to extend holds and due dates in Symphony.

The reason for this is due to (potential) strike action by workers. These scripts will ensure that items checked out don't become due during the strike, and that items that are on-shelf don't expire until the strike is over.

The script must allow the following parameters.
* `-d, --days=[int]` Optional number of days to put off the overdue or expire deadline. Default 7.
* `-e, --extend=["ON_SHELF"|"DUE_DATE"]` Required option of either extend `ON_SHELF` expiry, or exend `DUE_DATE` of items charged to customers.
* `-h, --help` Show usage and exit.
* `-t, --item_types=[itemtype1,itemtype2,...]` Optional comma separated list of
  item types. If none provided select by all item types. Use '~TYPE,...'
  to negate selection.
* `-p, --profiles=[profile1,profile2,...]` Optional comma separated subset of
  profiles. If none, all profiles are affected. Use '~profile,...' to 
  negate profiles.
* `-v, --version` Show version and exit.


