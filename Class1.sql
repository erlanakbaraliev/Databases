-- Database objects
-- 1. Who is the owner of table DUAL? 
SELECT OWNER
FROM DBA_TABLES
WHERE TABLE_NAME='DUAL';

-- 2.
-- Who is the owner and what is the object type of DBA_TABLES? (owner, object_type)
SELECT OBJECT_NAME, OWNER, OBJECT_TYPE
FROM DBA_OBJECTS
WHERE object_name='DBA_TABLES';

-- 3.
-- What kind of objects does the ORAUSER database user have? (dba_objects.object_type column)
SELECT DISTINCT OBJECT_TYPE
FROM DBA_OBJECTS
WHERE OWNER='ORAUSER';

-- 4.
-- What are the object types existing in the database?
SELECT DISTINCT object_type
FROM DBA_OBJECTS
ORDER BY OBJECT_TYPE;

-- 5.
-- Which users have more than 10 different kind of objects in the database?
SELECT OWNER, COUNT(DISTINCT OBJECT_TYPE)
FROM DBA_OBJECTS
GROUP BY OWNER
HAVING COUNT(DISTINCT OBJECT_TYPE) > 10
ORDER BY COUNT(DISTINCT OBJECT_TYPE) DESC;

-- 6.
-- Which users have both triggers and views in the database?
SELECT OWNER FROM DBA_OBJECTS WHERE OBJECT_TYPE='TRIGGER'
INTERSECT
SELECT OWNER FROM DBA_OBJECTS WHERE OBJECT_TYPE='VIEW';

-- 7.
-- Which users have views but no triggers?
SELECT OWNER FROM DBA_OBJECTS WHERE OBJECT_TYPE='VIEW'
MINUS
SELECT OWNER FROM DBA_OBJECTS WHERE OBJECT_TYPE='TRIGGER';

-- 8.
-- Which users have more than 20 tables, but less than 15 indexes?
select * from (
        SELECT OWNER
        FROM DBA_OBJECTS
        WHERE OBJECT_TYPE='TABLE'
        GROUP BY OWNER
        HAVING COUNT(*) > 20
    MINUS
        SELECT OWNER
        FROM DBA_OBJECTS
        WHERE OBJECT_TYPE='INDEX'
        GROUP BY OWNER
        HAVING COUNT(*) > 15
);
    -- SELECT OWNER
    -- FROM DBA_OBJECTS
    -- WHERE OBJECT_TYPE='TABLE'
    -- GROUP BY OWNER
    -- HAVING COUNT(*) >= 20
    -- INTERSECT
    -- SELECT OWNER
    -- FROM DBA_OBJECTS
    --     WHERE OBJECT_TYPE='INDEX'
    -- GROUP BY OWNER
    -- HAVING COUNT(*) <= 15;

-- 10.
-- Which object types have NULL (or 0) in the column data_object_id?
SELECT distinct object_type
FROM DBA_OBJECTS
WHERE data_object_id IS NULL;

-- 11.
-- Which object types have non NULL (and non 0) in the column data_object_id?
SELECT distinct object_type
FROM DBA_OBJECTS
WHERE data_object_id IS NOT NULL;

-- 12.
-- What is the intersection of the previous 2 queries?
SELECT distinct object_type
FROM DBA_OBJECTS
WHERE data_object_id IS NULL
INTERSECT
SELECT distinct object_type
FROM DBA_OBJECTS
WHERE data_object_id IS NOT NULL;

-- ------------------
-- Columns of a table
-- ------------------

-- 13.
-- How many columns does the nikovits.emp table have?
SELECT COUNT(*)
FROM dba_tab_columns
WHERE OWNER='NIKOVITS' AND TABLE_NAME='EMP';

-- 14.
-- What is the data type of the 6th column of nikovits.emp's table?
SELECT *
FROM DBA_TAB_COLUMNS
WHERE OWNER='NIKOVITS' AND TABLE_NAME='EMP' AND COLUMN_ID=6;

