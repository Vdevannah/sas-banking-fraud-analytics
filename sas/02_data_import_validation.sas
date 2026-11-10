/* ==========================================
   SAS Banking Fraud Analytics
   Phase 2: Import Credit Card Transactions
   ========================================== */

/* Step 1: Import the CSV file */
proc import
    datafile="/home/u64646496/sasuser.v94/creditcard.csv"
    out=work.creditcard_raw
    dbms=csv
    replace;
    getnames=yes;
    guessingrows=max;
run;

/* Step 2: Inspect dataset structure */
proc contents data=work.creditcard_raw;
    title "Credit Card Dataset Structure";
run;

/* Step 3: Display first 10 transactions */
proc print data=work.creditcard_raw(obs=10);
    var Time Amount Class;
    title "First 10 Credit Card Transactions";
run;

title;

/* Phase 2: Check missing numeric values */

proc means data=work.creditcard_raw
           n nmiss;
    var _numeric_;
    title "Missing Value Analysis";
run;

title;
/* Check fraud label distribution */

proc freq data=work.creditcard_raw;
    tables Class / missing;
    title "Fraud Label Distribution";
run;

title;

/* Phase 2: Convert fraud label to numeric */

data work.creditcard_clean;
    set work.creditcard_raw;

    fraud_flag = input(strip(Class), 8.);
run;

/* Verify numeric fraud indicator */
proc freq data=work.creditcard_clean;
    tables fraud_flag / missing;
    title "Numeric Fraud Flag Validation";
run;

title;

/* Phase 2: Check exact duplicate transactions */

proc sort data=work.creditcard_raw
          out=work.creditcard_unique
          nodupkey
          dupout=work.duplicate_records;
    by _all_;
run;

/* Count exact duplicate records */
proc sql;
    select count(*) as duplicate_count
    from work.duplicate_records;
quit;

title;

/* Phase 2: Validate transaction amounts */

proc sql;
    select
        count(*) as total_transactions,
        sum(case when Amount < 0 then 1 else 0 end)
            as negative_amounts,
        sum(case when Amount = 0 then 1 else 0 end)
            as zero_amounts,
        sum(case when missing(Amount) then 1 else 0 end)
            as missing_amounts
    from work.creditcard_clean;
quit;

/* Summary statistics for transaction amounts */
proc means data=work.creditcard_clean
           n mean median min max;
    var Amount;
    title "Transaction Amount Statistics";
run;

title;

/* Phase 2: Investigate zero-amount transactions */

proc sql;
    select
        fraud_flag,
        count(*) as transaction_count,
        sum(case when Amount = 0 then 1 else 0 end)
            as zero_amount_count,
        calculated zero_amount_count /
        calculated transaction_count * 100
            as zero_amount_pct format=8.2
    from work.creditcard_clean
    group by fraud_flag;
quit;

/* Final validation of numeric fraud labels */

proc sql;
    select
        count(*) as total_records,
        sum(case when missing(fraud_flag)
                 then 1 else 0 end) as missing_flags,
        sum(case when fraud_flag not in (0, 1)
                 then 1 else 0 end) as invalid_flags
    from work.creditcard_clean;
quit;