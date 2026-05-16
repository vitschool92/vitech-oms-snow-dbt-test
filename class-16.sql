select top 10 * from SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.CUSTOMER;

delete from SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.CUSTOMER;


select * from  OMS_DEV.BRONZE.ORDERS;


-- Step 1: Create share object
CREATE SHARE order_data_share
  COMMENT = 'Share order analytics with partner';

-- Step 2: Grant database access
GRANT USAGE ON DATABASE oms_dev TO SHARE order_data_share;

-- Step 3: Grant schema access
GRANT USAGE ON SCHEMA oms_dev.bronze TO SHARE order_data_share;

-- Step 4: Grant table permissions
GRANT SELECT ON TABLE oms_dev.bronze.orders TO SHARE order_data_share;
GRANT SELECT ON TABLE oms_dev.bronze.orders_v2 TO SHARE order_data_share;

-- Step 5: Verify share configuration
SHOW SHARES;
DESC SHARE order_data_share;

-- Add specific Snowflake account as consumer
ALTER SHARE order_data_share ADD ACCOUNTS = THAJKWT.VITECH_JOY_ACCOUNT;






delete from OMS_DEV.BRONZE.ORDERS  where quantity  < 5;








-- Create Reader Account --

CREATE MANAGED ACCOUNT vitech_joy_account
ADMIN_NAME = vitech_joy_admin,
ADMIN_PASSWORD = 'Test@123456789',
TYPE = READER;

// Show accounts
SHOW MANAGED ACCOUNTS;

--{"accountName":"VITECH_JOY_ACCOUNT","accountLocator":"MT85934","url":"https://thajkwt-vitech_joy_account.snowflakecomputing.com","accountLocatorUrl":"https://mt85934.central-india.azure.snowflakecomputing.com"}




---Consumer to read --open anothere browser with differet credentials 
-- Create database from share --  to verify the shares 

// Show all shares (consumer & producers)
SHOW SHARES;

// See details on share
DESC SHARE <account_name_producer>.ORDERS_SHARE;

// Create a database in consumer account using the share
CREATE DATABASE DATA_SHARE_DB FROM SHARE <account_name_producer>.ORDERS_SHARE;

// Validate table access
SELECT * FROM  DATA_SHARE_DB.PUBLIC.ORDERS



----------------------------------------
// Show all shares (consumer & producers)
SHOW SHARES;

// See details on share
DESC SHARE THAJKWT.PY97813.ORDER_DATA_SHARE;

// Create a database in consumer account using the share
CREATE DATABASE DATA_SHARE_DB FROM SHARE THAJKWT.PY97813.ORDER_data_SHARE;

// Validate table access
SELECT * FROM  DATA_SHARE_DB.bronze.ORDERS ;

delete from  DATA_SHARE_DB.bronze.ORDERS;


SELECT count(1) FROM  DATA_SHARE_DB.bronze.ORDERS ;


--------------------------------------------------------------

USE OMS_DEV;
USE ROLE ACCOUNTADMIN;


-- Prepare table --
create or replace table customers(
  id number,
  full_name varchar, 
  email varchar,
  phone varchar,
  spent number,
  create_date DATE DEFAULT CURRENT_DATE);

-- insert values in table --
insert into customers (id, full_name, email,phone,spent)
values
  (1,'Lewiss MacDwyer','lmacdwyer0@un.org','262-665-9168',140),
  (2,'Ty Pettingall','tpettingall1@mayoclinic.com','734-987-7120',254),
  (3,'Marlee Spadazzi','mspadazzi2@txnews.com','867-946-3659',120),
  (4,'Heywood Tearney','htearney3@patch.com','563-853-8192',1230),
  (5,'Odilia Seti','oseti4@globo.com','730-451-8637',143),
  (6,'Meggie Washtell','mwashtell5@rediff.com','568-896-6138',600);

select * from customers;
-- set up roles
CREATE OR REPLACE ROLE ANALYST_MASKED;
CREATE OR REPLACE ROLE ANALYST_FULL;

GRANT USAGE ON DATABASE OMS_DEV TO ROLE ANALYST_MASKED;
GRANT USAGE ON DATABASE OMS_DEV TO ROLE ANALYST_FULL;

-- grant select on table to roles
GRANT SELECT ON TABLE OMS_DEV.PUBLIC.CUSTOMERS TO ROLE ANALYST_MASKED;
GRANT SELECT ON TABLE OMS_DEV.PUBLIC.CUSTOMERS TO ROLE ANALYST_FULL;

GRANT USAGE ON SCHEMA OMS_DEV.PUBLIC TO ROLE ANALYST_MASKED;
GRANT USAGE ON SCHEMA OMS_DEV.PUBLIC TO ROLE ANALYST_FULL;

-- grant warehouse access to roles
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_MASKED;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_FULL;


-- assign roles to a user
GRANT ROLE ANALYST_MASKED TO USER VITECHSNOWDBT19;
GRANT ROLE ANALYST_FULL TO USER VITECHSNOWDBT19;


