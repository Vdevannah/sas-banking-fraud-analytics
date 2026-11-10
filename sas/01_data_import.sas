
/* =========================================
   SAS Banking Fraud Analytics
   Phase 1: Create Sample Transaction Data
   ========================================= */

/* Step 1: Create a transaction dataset */

data transactions;
    input transaction_id
          customer_id
          amount
          fraud_flag;

    datalines;
1001 101 250 0
1002 102 7800 1
1003 101 450 0
1004 103 12500 1
1005 102 300 0
1006 104 150 0
1007 105 9200 1
1008 103 600 0
1009 106 11000 1
1010 107 200 0
;
run;

/* Step 2: Display the dataset */

proc print data=transactions;
    title "Banking Transaction Dataset";
run;

/* Step 3: Calculate summary statistics */

proc means data=transactions
           n mean min max sum;
    var amount;
    title "Transaction Amount Statistics";
run;

/* Step 4: Count fraud and non-fraud records */

proc freq data=transactions;
    tables fraud_flag;
    title "Fraud Flag Distribution";
run;

title;
