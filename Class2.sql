-- Sequence

CREATE TABLE EMP
AS SELECT * FROM NIKOVITS.EMP;

CREATE TABLE DEPT
AS SELECT * FROM NIKOVITS.DEPT;

CREATE SEQUENCE user_seq
START WITH 50
INCREMENT BY 50;

SELECT *
FROM DEPT;

INSERT INTO DEPT
VALUES (user_seq.NEXTVAL, 'DATA ENGINEERING', 'BUDAPEST');

-- Database link to aramis from ullman
create database link aramisdb connect to username IDENTIFIED by password
using 'aramis.inf.elte.hu:1521/aramis';

SELECT * FROM nikovits.emp@aramisdb;

-- 
-- Oracle storage concepts

-- 1.
-- Give the names and sizes of the database data files (*.dbf). (file_name, size_in_bytes)
SELECT *
FROM DBA_DATA_FILES;

SELECT file_name,
       tablespace_name,
       ROUND(bytes / 1073741824, 2)      AS size_gb,
       ROUND(user_bytes / 1073741824, 2) AS usable_gb,
       autoextensible,
       ROUND(maxbytes / 1073741824, 2)   AS max_gb,
       online_status
FROM   dba_data_files
ORDER  BY tablespace_name, file_id;

-- 2.
-- Give the names of the tablespaces in the database. (tablespace_name)
SELECT *
FROM DBA_TABLESPACES;

-- 3.
-- Which datafile belongs to which tablespace? List them. (filename, tablespace_name)
SELECT FILE_NAME, tablespace_name
FROM DBA_DATA_FILES;

-- 4.
-- Is there a tablespace that doesn't have any datafile in dba_data_files? -> see dba_temp_files
SELECT T.TABLESPACE_NAME, F.FILE_NAME
FROM DBA_TABLESPACES T
LEFT JOIN DBA_DATA_FILES F
ON T.TABLESPACE_NAME=F.TABLESPACE_NAME;

SELECT *
FROM DBA_TEMP_FILES;

-- 5.
-- What is the datablock size in USERS tablespace? (block_size)
SELECT TABLESPACE_NAME, BLOCK_SIZE
FROM DBA_TABLESPACES;

-- 6.
-- Find some segments whose owner is NIKOVITS. What segment types do they have? List the types. (segment_type)
SELECT UNIQUE SEGMENT_TYPE
FROM DBA_SEGMENTS
WHERE OWNER='NIKOVITS';

-- 7.
-- How many extents are there in file 'users02.dbf' ? (num_extents)
-- How many bytes do they occupy? (sum_bytes)

select file_id, COUNT(extent_id)
from dba_extents
group by file_id;

SELECT df.file_id, df.file_name, count(e.extent_id), sum(e.bytes), df.bytes, ROUND((sum(e.bytes) / df.bytes)*100, 2) as "Occupied"
FROM DBA_EXTENTS e
JOIN DBA_DATA_FILES df
ON e.file_id=df.file_id
group by df.file_id, df.file_name, df.bytes
having file_name like '%users02.dbf%';

SELECT FILE_ID, ROUND((SUM(BYTES)/11869880320)*100, 2) AS "Free Space"
FROM DBA_FREE_SPACE
WHERE FILE_ID=2
GROUP BY FILE_ID;

-- 8.
-- How many free extents are there in file 'users02.dbf', and what is the summarized size of them ? (num, sum_bytes)
-- How many percentage of file 'users02.dbf' is full (allocated to some object)?
SELECT 
  COUNT(*) AS "COUNT OF EXTENTS",
  SUM(BYTES) AS "FREE SPACE IN BYTES",
  ROUND((SUM(BYTES)/11869880320) * 100, 2)
FROM DBA_FREE_SPACE
WHERE FILE_ID=2;

-- 9.
-- Who is the owner whose objects occupy the most space in the database? (owner, sum_bytes)
SELECT OWNER, SUM(BYTES)
FROM DBA_SEGMENTS
GROUP BY OWNER
ORDER BY SUM(BYTES) DESC
FETCH FIRST 3 ROWS ONLY;