CREATE OR REPLACE SECURE VIEW OMS_DEV.PUBLIC.CUSTOMERS_VW AS
SELECT * FROM OMS_DEV.PUBLIC.CUSTOMERS;


GRANT SELECT ON view OMS_DEV.PUBLIC.CUSTOMERS_VW TO ROLE ANALYST_FULL;

select current_user() ;

-- Set up masking policy

create or replace masking policy phone 
    as (val varchar) returns varchar ->
            case        
            when current_role() in ('ANALYST_FULL', 'ACCOUNTADMIN') then val
            else '##-###-##'
            end;
  

-- Apply policy on a specific column 
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN phone 
SET MASKING POLICY PHONE;




-- Validating policies

USE ROLE ANALYST_FULL;
SELECT * FROM CUSTOMERS;

show views ;

USE ROLE ANALYST_MASKED;
SELECT * FROM CUSTOMERS;


show views;



-- replace policy

use role accountadmin;

create or replace masking policy names as (val varchar) returns varchar ->
            case
            when current_role() in ('ANALYST_FULL', 'ACCOUNTADMIN') then val
            else CONCAT(LEFT(val,2),'*******')
            end;

-- apply policy
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN full_name
SET MASKING POLICY names;


-- Validating policies
USE ROLE ANALYST_FULL;
SELECT * FROM CUSTOMERS;

USE ROLE ANALYST_MASKED;
SELECT * FROM CUSTOMERS;


-- Apply policy on a specific column 
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN phone 
UNSET MASKING POLICY;



------------------
--TASk----
--for masking the phone number as below for customer table 

**********9168
**********7120
**********3659 

SELECT * FROM CUSTOMERS;

SELECT encrypt(to_binary(hex_encode('secret!')), 'sample_passphrase', NULL, 'aes-cbc/pad:pkcs') as encrypted_data;


SELECT 
    full_name,
    email,
    phone,
    encrypt(
        to_binary(hex_encode(email)), 
        'sample_passphrase', 
        NULL, 
        'aes-cbc/pad:pkcs'
    ) AS encrypted_email
FROM CUSTOMERS;



SELECT 
    SHA2('hello', 224) AS sha224,
    SHA2('hello', 256) AS sha256,   -- most common
    SHA2('hello', 384) AS sha384,
    SHA2('hello', 512) AS sha512;


    -- ENCRYPT: store encrypted value + SHA-256 hash together
SELECT 
    full_name,
    email,
    phone,

    -- AES Encryption (reversible)
    encrypt(
        to_binary(hex_encode(email)),
        'sample_passphrase',
        NULL,
        'aes-cbc/pad:pkcs'
    ) AS encrypted_email,

    -- SHA-256 Hash (integrity check / fingerprint)
    SHA2(email, 256) AS email_hash

FROM CUSTOMERS;



CREATE OR REPLACE TABLE CUSTOMERS_SECURED AS
SELECT 
    full_name,
    phone,

    -- Encrypted (can decrypt later)
    encrypt(
        to_binary(hex_encode(email)),
        'sample_passphrase',
        NULL,
        'aes-cbc/pad:pkcs'
    ) AS encrypted_email,

    -- SHA-256 fingerprint (for verification)
    SHA2(email, 256) AS email_sha256

FROM CUSTOMERS;

-- Verify
SELECT * FROM CUSTOMERS_SECURED;

-------------------

SELECT 
    full_name,

    -- Step 1: Decrypt AES back to original email
    hex_decode_string(
        decrypt(
            encrypted_email,
            'sample_passphrase',
            NULL,
            'aes-cbc/pad:pkcs'
        )
    ) AS decrypted_email,

    -- Step 2: Re-hash decrypted value
    SHA2(
        hex_decode_string(
            decrypt(
                encrypted_email,
                'sample_passphrase',
                NULL,
                'aes-cbc/pad:pkcs'
            )
        ), 256
    ) AS decrypted_email_hash
FROM CUSTOMERS_SECURED;


SELECT 
    full_name,

    -- Step 1: Decrypt → cast BINARY to STRING → hex decode to original email
    hex_decode_string(
        CAST(
            decrypt(
                encrypted_email,
                'sample_passphrase',
                NULL,
                'aes-cbc/pad:pkcs'
            ) AS VARCHAR
        )
    ) AS decrypted_email,

    -- Step 2: Re-hash decrypted value
    SHA2(
        hex_decode_string(
            CAST(
                decrypt(
                    encrypted_email,
                    'sample_passphrase',
                    NULL,
                    'aes-cbc/pad:pkcs'
                ) AS VARCHAR
            )
        ), 256
    ) AS decrypted_email_hash

FROM CUSTOMERS_SECURED;

SELECT 
    full_name,

    -- Step 1: Decrypt → cast BINARY to STRING → hex decode to original email
    hex_decode_string(
        CAST(
            decrypt(
                encrypted_email,
                'sample_passphrase',
                NULL,
                'aes-cbc/pad:pkcs'
            ) AS VARCHAR
        )
    ) AS decrypted_email
    FROM CUSTOMERS_SECURED