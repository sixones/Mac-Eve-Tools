CREATE TABLE "invTypeNames" (
  "typeID" smallint(6) NOT NULL,
  "typeName" varchar(100) default NULL,
  "description" varchar(3000) default NULL,
  PRIMARY KEY  ("typeID")
  );

insert into invTypeNames select typeID, typeName, description from invTypes where published = 1
