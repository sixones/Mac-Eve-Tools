import MySQLdb
import sys
import codecs
from types import *
from decimal import *
from optparse import OptionParser
import db_config


def dumpPrerequisites():
    q_type_id = "SELECT typeID FROM invTypes where published = 1 AND groupID IN (SELECT groupID FROM invGroups WHERE categoryID IN (6,7,8,16));"

    table_query = """SELECT taSkill.typeID, 
        COALESCE(taSkill.valueInt,FLOOR(taSkill.valueFloat)) as skillTypeID, 
        COALESCE(taLevel.valueInt,FLOOR(taLevel.valueFloat)) as skillLevel 
        FROM  
        dgmTypeAttributes taSkill JOIN dgmAttributeTypes atSkill ON (taSkill.attributeID = atSkill.attributeID), 
        dgmTypeAttributes taLevel JOIN dgmAttributeTypes atLevel ON (taLevel.attributeID = atLevel.attributeID) 
        WHERE taSkill.typeID = %s 
        AND taSkill.typeID = taLevel.typeID 
        AND atLevel.categoryID = atSkill.categoryID 
        AND atSkill.attributeName REGEXP \'^requiredSkill[0-9]\$\' 
        AND atLevel.attributeName REGEXP \'^requiredSkill[0-9]Level\$\' 
        AND atLevel.attributeName REGEXP atSkill.attributeName;"""

#    conn = MySQLdb.connect( host = "localhost", user = "", passwd = "", db = "eve", charset ="utf8", use_unicode = True)
# Database connection details are stored in db_config.py
    conn = MySQLdb.connect( **db_config.database )

    cursor = conn.cursor()
    skill_cursor = conn.cursor()

    cursor.execute('SET NAMES utf8;')
    cursor.execute('SET CHARACTER SET utf8;')
    cursor.execute('SET character_set_connection=utf8;')


    print "BEGIN TRANSACTION;\n"
    
    try:	
        cursor.execute(q_type_id)
    	row = cursor.fetchone()

        while row:
            skill_cursor.execute( table_query, row )
            prereq = skill_cursor.fetchone()
            i = 0
            while prereq:
                print "INSERT INTO typePrerequisites VALUES (%d,%d,%d,%d);" % (prereq + (i,))
                prereq = skill_cursor.fetchone()
                i += 1

            row = cursor.fetchone()

    except MySQLdb.Error, e:
        print "Unable to build typePrerequisites table. Error: %s" % e
        conn.rollback()
        return
    
    print 'COMMIT TRANSACTION;\n'

    cursor.close()
    conn.close()


if __name__ == "__main__":
    dumpPrerequisites()

