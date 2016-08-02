import MySQLdb
import sys
import codecs
from types import *
from decimal import *
from optparse import OptionParser
import db_config


def dumpPrerequisites():
    q_type_id = "SELECT typeID FROM invTypes where published = 1 AND groupID IN (SELECT groupID FROM invGroups WHERE categoryID IN (6,7,8,16,18,20,32));"

    # See below for another way to run this query
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


#So, if you want to get a list of the skills required for something (lets go with a Aeon, for typeid 23919)
# SELECT typename, it.typeid
#   FROM dgmTypeAttributes dta
#   JOIN invTypes it on it.typeid=coalesce(dta.valueint,dta.valuefloat)
#  WHERE dta.typeid=? and attributeid in (182,183,184,1285,1289,1290);
#
#+-------------+---------------------+--------------------------------------------+
#| attributeID | attributeName       | description                                |
#+-------------+---------------------+--------------------------------------------+
#|         182 | requiredSkill1      | The type ID of the skill that is required. |
#|         183 | requiredSkill2      | The type ID of the skill that is required. |
#|         184 | requiredSkill3      | The type ID of the skill that is required. |
#|         277 | requiredSkill1Level | Required skill level for skill 1           |
#|         278 | requiredSkill2Level | Required skill level for skill 2           |
#|         279 | requiredSkill3Level | Required skill level for skill 3           |
#|        1285 | requiredSkill4      | The type ID of the skill that is required. |
#|        1286 | requiredSkill4Level | Required skill level for skill 4           |
#|        1287 | requiredSkill5Level | Required skill level for skill 5           |
#|        1288 | requiredSkill6Level | Required skill level for skill 6           |
#|        1289 | requiredSkill5      | The type ID of the skill that is required. |
#|        1290 | requiredSkill6      | The type ID of the skill that is required. |
#+-------------+---------------------+--------------------------------------------+
