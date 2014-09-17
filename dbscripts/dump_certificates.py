#! /usr/bin/python

import re
import sys
from optparse import OptionParser
from yaml import load, dump

try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    sys.stderr.write( "Failed to import C-yaml. Using Python yaml.\n" )
    from yaml import Loader, Dumper


def dumpCertificates(certFile):
    with open(certFile) as f:
        data = load(f, Loader=Loader)
        #output = dump(data, Dumper=Dumper)

        print u'BEGIN TRANSACTION;'

        for key, item in data.items():
            certificateID = key
            description = item["description"]
            groupID = item["groupID"]
            name = item["name"]

            name = re.sub("'","''",name)
            description = re.sub("'","''",description)

            # insert this certificate into the database
            print u"INSERT INTO crtCertificates VALUES(%s,%s,'%s','%s');" %(certificateID,groupID,name,description)

            if "recommendedFor" in item:
                recommendedFor = item["recommendedFor"] # This will be a list
                for recommend in recommendedFor:
                    # Insert this recommendation into the database
                    print u"INSERT INTO crtRecommendations VALUES(%s,%s);" %(certificateID,recommend)

            skills = item["skillTypes"] # This will be another dictionary, I think
            for skillID, levels in skills.items():
                basic = 0
                standard = 0
                improved = 0
                advanced = 0
                elite = 0
                if "basic" in levels:
                    basic = levels["basic"]
                if "standard" in levels:
                    standard = levels["standard"]
                if "improved" in levels:
                    improved = levels["improved"]
                if "advanced" in levels:
                    advanced = levels["advanced"]
                if "elite" in levels:
                    elite = levels["elite"]
                # insert this skill into the cert skill table
                print u"INSERT INTO crtCertSkills VALUES(%s,%s,%s,%s,%s,%s,%s);" %(certificateID,skillID,basic,standard,improved,advanced,elite)

        print u'COMMIT TRANSACTION;'


def createCertificateTables():
    print """CREATE TABLE "crtCertificates" (
    "certificateID" int(11) NOT NULL,
    "groupID" smallint(6),
    "name" varchar(100),
    "description" varchar(500),
    PRIMARY KEY("certificateID")
    );"""

    print """CREATE TABLE "crtRecommendations" (
    "certificateID" int(11) NOT NULL,
    "typeID" int(11) NOT NULL,
    PRIMARY KEY("certificateID","typeID")
    );"""

    print """CREATE TABLE "crtCertSkills" (
    "certificateID" int(11) NOT NULL,
    "typeID" smallint(6) NOT NULL,
    "basic" smallint(6),
    "standard" smallint(6),
    "improved" smallint(6),
    "advanced" smallint(6),
    "elite" smallint(6),
    PRIMARY KEY("certificateID","typeID")
    );"""

if __name__ == "__main__":
    parser = OptionParser("usage: %prog [options] [<filename>]")
    parser.add_option("-t","--tables",dest="tables",action='store_true',help="Dump SQL for creating new (Rubicon) table schemas for certificates");
    (options, args) = parser.parse_args()

    if options.tables:
        createCertificateTables()
    else:
        if len(args) != 1:
            parser.error("Certificate yaml filename is required")
        dumpCertificates(args[0])

# Example of part of one certificate from CCP's certificates.yaml file
#70:
#    description: This certificate represents a level of competence in handling capital
#        hybrid turrets. The holder has learned that blasters are extreme close range
#        weapons, while railguns are their counterpart at very long range, and that
#        both use hybrid charges as ammunition. This is a good skillset for capsuleers
#        specializing in capital Gallente vessels based on Dreadnought and Titan hulls.
#    groupID: 255
#    name: Capital Hybrid Turret
#    recommendedFor:
#    - 671
#    - 19724
#    skillTypes:
#        3300:
#            advanced: 5
#            basic: 5
#            elite: 5
#            improved: 5
#            standard: 5
#        3301:
#            advanced: 3
#            basic: 3
#            elite: 3
#            improved: 3
#            standard: 3


# Old cert related tables:
#CREATE TABLE "crtCategories" (
#    "categoryID" smallint(6),
#    "categoryName" varchar(256),
#    PRIMARY KEY("categoryID")
#);
#
#CREATE TABLE "crtCertificates" (
#    "certificateID" int(11),
#    "categoryID" smallint(6),
#    "classID" int(11),
#    "grade" smallint(6),
#    "description" varchar(500),
#    PRIMARY KEY("certificateID")
#);
#
#CREATE TABLE "crtClasses" (
#    "classID" int(11),
#    "className" varchar(256),
#    PRIMARY KEY("classID")
#);
#
#CREATE TABLE "crtRelationships" (
#    "relationshipID" int(11),
#    "parentID" int(11),
#    "parentTypeID" smallint(6),
#    "parentLevel" smallint(6),
#    "childID" int(11),
#    PRIMARY KEY("relationshipID")
#);
#