SELECT SUM(MAXBYTES/1073741824)
FROM DBA_DATA_FILES;

SELECT ROUND(SUM(bytes)     / 1073741824, 2) AS actual_gb,
       ROUND(SUM(user_bytes)/ 1073741824, 2) AS usable_gb,
       ROUND(SUM(maxbytes)  / 1073741824, 2) AS max_possible_gb
FROM dba_data_files;
-- 10.
-- Is there a table of owner NIKOVITS that has extents in at least two different datafiles? (table_name)
-- Select one from the above tables (e.g. tabla_123) and give the occupied space by files. (filename, bytes)
SELECT 
  segment_name, 
  segment_type, 
  count(unique file_id),
  SUM(bytes)/1048576
FROM DBA_EXTENTS
WHERE OWNER='NIKOVITS' AND segment_type='TABLE'
GROUP BY segment_name, segment_type
HAVING COUNT(UNIQUE file_id)>1
ORDER BY COUNT(unique file_id) desc;

-- 11.
-- On which tablespace is the table ORAUSER.DOLGOZO?
-- On which tablespace is the table NIKOVITS.ELADASOK? Why NULL? 
--  (-> partitioned table, stored on more than 1 tablespace)

SELECT DISTINCT TABLESPACE_NAME
FROM DBA_TABLES
WHERE TABLE_NAME='DOLGOZO';

SELECT *
FROM DBA_TABLES
WHERE TABLE_NAME='ELADASOK';

SELECT DISTINCT OBJECT_NAME, OBJECT_TYPE
FROM DBA_OBJECTS
WHERE OBJECT_NAME LIKE '%ELADASOK%';

-- 12.
-- Write a PL/SQL procedure, which prints out for the parameter user his/her newest table (which was created last),
-- the size of the table in bytes (the size of the table's segment) and the creation date. 
-- The output format should be the following.
-- (Number of spaces doesn't count between the columns, date format is yyyy.mm.dd.hh24:mi)

-- Table_name: NNNNNN   Size: SSSSSS bytes   Created: yyyy.mm.dd.hh:mi
CREATE OR REPLACE PROCEDURE newest_table(p_user VARCHAR2) Is
  table_name dba_objects.object_name%TYPE;
  table_size dba_extents.bytes%TYPE;
  created dba_objects.created%TYPE;
BEGIN
  SELECT o.object_name, SUM(s.bytes), o.created
  INTO table_name, table_size, created
  FROM DBA_OBJECTS o
  JOIN DBA_SEGMENTS s
  ON o.owner=s.owner and o.object_name=s.segment_name
  WHERE o.OBJECT_TYPE='TABLE' AND o.OWNER=UPPER(p_user)
  GROUP BY o.object_name, o.created
  ORDER BY CREATED DESC
  FETCH FIRST 1 ROWS ONLY;

  DBMS_OUTPUT.PUT_LINE('Table name: ' || table_name);
  DBMS_OUTPUT.PUT_LINE('Size: ' || table_size);
  DBMS_OUTPUT.PUT_LINE('Created: ' || TO_CHAR(created, 'YYYY.MM.DD'));
END;
/
SET SERVEROUTPUT ON;
EXECUTE newest_table('RTSUMV');

-- CREATE OR REPLACE PROCEDURE newest_table(p_user VARCHAR2) IS 
-- ...
-- Test your program:
SET SERVEROUTPUT ON
execute newest_table('nikovits');
execute newest_table('sila');

-- Hint:
-- Find the creation date of the object (table) in DBA_OBJECTS, then find the segment(s) of the table
-- in DBA_SEGMENTS.

-- -------------------------------------------------------
-- Comment!
-- Try the procedure with your username after running the following statement:
  CREATE TABLE t_without_segment(o INT) SEGMENT CREATION DEFERRED;    -- only in Ullman database
-- Then insert a row and retry the procedure.
  INSERT INTO t_without_segment VALUES(100);