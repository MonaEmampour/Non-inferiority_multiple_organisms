/*********************************************************************
Program: Analysis_NI_Qual_MultiOrg.sas
Purpose: Non-inferiority test on accuracy with multiple microorganisms 
Remark: Supplementary material to paper:
Optimal spiking experiment for non-inferiority of qualitative
microbiological methods on accuracy with multiple microorganisms,
Journal of Statistics in Biopharmaceutical Research, 2021.
*********************************************************************/

%MACRO SIMULATION(SEED0=, SEED1=, SEED2=, SEED3=, SEED4=, SEED5=, SIM=,
                  NS=, MO=, DIST=, ALPHA=, BETA=, ETA=, LAMBDA=, T=, LAST=NO);

ODS NORESULTS;
OPTIONS NONOTES;
*-----------------------------------------------------------------------------;
* Import data;
*-----------------------------------------------------------------------------;
PROC IMPORT DATAFILE="D:\NI\theta=&T\Dist=&DIST(&ALPHA,&BETA)\lambda=&LAMBDA\m=&MO\cleaninput.csv"
  OUT=DROP DBMS=CSV REPLACE;
  GETNAMES=YES;
RUN;

DATA VALIDATION;
  SET DROP;
  KEEP SIM ORGANISM LAMBDA_HAT METHOD Y DP MEANRESP;
RUN;

*-----------------------------------------------------------------------------;
* Analysis for fixed detection proportions;
*-----------------------------------------------------------------------------;
ODS OUTPUT PARAMETERESTIMATES=PARMS;
PROC NLMIXED DATA=VALIDATION QPOINTS=20 ALPHA=0.10 DF=10000;
  PARMS %DO I=1 %TO &MO; DET&I=0.8 %END; THETA=0.8;
  %DO I=1 %TO &MO;
  IF ORGANISM=&I THEN DO;
    PC = 1-EXP(-DET&I.*LAMBDA_HAT);
    PR = 1-EXP(-THETA*DET&I.*LAMBDA_HAT);
  END;
  %END;
  P  = (METHOD="b'C'")*PC + (METHOD="b'R'")*PR;
  MODEL Y~BINARY(P);
  BY SIM;
RUN;

ODS OUTPUT PARAMETERESTIMATES=RECOVERY;
PROC NLMIXED DATA=VALIDATION QPOINTS=20 ALPHA=0.10 DF=10000;
  PARMS %DO I=1 %TO &MO; DET&I=0.8 %END; LOGTHETA=-0.1;
  %DO I=1 %TO &MO;
  IF ORGANISM=&I THEN DO;
    PC = 1-EXP(-DET&I.*LAMBDA_HAT);
    PR = 1-EXP(-EXP(LOGTHETA)*DET&I.*LAMBDA_HAT);
  END;
  %END;
  P  = (METHOD="b'C'")*PC + (METHOD="b'R'")*PR;
  MODEL Y~BINARY(P);
  BY SIM;
RUN;

ODS LISTING;

*-----------------------------------------------------------------------------;
* Results evaluation;
*-----------------------------------------------------------------------------;
DATA PARMS;
  SET PARMS;
  WHERE PARAMETER = 'THETA';
  NI = (LOWER>=0.7);
  KEEP SIM PARAMETER ESTIMATE NI;
RUN;

DATA RECOVERY;
  SET RECOVERY;
  WHERE PARAMETER = 'LOGTHETA';
  NI = (LOWER>=LOG(0.7));
  KEEP SIM PARAMETER ESTIMATE NI;
RUN;

DATA EQUIVALENCE;
  SET PARMS RECOVERY;
RUN;

ODS LISTING;
TITLE1 "DISTRIBUTION = &DIST";
TITLE2 "PARMS PROPORTIONS: A = &ALPHA, B = &BETA";
TITLE3 "MICROORGANISMS=&MO, SAMPLE SIZE = &NS, LAMBDA=&LAMBDA";
TITLE4 "LOG THETA = &ETA";
PROC MEANS DATA=EQUIVALENCE MEAN NOPRINT; 
  CLASS PARAMETER;
  VAR ESTIMATE NI;
  OUTPUT OUT=NEW(WHERE=(_TYPE_=1)) MEAN=ESTIM NONIN;
RUN;

DATA NEW;
  DIST="&DIST";
  ALPHA=&ALPHA;
  BETA=&BETA;
  ETA=&ETA;
  NS=&NS;
  MO=&MO;
  LAMBDA=&LAMBDA;
  SET NEW(DROP=_TYPE_ _FREQ_); 
  NONIN=100*NONIN; * Power in percent;
RUN;

ODS LISTING CLOSE;

PROC DELETE DATA= DROP VALIDATION PARMS RECOVERY EQUIVALENCE;
RUN;

ODS LISTING;

PROC APPEND BASE=RESULT NEW=NEW FORCE; RUN;

ODS EXCEL FILE="D:\NI\theta=&T\result.xlsx";

%IF &LAST=YES %THEN %DO;
  TITLE "Simulated power for non-inferiority of rapid vs compendial with multiple organisms";
  PROC PRINT DATA=RESULT;
    FORMAT ESTIM 7.3 NONIN 5.1;
  RUN;

  PROC DATASETS NOLIST; DELETE RESULT; RUN; QUIT;
%END;

PROC DELETE DATA=NEW;
RUN;

ODS EXCEL CLOSE;

%MEND SIMULATION;