-- 15.
-- Give the owner and name of the tables which have column name beginning with letter 'Z'.
SELECT DISTINCT OWNER, TABLE_NAME
FROM DBA_TAB_COLUMNS
WHERE TABLE_NAME LIKE 'Z%'
ORDER BY OWNER;

-- 16.
-- Give the owner and name of the tables which have at least 8 columns with data type DATE.
SELECT OWNER, TABLE_NAME, COUNT(*)
FROM DBA_TAB_COLUMNS
WHERE DATA_TYPE='DATE'
GROUP BY TABLE_NAME, OWNER
HAVING COUNT(*)>=8
ORDER BY COUNT(*) DESC;

-- 17
-- Give the owner and name of the tables whose 1st and 4th column's datatype is VARCHAR2.
SELECT OWNER, TABLE_NAME
FROM DBA_TAB_COLUMNS
WHERE column_id=1 AND DATA_TYPE='VARCHAR2'
INTERSECT
SELECT OWNER, TABLE_NAME
FROM DBA_TAB_COLUMNS
WHERE column_id=4 AND DATA_TYPE='VARCHAR2';

-- 18.
-- Write a PL/SQL procedure, which prints out the owners and names of the tables beginning with the 
-- parameter character string. 
CREATE OR REPLACE PROCEDURE table_print(p_char VARCHAR2) IS
BEGIN
    FOR r IN (
        SELECT OWNER, TABLE_NAME
        FROM DBA_TABLES
        WHERE TABLE_NAME LIKE UPPER(p_char) || '%'
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(r.owner || ' - ' || r.table_name);
    END LOOP;
END;
/
SET serveroutput ON
execute table_print('E');

CREATE OR REPLACE PROCEDURE table_print(p_table_name VARCHAR2) is
    CURSOR curs1 is
    SELECT owner, table_name 
    FROM DBA_TABLES
    WHERE UPPER(TABLE_NAME) LIKE UPPER(p_table_name) || '%';
    rec curs1%ROWTYPE;
BEGIN
    OPEN curs1;
    LOOP
        FETCH curs1 INTO rec;
        EXIT WHEN curs1%NOTFOUND;
        dbms_output.put_line(rec.owner || ' - ' || rec.table_name);
    END LOOP;
    CLOSE curs1;
END;
/
set serveroutput on
execute table_print('V');

-- 19.
-- Write a PL/SQL function, which gets a username as the parameter and returns the first table or view of the user
-- in alphabetical order, which has a column with datatype DATE, but doesn't have a column with datatype NUMBER. 
-- parameter character string. 
-- CREATE OR REPLACE FUNCTION first_tab_view(p_owner VARCHAR2) RETURN VARCHAR2 IS 
-- ...
-- Test the function:
-- SELECT first_tab_view('nikovits') FROM dual;
-- SELECT first_tab_view('bubu') FROM dual;

CREATE OR REPLACE FUNCTION first_tab_view2(p_owner VARCHAR2) RETURN VARCHAR2 IS
    v_name VARCHAR2(100);
BEGIN
    SELECT OBJECT_NAME INTO v_name
    FROM DBA_OBJECTS
    WHERE
        OWNER LIKE '%' || p_owner || '%'
        AND OBJECT_TYPE IN ('TABLE', 'VIEW')
        AND OBJECT_NAME IN (
            SELECT TABLE_NAME
            FROM DBA_TAB_COLUMNS
            WHERE DATA_TYPE='DATE'
            MINUS
            SELECT TABLE_NAME
            FROM DBA_TAB_COLUMNS
            WHERE DATA_TYPE='NUMBER'
        )
    ORDER BY OBJECT_NAME
    FETCH FIRST 1 ROW ONLY;

    RETURN v_name;
END;
/
SET SERVEROUTPUT ON;
SELECT first_tab_view2('NIKOVITS') 
FROM DUAL;