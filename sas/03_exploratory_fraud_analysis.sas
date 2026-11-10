/* Start Phase 3 consolidated report */

ods pdf file="/home/u64646496/sasuser.v94/phase3_exploratory_fraud_report.pdf"
        style=journal;

/* Phase 3: Verify cleaned dataset */

proc contents data=work.creditcard_clean;
run;

/* Phase 3 - Step 1: Fraud vs Nonfraud Comparison */

proc means data=work.creditcard_clean
           n mean median min max std
           maxdec=2;
    class fraud_flag;
    var Amount;
    title "Transaction Amount Statistics by Fraud Status";
run;

title;

/* Phase 3 - Step 2: Create transaction amount bands */

data work.creditcard_bands;
    set work.creditcard_clean;

    length amount_band $20;

    if Amount = 0 then amount_band = "1. Zero";
    else if Amount < 10 then amount_band = "2. Under $10";
    else if Amount < 50 then amount_band = "3. $10-$49";
    else if Amount < 100 then amount_band = "4. $50-$99";
    else if Amount < 500 then amount_band = "5. $100-$499";
    else amount_band = "6. $500+";
run;

/* Calculate fraud rates by amount band */

proc sql;
    select
        amount_band,
        count(*) as total_transactions,
        sum(fraud_flag) as fraud_transactions,
        calculated fraud_transactions /
        calculated total_transactions * 100
            as fraud_rate_pct format=8.3
    from work.creditcard_bands
    group by amount_band
    order by amount_band;
quit;

/* Phase 3 - Step 3: Visualize fraud rate by amount band */

/* Create summary dataset for plotting */
proc sql;
    create table work.fraud_by_amount as
    select
        amount_band,
        count(*) as total_transactions,
        sum(fraud_flag) as fraud_transactions,
        calculated fraud_transactions /
        calculated total_transactions * 100
            as fraud_rate_pct
    from work.creditcard_bands
    group by amount_band;
quit;

/* Create fraud rate bar chart */
proc sgplot data=work.fraud_by_amount;
    vbar amount_band /
        response=fraud_rate_pct
        datalabel;

    xaxis label="Transaction Amount Range";
    yaxis label="Fraud Rate (%)";

    title "Fraud Rate by Transaction Amount Range";
run;

title;

/* Phase 3 - Step 4: Analyze transaction timing */

/* Create six-hour elapsed-time intervals */

data work.creditcard_time;
    set work.creditcard_clean;

    time_block = floor(Time / 21600);

    length time_label $20;
    time_label = cats(
        put(time_block * 6, 3.),
        "-",
        put((time_block + 1) * 6, 3.),
        " elapsed hours"
    );
run;

/* Calculate fraud rates by elapsed-time interval */

proc sql;
    select
        time_block,
        count(*) as total_transactions,
        sum(fraud_flag) as fraud_transactions,
        calculated fraud_transactions /
        calculated total_transactions * 100
            as fraud_rate_pct format=8.3
    from work.creditcard_time
    group by time_block
    order by time_block;
quit;

/* Phase 3 - Step 5: Fraud rate over elapsed time */

/* Create summary dataset */
proc sql;
    create table work.fraud_by_time as
    select
        time_block,
        count(*) as total_transactions,
        sum(fraud_flag) as fraud_transactions,
        calculated fraud_transactions /
        calculated total_transactions * 100
            as fraud_rate_pct
    from work.creditcard_time
    group by time_block
    order by time_block;
quit;

/* Visualize fraud rate across time blocks */
proc sgplot data=work.fraud_by_time;
    series x=time_block y=fraud_rate_pct /
        markers
        datalabel;

    xaxis label="Six-Hour Elapsed-Time Block"
          integer;

    yaxis label="Fraud Rate (%)";

    title "Fraud Rate Across Transaction Timeline";
run;

title;

/* Close Phase 3 consolidated report */

ods pdf close;