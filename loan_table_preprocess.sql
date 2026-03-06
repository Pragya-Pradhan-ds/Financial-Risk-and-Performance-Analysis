CREATE TABLE loans (
    id BIGINT,
    year INT,

    issue_d TEXT,
    final_d TEXT,

    emp_length_int NUMERIC,

    home_ownership TEXT,
    home_ownership_cat INT,

    income_category TEXT,
    annual_inc BIGINT,
    income_cat INT,

    loan_amount BIGINT,

    term TEXT,
    term_cat INT,

    application_type TEXT,
    application_type_cat INT,

    purpose TEXT,
    purpose_cat INT,

    interest_payments TEXT,
    interest_payment_cat INT,

    loan_condition TEXT,
    loan_condition_cat INT,

    interest_rate NUMERIC,

    grade TEXT,
    grade_cat INT,

    dti NUMERIC,
				
    total_pymnt NUMERIC,
    total_rec_prncp NUMERIC,

    recoveries NUMERIC,

    installment NUMERIC,

    region TEXT
);

select * from loans;
--A.Extract Phase (Data Loading & Verification)
--1. Display the first 10 records from the table to confirm successful loading.
select * from loans limit 10;
--2. Check the total number of records and distinct loan years.*/

select count(*) from loans;
select distinct year from  loans order by year asc;

/*List all unique values for key categorical variables like home_ownership, 
loan_condition, and purpose.*/

select distinct home_ownership from loans;
select distinct loan_condition from loans;
select distinct purpose from loans;

--Check number of columns.
SELECT COUNT(*)
FROM information_schema.columns
WHERE table_name = 'loans';
--B. Transform Phase (Data Cleaning & Feature Engineering)
/* 1. Identify missing or null values in critical columns 
(loan_amount, interest_rate, annual_inc, loan_condition, purpose).*/

select count(*) as missing_amount from loans where loan_amount is null;
select count(*) as missing_rate from loans where interest_rate is null;
select count(*) as missing_income from loans where annual_inc is null;
select count(*) as missing_condition from loans where loan_condition is null;
select count(*) as missing_purpose from loans where purpose is null;


/* 2. Replace missing income values with the median income of all borrowers.
Standardize categorical values — for example, convert all home_ownership 
entries to uppercase for consistency.*/

--in this dataset there is no missing values so no replacement
update loans set home_ownership=upper(home_ownership);
update loans set loan_condition=upper(loan_condition);
update loans set purpose=upper(purpose);

/* 3. Create a new column profitability that measures the difference between 
total_pymnt and loan_amount.*/
alter table loans add column profitability numeric;

update loans set profitability=(total_pymnt-loan_amount);

/* 4. Create a new column risk_flag based on the loan condition:
If loan_condition = ‘Bad Loan’ → risk_flag = 1
Else → risk_flag = 0*/

alter table loans add column risk_flag integer;
update loans set risk_flag=
case when loan_condition='GOOD LOAN' then 1 else 0 end;


--C. Load Preparation Phase (Data Structuring & Export Readiness)
/* 1. Create a new table loans_cleaned containing only cleaned and transformed records
(no nulls in key fields).*/

create table loans_cleaned as 
select * from loans where loan_amount is not null
  and interest_rate is not null
  and annual_inc is not null
  and loan_condition is not null
  and purpose is not null;

/*2. Add a default_rate_indicator column that computes the ratio of defaulted loans (Bad Loan)
to total loans within the same year.*/
alter table loans_cleaned add column default_rate_indicator numeric;

UPDATE loans_cleaned lc
SET default_rate_indicator = sub.default_rate
FROM (
    SELECT 
        year,
        round(COUNT(*) FILTER (WHERE loan_condition = 'BAD LOAN') * 1.0
        / COUNT(*),2) AS default_rate
    FROM loans_cleaned
    GROUP BY year
) sub
WHERE lc.year = sub.year;

select * from loans_cleaned;

--3. Extract loan term as numeric value (e.g., convert ‘36 months’ → 36).
select split_part(trim(term),' ',1) as term_numeric from loans_cleaned;

/*4. Add a new column income_to_loan_ratio calculated as the borrower’s
annual income divided by the loan amount. */

alter table loans_cleaned add column income_toloan_ratio numeric;

update loans_cleaned set income_toloan_ratio
=round(annual_inc::numeric/loan_amount::numeric,2);

select * from loans_cleaned;