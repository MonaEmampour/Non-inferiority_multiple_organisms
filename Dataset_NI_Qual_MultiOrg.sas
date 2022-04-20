/*********************************************************************
Program: Dataset_NI_Qual_MultiOrg.sas
Purpose: Generating data to demonstrate non-inferiority of qualitative
methods with multiple microorganisms 
Remark: Supplementary material to paper:
Optimal spiking experiment for non-inferiority of qualitative
microbiological methods on accuracy with multiple microorganisms,
Journal of Statistics in Biopharmaceutical Research, 2021.
*********************************************************************/

%MACRO SIMULATION(SEED0=, SEED1=, SEED2=, SEED3=, SEED4=, SEED5=, SIM=,
                  NS=, MO=, DIST=, ALPHA=, BETA=, ETA=, LAMBDA=, T=, LAST=NO);
ODS NORESULTS;
OPTIONS NONOTES;
LIBNAME RESULT "D:\NI\theta=&T\Dist=&DIST(&ALPHA,&BETA)\lambda=&LAMBDA\m=&MO";
*-----------------------------------------------------------------------------;
* Generate data;
*-----------------------------------------------------------------------------;
* Simulation data set with samples and their results in Compendial or Rapid method;
DATA SIMULATION;
  RETAIN ZAAD0 &SEED0 ZAAD1 &SEED1 ZAAD2 &SEED2 ZAAD3 &SEED3 ZAAD4 &SEED4 ZAAD5 &SEED5;

  DO SIM=1 TO &SIM BY 1;
    DO ORGANISM = 1 TO &MO BY 1;
      %IF &DIST=NORMAL %THEN %DO; * PC=EXP(U)/(1+EXP(U)) with U~N(mu,sigma^2)=N(alpha,beta^2);
        CALL RANNOR(ZAAD1,U);
        PC = EXP(&ALPHA+&BETA*U)/(1+EXP(&ALPHA+&BETA*U));
		PR = EXP(&ETA)*PC;
        DO SAMPLE = 1 TO &NS BY 1;
          CALL RANPOI(ZAAD2,&LAMBDA,XC); * True number of organisms per sample;
          CALL RANPOI(ZAAD3,&LAMBDA,XR);
          CALL RANUNI(ZAAD4,UC); * Define Pos/Neg result with detection probability;
          CALL RANUNI(ZAAD5,UR);
          YC = (UC <= 1-(1-PC)**XC);
          YR = (UR <= 1-(1-PR)**XR);
          OUTPUT;
        END;
      %END;
      %ELSE %DO; * PC~B(ALPHA,BETA);
        CALL RANUNI(ZAAD1,U);
        PC = BETAINV(U,&ALPHA,&BETA);
		PR = EXP(&ETA)*PC;
        DO SAMPLE = 1 TO &NS BY 1;
          CALL RANPOI(ZAAD2,&LAMBDA,XC);
          CALL RANPOI(ZAAD3,&LAMBDA,XR);
          CALL RANUNI(ZAAD4,UC);
          CALL RANUNI(ZAAD5,UR);
          YC = (UC <= 1-(1-PC)**XC);
          YR = (UR <= 1-(1-PR)**XR);
          OUTPUT;
        END;
      %END;
    END;
  END;
RUN;

* Mean true number of organisms in a sample per method (Compendial, Rapid);
PROC MEANS DATA=SIMULATION NOPRINT;
  VAR XC XR;
  OUTPUT OUT=DENSITY MEAN=DENC DENR;
  BY SIM ORGANISM;
RUN;

* Add mean true density of organisms in a sample over methods;
DATA EXPERIMENT;
  MERGE SIMULATION DENSITY;
  BY SIM ORGANISM;
  LAMBDA_HAT = (DENC + DENR)/2;
  KEEP SIM ORGANISM PC PR YC YR LAMBDA_HAT;
RUN;

* Put data for Compendial and Rapid method below each other;
DATA COMPENDIAL;
  SET EXPERIMENT;
  METHOD = "C";
  Y = YC;
  DP = PC;
  KEEP SIM ORGANISM DP METHOD Y LAMBDA_HAT;
RUN;

DATA RAPID;
  SET EXPERIMENT;
  METHOD = "R";
  Y = YR;
  DP = PR;
  KEEP SIM ORGANISM DP METHOD Y LAMBDA_HAT;
RUN;

DATA ANALYSIS;
  SET COMPENDIAL RAPID;
RUN;

PROC SORT DATA=ANALYSIS;
  BY SIM ORGANISM METHOD;
RUN;

* Average of response per organism per method;
PROC MEANS DATA=ANALYSIS;
  VAR Y;
  BY SIM ORGANISM LAMBDA_HAT METHOD;
  OUTPUT OUT=MEANY;
RUN;

DATA AVERAGE;
  SET MEANY;
  WHERE _STAT_= 'MEAN';
  MEANRESP=Y;
  DROP Y _FREQ_ _TYPE_ _STAT_;
RUN;

PROC SORT DATA=ANALYSIS;
  BY SIM ORGANISM LAMBDA_HAT METHOD;
RUN;

PROC SORT DATA=AVERAGE;
  BY SIM ORGANISM LAMBDA_HAT METHOD;
RUN;

DATA WHOLE;
  MERGE ANALYSIS AVERAGE;
  BY SIM ORGANISM LAMBDA_HAT METHOD;
RUN;

DATA RESULT.INPUT;
  SET WHOLE;
RUN;

PROC DELETE DATA=SIMULATION DENSITY EXPERIMENT COMPENDIAL RAPID ANALYSIS MEANY AVERAGE WHOLE;
RUN;

%MEND SIMULATION;
