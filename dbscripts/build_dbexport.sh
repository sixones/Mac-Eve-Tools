#!/bin/bash

DBEXPORT=database.sql

DBVERSION=12
DBEXPANSION="Rubicon 1.0"

VERQUERY="INSERT INTO version VALUES ($DBVERSION,'$DBEXPANSION');"

if [ ! -r db_config.py ]; then
    echo "Missing db_config.py"
    echo "Copy db_config_clean.py to db_config.py and fill in the database connection information"
    exit
fi

rm -f tempdb.db
rm -f rows.sql

/bin/bash dumprows.sh rows.sql

/bin/cat tables.sql rows.sql post.sql > $DBEXPORT
echo "$VERQUERY" >> $DBEXPORT
/usr/bin/bzip2 < $DBEXPORT > $DBEXPORT.bz2
/usr/bin/sqlite3 tempdb.db < $DBEXPORT 

SHA_EXE="python sha1_base64.py" # was "./sha1"
SHA_SQL=`${SHA_EXE} $DBEXPORT`
SHA_BZ2=`${SHA_EXE} $DBEXPORT.bz2`
SHA_DB=`${SHA_EXE} tempdb.db`

XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<EveDatabaseExport version=\"$DBVERSION\">
	<file>$DBEXPORT.bz2</file>
	<sha1_bzip>$SHA_BZ2</sha1_bzip>
	<sha1_dec>$SHA_SQL</sha1_dec>
	<sha1_built>$SHA_DB</sha1_built>
</EveDatabaseExport>"


echo $XML > database.xml

rm -f $DBEXPORT
rm -f tempdb.db
rm -f rows.sql

