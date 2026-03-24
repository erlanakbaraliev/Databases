-- 5. (10 points)    
-- Give the name and size (in bytes) of the partitioned tables of owner NIKOVITS where the table does not
-- have a column with datatype DATE. (Table_name, Size)
-- Be careful with the size, a partitioned table can have subpartitions!

SELECT T.TABLE_NAME, SUM(S.BYTES) AS SIZE_BYTES
FROM DBA_TABLES T
JOIN DBA_SEGMENTS S
ON T.OWNER=S.OWNER AND T.TABLE_NAME=S.SEGMENT_NAME
WHERE T.OWNER='NIKOVITS' 
AND   T.PARTITIONED='YES'
AND   T.TABLE_NAME NOT IN (
    SELECT TABLE_NAME
    FROM DBA_TAB_COLUMNS
    WHERE DATA_TYPE='DATE'
    AND   OWNER='NIKOVITS'
)
GROUP BY T.TABLE_NAME
ORDER BY SIZE_BYTES DESC;

-- 6. (10 points)
-- Write a PL/SQL function which returns in a character string the list of non-partitioned table names 
-- (comma separated list in alphabetical order) of owner NIKOVITS, where the table has a column of data type DATE,
-- and the table has at least four extents.

CREATE OR REPLACE TYPE string_list AS TABLE OF VARCHAR2(1000);
/

CREATE OR REPLACE FUNCTION extent4 RETURN VARCHAR2 IS
    v_result VARCHAR2(10000);
BEGIN
    FOR rec IN (
        SELECT TABLE_NAME
        FROM DBA_TABLES
        WHERE OWNER='NIKOVITS'
        AND   PARTITIONED='NO'
        AND   TABLE_NAME IN (
            SELECT TABLE_NAME
            FROM DBA_TAB_COLUMNS
            WHERE DATA_TYPE='DATE'
        )
        AND   TABLE_NAME IN (
            SELECT SEGMENT_NAME
            FROM DBA_SEGMENTS
            WHERE OWNER='NIKOVITS'
            GROUP BY SEGMENT_NAME
            HAVING SUM(EXTENTS) >= 4
        )
        ORDER BY TABLE_NAME
    ) LOOP
        IF v_result IS NOT NULL THEN
            v_result := v_result || ',';
        END IF;
        v_result := v_result || rec.table_name;
    END LOOP;

    RETURN v_result;
END;
/

SELECT extent4 FROM dual;
EXECUTE check_plsql('extent4()');


-- 7. (10 points)
-- Write a PL/SQL procedure which prints out the data blocks of table NIKOVITS.CUSTOMERS
-- in which the number of records is greater than 40. The output has 3 columns: File_id, Block_number
-- and the number of records within that block. Output is ordered by File_id, then Block_number.
-- Output values are terminated by semicolons --> 2;1334;41;...

-- CREATE OR REPLACE PROCEDURE gt_40 IS
-- ...
-- Run the following statements and send also the output:
-- set serveroutput on
-- EXECUTE gt_40();

-- You can check your program with the following:
-- EXECUTE check_plsql('gt_40()');

SELECT DBMS_ROWID.ROWID_RELATIVE_FNO(ROWID),
       DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID)
FROM emp;
-- 1066283

SELECT *
FROM dba_extents
WHERE OWNER='RTSUMV'
AND   SEGMENT_NAME='EMP';