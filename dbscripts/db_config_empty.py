""" Copy db_config_clear.py to db_config.py and add login inforation to db_config.py.
    db_config_clear.py should never contain database login information.
    db_config.py should never be checked into source control.
"""
database = {
    'host': "localhost",
    'user': "",
    'passwd': "",
    'db': "eve",
    'charset':"utf8",
    'use_unicode': True}
