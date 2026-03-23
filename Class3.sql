-- Compulsory
CREATE OR REPLACE PROCEDURE num_of_rows IS
    -- Associative array to hold the row counts in memory
    TYPE t_block_counts IS TABLE OF NUMBER INDEX BY VARCHAR2(50);
    v_counts t_block_counts;
    v_idx    VARCHAR2(50);
    v_rows   NUMBER;
BEGIN
    -- STEP 1: Get the actual row count per block currently holding data
    -- We use DBMS_ROWID to extract the Relative File Number and Block Number
    FOR r IN (
        SELECT DBMS_ROWID.ROWID_RELATIVE_FNO(rowid) AS rel_fno,
               DBMS_ROWID.ROWID_BLOCK_NUMBER(rowid) AS block_id,
               COUNT(*) AS cnt
        FROM NIKOVITS.TABLA_123
        GROUP BY DBMS_ROWID.ROWID_RELATIVE_FNO(rowid),
                 DBMS_ROWID.ROWID_BLOCK_NUMBER(rowid)
    ) LOOP
        -- Create a unique key (e.g., "4_1205") and store the count
        v_idx := r.rel_fno || '_' || r.block_id;
        v_counts(v_idx) := r.cnt;
    END LOOP;
    
    -- STEP 2: Loop through all allocated extents for the table
    FOR ext IN (
        SELECT file_id, relative_fno, block_id, blocks 
        FROM dba_extents 
        WHERE owner = 'NIKOVITS' 
          AND segment_name = 'TABLA_123'
        ORDER BY file_id, block_id
    ) LOOP
        -- STEP 3: Iterate through every single block inside the current extent
        FOR i IN 0 .. ext.blocks - 1 LOOP
            v_idx := ext.relative_fno || '_' || (ext.block_id + i);
            
            -- Check if our associative array has a count for this specific block
            IF v_counts.EXISTS(v_idx) THEN
                v_rows := v_counts(v_idx);
            ELSE
                v_rows := 0; -- The block is allocated but empty
            END IF;
            
            -- Print the output in the strictly required format
            DBMS_OUTPUT.PUT_LINE(ext.file_id || '; ' || (ext.block_id + i) || ' -> ' || v_rows || ';');
        END LOOP;
    END LOOP;
END;
/

execute check_plsql('num_of_rows()');

commit;