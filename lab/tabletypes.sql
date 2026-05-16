




CREATE DATABASE  OMS_DEV;

CREATE SCHEMA BRONZE ;


CREATE SCHEMA SILVER ;


CREATE SCHEMA GOLD ;





CREATE OR REPLACE STAGE vitech_dev.LOANS.LOAN_STAGE1
  URL = 's3://bucketsnowflakes3';


  list @vitech_dev.LOANS.LOAN_STAGE1 ;


  



  --s3 url --- s3://bucketsnowflakes3/OrderDetails.csv
  ---ddl
  CREATE  or replace  TABLE OMS_DEV.bronze.ORDERS (
    ORDER_ID VARCHAR(30),
    AMOUNT INT,
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));


    show tables ;



  CREATE  transient TABLE OMS_DEV.bronze.ORDERS_v2 (
    ORDER_ID VARCHAR(30),
    AMOUNT INT,
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));




    CREATE  TEMPORARY TABLE OMS_DEV.bronze.ORDERS_TEMP (
    ORDER_ID VARCHAR(30),
    AMOUNT INT,
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));




    COPY INTO OMS_DEV.bronze.ORDERS 
    FROM @vitech_dev.LOANS.LOAN_STAGE1
    FILE_FORMAT=(TYPE=CSV , SKIP_HEADER=1)
    PATTERN = '.*OrderDetails.*csv' 
    force=true ;


    
    COPY INTO OMS_DEV.bronze.ORDERS_v2 
    FROM @vitech_dev.LOANS.LOAN_STAGE1
    FILE_FORMAT=(TYPE=CSV , SKIP_HEADER=1)
    PATTERN = '.*OrderDetails.*csv' ;


        
    COPY INTO OMS_DEV.bronze.ORDERS_TEMP 
    FROM @vitech_dev.LOANS.LOAN_STAGE1
    FILE_FORMAT=(TYPE=CSV , SKIP_HEADER=1)
    PATTERN = '.*OrderDetails.*csv' ;



    select * from OMS_DEV.bronze.ORDERS ;

    select * from OMS_DEV.bronze.ORDERS_v2; 

    select * from OMS_DEV.bronze.ORDERS_TEMP;



  create temporary table OMS_DEV.bronze.orders_sales_temp  as
  (
     select * from orders 
       where profit < 0 
  ) ;


   select * from  OMS_DEV.bronze.orders_sales_temp;

   show tables ;


CREATE OR REPLACE EXTERNAL TABLE OMS_DEV.bronze.ORDERS_EXT (
    ORDER_ID VARCHAR(30) AS (VALUE:c1::VARCHAR(30)),
    AMOUNT INT AS (VALUE:c2::INT),
    PROFIT INT AS (VALUE:c3::INT),
    QUANTITY INT AS (VALUE:c4::INT),
    CATEGORY VARCHAR(30) AS (VALUE:c5::VARCHAR(30)),
    SUBCATEGORY VARCHAR(30) AS (VALUE:c6::VARCHAR(30))
)
WITH LOCATION = @VITECH_DEV.LOANS.LOAN_STAGE1
FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1)
PATTERN = '.*OrderDetails.*csv';


SELECT * FROM OMS_DEV.bronze.ORDERS_EXT;


select category,count(*) from  OMS_DEV.bronze.ORDERS_EXT
group by category ;




 select * from OMS_DEV.bronze.ORDERS ;

  delete from OMS_DEV.bronze.ORDERS where quantity < 10 ;

select category, sum(quantity)
from OMS_DEV.bronze.ORDERS 
      group by category 
      order by 2 ;


 --945  1154  3516 

create or replace table  oms_dev.silver.cat_sum as (
 select category, sum(quantity) as total_cnt
from OMS_DEV.bronze.ORDERS 
      group by category 
      order by 2 
)
;


select * from oms_dev.silver.cat_sum  ;




create or replace dynamic table oms_dev.silver.category_agg
  target_lag = '1 minute'
  warehouse = COMPUTE_WH
as
  select category, sum(quantity) as total_cnt
  from OMS_DEV.bronze.ORDERS
  group by category;

  
select * from  oms_dev.silver.category_agg ;   --1756 607 536 




--TASK 
--CREATE WITH SAME NAME AS ALL THE TABLE TYPES MAINLY PERMANENT /TRANSIENT /TEMP ??
--EMPLOYEES    FOR ALL 3 ?? 
-- IF POSSIBLE LOAD DATA AND OBSERVE AND SIGNOUT AND SIG IN  
-- HOW MANY RECORDS ??
---CAN WE CREATE TEMP TABLE / PERMANNET TABLE AS SAME NAME ??
--IF YES WHICH ONE WILL TAKE PRIORITY ??


