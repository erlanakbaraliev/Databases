-- 1.
-- How many data blocks are allocated in the database for the table NIKOVITS.CIKK?
-- There can be empty blocks, but we count them too.
-- The same question: how many data blocks does the segment of the table have?
SELECT OWNER, SEGMENT_NAME, BLOCKS
FROM DBA_SEGMENTS
WHERE OWNER='NIKOVITS' AND SEGMENT_TYPE='TABLE' AND SEGMENT_NAME='CIKK';

SELECT OWNER, SEGMENT_NAME, SUM(BLOCKS)
FROM DBA_EXTENTS
WHERE OWNER='NIKOVITS'
AND   SEGMENT_NAME='CIKK'
GROUP BY OWNER, SEGMENT_NAME;

-- 2.
-- How many filled data blocks does the previous table have?
-- Filled means that the block is not empty (there is at least one row in it).
-- This question is not the same as the previous !!!
-- How many empty data blocks does the table have?
-- Blocks, bytes in dba_segments are allocated space for a specific table.
-- 8 blocks may be allocated, but only 5 are filled with actual data, 3 remating blocks are strictly reserved only for this table like parking spot for people with disabilities.
-- Allocated, actually used, empty space, oracle uses blocks, not bytes.

SELECT OWNER, SEGMENT_NAME, BLOCKS
FROM DBA_SEGMENTS
WHERE OWNER='NIKOVITS' AND SEGMENT_TYPE='TABLE' AND SEGMENT_NAME='CIKK';

SELECT OWNER, TABLE_NAME, BLOCKS, EMPTY_BLOCKS, NUM_ROWS
FROM DBA_tables
WHERE OWNER='NIKOVITS'
AND   TABLE_NAME='CIKK';

-- 3.
-- How many rows are there in each block of the previous table?
SELECT DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID),
       COUNT(*)
FROM NIKOVITS.CIKK
GROUP BY DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID);

-- 4.
-- There is a table NIKOVITS.ELADASOK which has the following row:
-- szla_szam = 100 (szla_szam is a column name)
-- In which datafile is the given row stored?
-- Within the datafile in which data block? (block number) 
-- In which data object? (Give the name of the segment.)

SELECT *
FROM DBA_TAB_COLUMNS
WHERE OWNER='NIKOVITS' AND TABLE_NAME='ELADASOK';

SELECT *
FROM DBA_EXTENTS
WHERE SEGMENT_NAME='ELADASOK' AND OWNER='NIKOVITS';

SELECT *
FROM DBA_DATA_FILES
WHERE FILE_ID IN (7, 5);
-- ELADASOK table is in Users and Example tablspaces

-- 2. In which datafile is the given row stored (szla_szam)?
SELECT dbms_rowid.rowid_relative_fno(ROWID) file_id, 
       dbms_rowid.rowid_object(ROWID) data_object,
       dbms_rowid.rowid_block_number(ROWID) block_nr, 
       dbms_rowid.rowid_row_number(ROWID) row_nr 
FROM nikovits.eladasok 
WHERE szla_szam = 100;

SELECT dbms_rowid.rowid_relative_fno(ROWID) file_id, 
       dbms_rowid.rowid_object(ROWID) data_object,
       dbms_rowid.rowid_block_number(ROWID) block_nr, 
       dbms_rowid.rowid_row_number(ROWID) row_nr 
FROM EMP
WHERE ENAME='SMITH';

SELECT *
FROM DBA_DATA_FILES
WHERE FILE_ID=7;
-- /u01/app/oracle/oradata/ullman/users01.dbf
-- 1484087
-- 1066283


-- -------------------------------------------------------
-- **************************************************************************
-- Compulsory exercise. Deadline: next practice
-- Don't send your solution to me, but check it with 'check_plsql' procedure (see below).
-- **************************************************************************
-- 5.
-- Write a PL/SQL procedure which prints out the number of rows in each data block for the 
-- following table: NIKOVITS.TABLA_123. (Output format:  file_id; block_id -> num_of_rows;
-- Output is sorted by file_id then by block_id.
-- CREATE OR REPLACE PROCEDURE num_of_rows IS 
-- ...
-- Test:
-- -----
SET SERVEROUTPUT ON
execute num_of_rows();

-- Check your solution with the following procedure:
execute check_plsql('num_of_rows()');

-- Hint:
-- List the extents of the table. You can find the first data block of the extent and the size of the extent (in blocks)
-- in DBA_EXTENTS. Check the individual data blocks, how many rows they contain. (--> ROWID helps you)

SELECT file_id, block_id, blocks
FROM dba_extents 
WHERE owner = 'NIKOVITS'
    AND segment_name = 'TABLA_123';


CREATE OR REPLACE PROCEDURE num_of_rows AUTHID CURRENT_USER IS
    v_count NUMBER;
BEGIN
    -- We loop through the metadata view to find EVERY block allocated to the table
    FOR r_ext IN (
        SELECT file_id, block_id, blocks 
        FROM dba_extents 
        WHERE owner = 'NIKOVITS' 
          AND segment_name = 'TABLA_123'
        ORDER BY file_id, block_id
    ) LOOP
        -- For every extent, we must visit every block from start_id to (start_id + size)
        FOR i IN 0 .. (r_ext.blocks - 1) LOOP
            
            -- Count how many rows exist in this specific file/block combo
            SELECT COUNT(*) INTO v_count 
            FROM NIKOVITS.TABLA_123
            WHERE DBMS_ROWID.ROWID_BLOCK_NUMBER(rowid) = r_ext.block_id + i
              AND DBMS_ROWID.ROWID_RELATIVE_FNO(rowid) = r_ext.file_id;
            
            -- Formatting must match exactly: file_id; block_id -> count;
            DBMS_OUTPUT.PUT_LINE(r_ext.file_id || '; ' || (r_ext.block_id + i) || ' -> ' || v_count || ';');
            
        END LOOP;
    END LOOP;
END;
/

SET SERVEROUTPUT ON;
execute num_of_rows;

SELECT COUNT(*)
FROM NIKOVITS.TABLA_123;

SELECT * FROM DBA_EXTENTS
WHERE OWNER='NIKOVITS' AND SEGMENT_NAME='TABLA_123';

DROP PROCEDURE num_of_rows;