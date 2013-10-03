#! /usr/bin/python

import hashlib
import base64
from optparse import OptionParser

def getHash( filename ):
    """ This is a replacement for the C based program that Vitality was using to
        generate hashes of database files.
    """
    with open( filename, 'r' ) as f:
        data = f.read()
        h = hashlib.sha1(data)
        return base64.b64encode(h.digest())

if __name__ == "__main__":
    parser = OptionParser()
#    parser.add_option("-f","--file",dest="file",help="output file name (append)");
    (options, args) = parser.parse_args()
    if len(args) > 0:
        b64 = getHash(args[0])
        print "%s" % b64
