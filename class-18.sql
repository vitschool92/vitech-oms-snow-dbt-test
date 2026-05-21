CREATE OR REPLACE TABLE oms_dev.bronze.customer (
    cid INT,
    cname VARCHAR(20),
    city VARCHAR(10),
    phone VARCHAR(10)
);

INSERT INTO oms_dev.bronze.customer (cid, cname, city, phone) VALUES
(1011, 'Alice', 'New York', '5551001'),
(2011, 'Bob', 'Chicago', '5551002'),
(3011, 'Charlie', 'Houston', '5551003'),
(4011, 'Diana', 'Phoenix', '5551004'),
(5011, 'Edward', 'Dallas', '5551005');


select * from oms_dev.bronze.customer;

delete from oms_dev.bronze.customer where cid = 301;

update  oms_dev.bronze.customer 
        set city = 'blr'  where cid = 101;

select * from oms_dev.silver.customer_tgt ;




CREATE OR REPLACE TABLE oms_dev.silver.customer_tgt (
    cid INT,
    cname VARCHAR(20),
    city VARCHAR(10),
    phone VARCHAR(10)
);


CREATE or replace TABLE oms_dev.silver.customer_tgt  clone oms_dev.bronze.customer;


select * from oms_dev.silver.customer_tgt ;


---------------------------------------------------stream--

---CREATE STREAM 
CREATE OR REPLACE STREAM OMS_DEV.BRONZE.CUST_STREAM ON TABLE oms_dev.bronze.customer;


SELECT * FROM OMS_DEV.BRONZE.CUST_STREAM ;


MERGE INTO oms_dev.silver.customer_tgt AS tgt
USING oms_dev.bronze.cust_stream AS src
ON tgt.cid = src.cid
WHEN NOT MATCHED AND src.METADATA$ACTION = 'INSERT' THEN
    INSERT (cid, cname, city, phone)
    VALUES (src.cid, src.cname, src.city, src.phone);

    
select * from oms_dev.silver.customer_tgt ;




CREATE OR REPLACE TASK oms_dev.bronze.cust_task
WAREHOUSE = COMPUTE_WH
SCHEDULE = '1 MINUTE'
WHEN SYSTEM$STREAM_HAS_DATA('OMS_DEV.BRONZE.CUST_STREAM')
AS
MERGE INTO oms_dev.silver.customer_tgt AS tgt
USING oms_dev.bronze.cust_stream AS src
ON tgt.cid = src.cid
WHEN NOT MATCHED AND src.METADATA$ACTION = 'INSERT' THEN
    INSERT (cid, cname, city, phone)
    VALUES (src.cid, src.cname, src.city, src.phone);


show tasks ;

ALTER TASK oms_dev.bronze.cust_task RESUME;

ALTER TASK oms_dev.bronze.cust_task SUSPEND;



select * from oms_dev.silver.customer_tgt ;



-----------------------------incremental load 
CREATE OR REPLACE TASK oms_dev.bronze.cust_task
WAREHOUSE = COMPUTE_WH
SCHEDULE = '1 MINUTE'
WHEN SYSTEM$STREAM_HAS_DATA('OMS_DEV.BRONZE.CUST_STREAM')
AS
MERGE INTO oms_dev.silver.customer_tgt AS tgt
USING oms_dev.bronze.cust_stream AS src
ON tgt.cid = src.cid
WHEN MATCHED AND src.METADATA$ACTION = 'DELETE' THEN
    DELETE
WHEN MATCHED AND src.METADATA$ACTION = 'INSERT' AND src.METADATA$ISUPDATE = TRUE THEN
    UPDATE SET tgt.cname = src.cname, tgt.city = src.city, tgt.phone = src.phone
WHEN NOT MATCHED AND src.METADATA$ACTION = 'INSERT' THEN
    INSERT (cid, cname, city, phone)
    VALUES (src.cid, src.cname, src.city, src.phone);



    select * from oms_dev.silver.customer_tgt ;



---task -----

CREATE OR REPLACE TASK oms_dev.bronze.emp_task 
WAREHOUSE = COMPUTE_WH
SCHEDULE = 'USING CRON */30 * * * * UTC'
AS 
DELETE FROM employee WHERE status = 'inactive';



CREATE OR REPLACE TASK oms_dev.bronze.emp_task 
WAREHOUSE = COMPUTE_WH
SCHEDULE = 'USING CRON */2 * * * * UTC'
AS 
DELETE FROM employee WHERE status = 'inactive';