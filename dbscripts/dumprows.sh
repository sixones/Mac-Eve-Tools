#!/bin/bash

# cat 1 = Characters, Corps, Alliances, Factions
# cat 18 = Drones
# cat 20 = implants
# cat 32 = T3 subsystems
CATEGORIES="1,6,7,8,16,18,20,32"
SCRIPT=dump_table.py
PYEXE=python

$PYEXE $SCRIPT -t chrRaces -f $1 \
-q "SELECT raceID, raceName, iconID FROM chrRaces;";

$PYEXE $SCRIPT -t invMarketGroups -f $1 \
-q "SELECT marketGroupID, parentGroupID, marketGroupName, description, iconID, hasTypes FROM invMarketGroups;"

$PYEXE $SCRIPT -t invCategories -f $1 \
-q "SELECT categoryID,categoryName,iconID
FROM invCategories
WHERE published = 1
AND categoryID IN ($CATEGORIES);"

$PYEXE $SCRIPT -t invGroups -f $1 \
-q "SELECT groupID,categoryID,groupName,iconID
FROM invGroups
WHERE categoryID IN ($CATEGORIES);"

$PYEXE $SCRIPT -t invTypes -f $1 \
-q "SELECT typeID,groupID,typeName,description,mass,volume,capacity,raceID,basePrice,marketGroupID 
FROM invTypes 
WHERE published = 1
AND groupID IN (SELECT groupID FROM invGroups WHERE categoryID IN ($CATEGORIES));"

$PYEXE $SCRIPT -t invTraits -f $1 \
-q "SELECT typeID,skillID,bonus,bonusText,unitID FROM invTraits;"

$PYEXE $SCRIPT -t dgmTypeAttributes -f $1 \
-q" SELECT typeID, attributeID, valueInt, valueFloat
FROM dgmTypeAttributes
WHERE typeID IN (SELECT typeID FROM invTypes WHERE published = 1 AND groupID IN (SELECT groupID FROM invGroups WHERE categoryID IN ($CATEGORIES)));"

$PYEXE $SCRIPT -t dgmAttributeTypes -f $1 \
-q "SELECT attributeID, attributeName, description, iconID, defaultValue, displayName, unitID, stackable, highIsGood, categoryID
FROM dgmAttributeTypes
WHERE published = 1
AND attributeID IN 
	(SELECT attributeID FROM dgmTypeAttributes WHERE published = 1 AND typeID IN 
			(SELECT typeID FROM invTypes WHERE groupID IN 
						(SELECT groupID FROM invGroups WHERE categoryID IN ($CATEGORIES))));"

$PYEXE $SCRIPT -t invMetaTypes -f $1 \
-q "SELECT typeID, parentTypeID, metaGroupID FROM invMetaTypes WHERE typeID IN
	(SELECT typeID FROM invTypes WHERE published = 1 AND groupID IN (SELECT groupID FROM invGroups WHERE categoryID IN ($CATEGORIES)));"


$PYEXE $SCRIPT -t invMetaGroups -f $1 \
-q "SELECT metaGroupID, metaGroupName FROM invMetaGroups WHERE metaGroupID IN (1,2,3,4,5,6,14);"

$PYEXE $SCRIPT -t eveUnits -f $1 \
-q "SELECT unitID, unitName, displayName FROM eveUnits;"

#$PYEXE $SCRIPT -t eveGraphics -f $1 \
#-q "SELECT graphicID, icon FROM eveGraphics WHERE icon <> '';"

$PYEXE $SCRIPT -t trnTranslations -f $1 \
-q "SELECT tcID, keyID, languageID, text FROM trnTranslations WHERE languageID IN ('DE','RU');"

$PYEXE $SCRIPT -t trnTranslationColumns -f $1 \
-q "SELECT tcGroupID,tcID,tableName,columnName,masterID FROM trnTranslationColumns;"

# Pre-Rubicon certificate tables
#$PYEXE $SCRIPT -t crtCategories -f $1 \
#-q "SELECT categoryID, categoryName FROM crtCategories WHERE categoryID <> 17;"
#
#$PYEXE $SCRIPT -t crtCertificates -f $1 \
#-q "SELECT certificateID, categoryID, classID, grade, description FROM crtCertificates;";
#
#$PYEXE $SCRIPT -t crtClasses -f $1 \
#-q "SELECT classID, className FROM crtClasses;";
#
#$PYEXE $SCRIPT -t crtRelationships -f $1 \
#-q "SELECT relationshipID, parentID, parentTypeID, parentLevel, childID from crtRelationships;";

# For Market Orders UI
$PYEXE $SCRIPT -t metStations -f $1 \
-q "SELECT stationID, solarSystemID, stationName FROM staStations;";

$PYEXE $SCRIPT -t metTypeNames -f $1 \
-q "SELECT typeID, typeName, description FROM invTypes;";

$PYEXE $SCRIPT -t mapSolarSystems -f $1 \
-q "SELECT * FROM mapSolarSystems;";

$PYEXE $SCRIPT -t mapSolarSystemJumps -f $1 \
-q "SELECT * FROM mapSolarSystemJumps;";

$PYEXE $SCRIPT -t mapConstellations -f $1 \
-q "SELECT * FROM mapConstellations;";

$PYEXE $SCRIPT -t mapRegions -f $1 \
-q "SELECT * FROM mapRegions;";

$PYEXE dump_certificates.py certificates.yaml >> $1
$PYEXE dump_pre.py >> $1
$PYEXE dump_attrs.py -f $1

