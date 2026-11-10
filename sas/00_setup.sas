/* ==========================================
   SAS Banking Fraud Analytics
   Phase 0: Session Setup
   ==========================================

   Run this script at the start of EVERY SAS Studio session
   (LIBNAME assignments end when SAS Studio logs out; the
   datasets stored in the library do not).

   Permanent library FRAUD
   -----------------------
   Holds the datasets that later phases depend on, so they
   survive between sessions:

     Dataset                    Written by   Read by
     -------------------------  -----------  ---------
     FRAUD.CREDITCARD_CLEAN     Phase 2      Phase 4
     FRAUD.CREDITCARD_RISK      Phase 4      Phase 5
     FRAUD.ALL_RULE_COMPARISON  Phase 4      Phase 5

   Run order
   ---------
   First time (or to rebuild everything):
     00_setup -> 02 -> 03 -> 04 -> 05

   Any later session (e.g. after SAS Studio logs out):
     00_setup -> 05      (regenerate the executive report)
     00_setup -> 04      (re-run the risk rules)

   Update the path below if your SAS home directory differs.
   ========================================== */

libname fraud "/home/u64646496/sasuser.v94";

/* Optional: Phase 3 reads WORK.CREDITCARD_CLEAN. To re-run
   Phase 3 in a new session without repeating Phase 2,
   uncomment the step below to restore the WORK copy. */

/*
data work.creditcard_clean;
    set fraud.creditcard_clean;
run;
*/

/* List what is currently stored in the permanent library */
proc datasets library=fraud nolist;
    contents data=_all_ memtype=data nods;
run;
quit;
