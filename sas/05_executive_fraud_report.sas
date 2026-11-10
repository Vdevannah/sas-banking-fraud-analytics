/* ==========================================
   SAS Banking Fraud Analytics
   Phase 5: Executive Fraud Analytics Report
   ==========================================

   Prerequisites:
     1. Run sas/00_setup.sas in this session (assigns FRAUD).
     2. Phase 4 has been run at least once, so these exist:
          FRAUD.CREDITCARD_RISK
          FRAUD.ALL_RULE_COMPARISON

   Output:
     /home/u64646496/sasuser.v94/phase5_executive_fraud_report.pdf
   ========================================== */

/* Start Phase 5 consolidated report */

ods pdf file="/home/u64646496/sasuser.v94/phase5_executive_fraud_report.pdf"
        style=journal;


/* Phase 5 - Step 1: Executive Fraud KPI Summary */

proc sql;
    create table work.executive_kpis as
    select
        count(*) as total_transactions,
        sum(fraud_flag = 1) as confirmed_fraud,
        sum(fraud_flag = 0) as legitimate_transactions,
        calculated confirmed_fraud /
            calculated total_transactions * 100
            as fraud_rate_pct format=8.3,
        sum(risk_flag = 1) as total_alerts,
        sum(risk_flag = 1 and fraud_flag = 1)
            as fraud_detected,
        sum(risk_flag = 1 and fraud_flag = 0)
            as false_alerts
    from fraud.creditcard_risk;
quit;

title1 "SAS Banking Fraud Analytics";
title2 "Executive Fraud Performance Report";

proc print data=work.executive_kpis noobs;
run;

title;


/* Phase 5 - Step 2: Detection Performance */

proc sql;
    create table work.executive_performance as
    select
        total_alerts,
        fraud_detected,
        false_alerts,

        fraud_detected / total_alerts * 100
            as precision_pct format=8.2,

        fraud_detected / confirmed_fraud * 100
            as recall_pct format=8.2,

        false_alerts / legitimate_transactions * 100
            as false_positive_rate_pct format=8.2

    from work.executive_kpis;
quit;

title "Fraud Detection Performance";

proc print data=work.executive_performance noobs;
run;

title;


/* Phase 5 - Step 3: Alert Outcome Visualization */

/* Create a dataset for the chart */
data work.alert_outcomes;
    set work.executive_kpis;

    length outcome $20;

    outcome = "True Positives";
    alert_count = fraud_detected;
    output;

    outcome = "False Positives";
    alert_count = false_alerts;
    output;

    keep outcome alert_count;
run;

/* Generate executive bar chart */
title "True Positive vs False Positive Alerts";

proc sgplot data=work.alert_outcomes;
    vbar outcome / response=alert_count
                   datalabel;
    xaxis label="Alert Outcome";
    yaxis label="Number of Alerts";
run;

title;


/* Phase 5 - Step 4: Rule Recall Comparison */

data work.rule_performance_chart;
    set fraud.all_rule_comparison;

    recall_pct = recall;
    precision_pct = precision;
run;

title "Fraud Detection Recall by Risk Rule";

proc sgplot data=work.rule_performance_chart;
    hbar rule_name / response=recall_pct
                     datalabel;
    xaxis label="Recall (%)";
    yaxis label="Fraud Detection Rule";
run;

title;


/* Phase 5 - Step 5: Executive Business Insights */

proc sql;
    create table work.business_insights as
    select
        total_alerts / total_transactions * 100
            as alert_rate_pct format=8.2,

        confirmed_fraud - fraud_detected
            as missed_fraud_cases,

        false_alerts / fraud_detected
            as false_alerts_per_detection format=8.1

    from work.executive_kpis;
quit;

title "Executive Business Insights";

proc print data=work.business_insights noobs;
run;

title;


/* Close Phase 5 consolidated report */

ods pdf close;


/* Phase 5 - Step 6: Save reporting datasets */

data fraud.executive_kpis;
    set work.executive_kpis;
run;

data fraud.executive_performance;
    set work.executive_performance;
run;

data fraud.alert_outcomes;
    set work.alert_outcomes;
run;

data fraud.rule_performance_chart;
    set work.rule_performance_chart;
run;

data fraud.business_insights;
    set work.business_insights;
run;
