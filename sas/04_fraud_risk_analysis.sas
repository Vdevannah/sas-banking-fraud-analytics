/* Start Phase 4 consolidated report */

ods pdf file="/home/u64646496/sasuser.v94/phase4_fraud_risk_report.pdf"
        style=journal;

/* ==========================================
   SAS Banking Fraud Analytics
   Phase 4 - Step 1: Fraud Risk Indicators
   ========================================== */

/* Create transaction-level risk indicators */

data work.creditcard_risk;
    set work.creditcard_clean;

    /* Rule 1: Zero-amount transactions */
    if Amount = 0 then risk_zero_amount = 1;
    else risk_zero_amount = 0;

    /* Rule 2: High-value transactions */
    if Amount >= 500 then risk_high_amount = 1;
    else risk_high_amount = 0;

    /* Rule 3: Elapsed hours 24-30 */
    if Time >= 86400 and Time < 108000
        then risk_time_window = 1;
    else risk_time_window = 0;

    /* Combined risk indicator */
    if risk_zero_amount = 1
       or risk_high_amount = 1
       or risk_time_window = 1
       then risk_flag = 1;
    else risk_flag = 0;

run;

/* Inspect risk indicator distributions */

proc freq data=work.creditcard_risk;
    tables risk_zero_amount
           risk_high_amount
           risk_time_window
           risk_flag;
    title "Fraud Risk Indicator Distribution";
run;

title;


/* Phase 4 - Step 2: Risk indicator performance */

/* Compare predicted risk with actual fraud labels */

proc freq data=work.creditcard_risk;
    tables risk_flag * fraud_flag /
           norow nocol nopercent;

    title "Combined Risk Flag vs Actual Fraud";
run;

title;

/* Calculate confusion matrix counts */

proc sql;
    select
        sum(case when risk_flag = 1
                      and fraud_flag = 1
                 then 1 else 0 end) as true_positive,

        sum(case when risk_flag = 1
                      and fraud_flag = 0
                 then 1 else 0 end) as false_positive,

        sum(case when risk_flag = 0
                      and fraud_flag = 1
                 then 1 else 0 end) as false_negative,

        sum(case when risk_flag = 0
                      and fraud_flag = 0
                 then 1 else 0 end) as true_negative

    from work.creditcard_risk;
quit;

/* Phase 4 - Step 3: Fraud Detection Metrics */

/* Count the four confusion matrix outcomes */

proc sql;
    create table work.fraud_metrics as
    select
        sum(risk_flag=1 and fraud_flag=1) as TP,
        sum(risk_flag=1 and fraud_flag=0) as FP,
        sum(risk_flag=0 and fraud_flag=1) as FN,
        sum(risk_flag=0 and fraud_flag=0) as TN
    from work.creditcard_risk;
quit;

/* Calculate performance metrics */

data work.fraud_performance;
    set work.fraud_metrics;

    precision = TP / (TP + FP) * 100;
    recall = TP / (TP + FN) * 100;
    false_positive_rate = FP / (FP + TN) * 100;
    accuracy = (TP + TN) / (TP + FP + FN + TN) * 100;

    format precision recall false_positive_rate accuracy 8.2;
run;

/* Display performance results */

proc print data=work.fraud_performance noobs;
    var TP FP FN TN
        precision recall
        false_positive_rate accuracy;

    title "Combined Fraud Risk Indicator Performance";
run;

title;

/* Phase 4 - Step 4: Compare Individual Risk Rules */

/* Convert risk indicators into long format */

data work.risk_rules_long;
    set work.creditcard_risk;

    length rule_name $25;

    rule_name = "Zero Amount";
    rule_flag = risk_zero_amount;
    output;

    rule_name = "High Amount";
    rule_flag = risk_high_amount;
    output;

    rule_name = "Elapsed Time Window";
    rule_flag = risk_time_window;
    output;

    keep rule_name rule_flag fraud_flag;
run;

/* Evaluate each individual rule */

proc sql;
    create table work.rule_comparison as
    select
        rule_name,

        sum(rule_flag) as total_alerts,

        sum(case when rule_flag=1 and fraud_flag=1
                 then 1 else 0 end) as TP,

        sum(case when rule_flag=1 and fraud_flag=0
                 then 1 else 0 end) as FP,

        sum(case when rule_flag=0 and fraud_flag=1
                 then 1 else 0 end) as FN,

        sum(case when rule_flag=0 and fraud_flag=0
                 then 1 else 0 end) as TN

    from work.risk_rules_long
    group by rule_name;
quit;

/* Calculate precision, recall and false-positive rate */

data work.rule_comparison;
    set work.rule_comparison;

    precision = TP / (TP + FP) * 100;
    recall = TP / (TP + FN) * 100;
    false_positive_rate = FP / (FP + TN) * 100;

    format precision recall false_positive_rate 8.2;
run;

/* Display individual rule performance */

proc print data=work.rule_comparison noobs;
    var rule_name total_alerts TP FP FN
        precision recall false_positive_rate;

    title "Individual Fraud Risk Rule Comparison";
run;

title;

/* Phase 4 - Step 5: Compare Rule Performance */

/* Add combined rule performance to comparison */

data work.all_rule_comparison;
    set work.rule_comparison;

    output;
run;

/* Append combined rule metrics */

data work.combined_rule;
    length rule_name $25;

    set work.fraud_performance;

    rule_name = "Combined Rule";
    total_alerts = TP + FP;

    keep rule_name total_alerts TP FP FN
         precision recall false_positive_rate;
run;

proc append base=work.all_rule_comparison
            data=work.combined_rule force;
run;

/* Convert metrics into long format for charting */

data work.rule_metrics_long;
    set work.all_rule_comparison;

    length metric $12;

    metric = "Precision";
    value = precision;
    output;

    metric = "Recall";
    value = recall;
    output;

    keep rule_name metric value;
run;

/* Plot precision and recall side by side */

proc sgplot data=work.rule_metrics_long;
    vbarparm category=rule_name response=value /
        group=metric
        groupdisplay=cluster
        datalabel;

    xaxis label="Fraud Risk Rule";
    yaxis label="Percentage (%)";

    title "Fraud Risk Rule Performance Comparison";
run;

title;


/* Close Phase 4 consolidated report */

ods pdf close;