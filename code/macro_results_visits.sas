%macro results_visits(dv=,          /* for proc plms (plural, ex: visits_pc) */
                      visittype=);  /* DV typefor plots to identify column (singular, ex: pc) */

OPTIONS pageno=1 linesize=88 pagesize=60 SOURCE;
%LET root    = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
               %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname))-6); *remove \Code\;

%LET script  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
               %length(%sysget(SAS_EXECFILEPATH))-4);

%LET today   = %SYSFUNC(today(), YYMMDD10.);
%LET pdf     = &root./code/&dv._&today..pdf;

ODS PDF FILE = "&pdf" STARTPAGE = no;

TITLE "&dv";

proc odstext;
p "DATE: &today";
p "Probability DV: ind_visit_&visittype";
p "Visit/Count DV: visits_&visittype";
p "";
RUN; 

TITLE "&dv";  

ods text = "PROB ESTIMATE FITS by corr structure";
ods text = "Type EXCH"; 
PROC PLM RESTORE=out.&dv._pmodel_exch noinfo noclprint; show fit; RUN;
ods text = "Prob Model Fit, type ind" ;
PROC PLM RESTORE=out.&dv._pmodel_ind noinfo noclprint; show fit; RUN;

ods text = "VISIT ESTIMATE FITS by corr type";
ods text = "type EXCH"; 
PROC PLM RESTORE=out.&dv._vmodel_exch noinfo noclprint; show fit; RUN; 
ods text = "type IND"; 
PROC PLM RESTORE=out.&dv._vmodel_ind noinfo noclprint; show fit; RUN; 

ods pdf startpage = now; 
TITLE "&dv Actual v Predicted Estimates by Corr Structure" ; 

ods text = "Actual v Predicted, Structure EXCH";
PROC PRINT data = out.&dv._avp_exch; RUN;
PROC MEANS data = out.&dv._mean_exch; by exposed; var p_prob p_visit a_visit; RUN;  

ods text = "Actual v Predicted, Structure IND";
PROC PRINT data = out.&dv._avp_ind; RUN;
PROC MEANS data = out.&dv._mean_ind; by   exposed; var  p_prob p_visit a_visit; RUN;  

ods pdf startpage = now; 
TITLE "&dv Decile Calibration Plots, Table"; 

* Create dataset with both types so you can sgpanel by type in plots below: ; 
DATA &dv._meanout_exch; SET out.&dv._meanout_exch; type = "exch"; RUN; 
DATA &dv._meanout_ind;  SET out.&dv._meanout_ind;  type = "ind";  RUN; 

DATA out.&dv._meanout;
SET  &dv._meanout_exch &dv._meanout_ind; 
DELTA = ind_visit_&visittype._Mean - pred_Mean;
RUN; 

* Plots (n=2); 
ods graphics / reset=all height = 3.5in width=7.5in;
ods text = "Plots, Corr Structure Exch";
proc sgpanel data = out.&dv._meanout;
styleattrs datacontrastcolors=(purple orange);
panelby type / spacing=15 ;
scatter x = predgroup y = pred_mean / markerattrs=(color=purple);
scatter x = predgroup y = ind_&dv._mean / markerattrs=(color=orange);
series x = predgroup y = pred_mean / break transparency=0.5 lineattrs=(color=purple);
series x = predgroup y = ind_&dv._mean / break transparency=0.5 lineattrs=(color=orange);
RUN; 

proc sgpanel data = out.&dv._meanout ;
styleattrs datacontrastcolors=(purple orange);
panelby type / spacing = 15; 
scatter x = pred_mean y = ind_&dv._mean;
lineparm x = 0 y = 0 slope = 1;
run;

ods text = "---";
ods text = "Decile Table"; 
ods text="---"; 
PROC PRINT DATA = out.&dv._meanout; RUN; 

ods pdf startpage = now;
TITLE "Model Parameters and Program, Type EXCH"; 
PROC PLM RESTORE=out.&dv._pmodel_exch noclprint; show parms program; RUN;
PROC PLM RESTORE=out.&dv._vmodel_exch noclprint; show parms program; RUN;

ods pdf startpage = now;
TITLE "Model Parameters and Program, Type IND"; 
PROC PLM RESTORE=out.&dv._pmodel_ind noclprint; show parms program; RUN;
PROC PLM RESTORE=out.&dv._vmodel_ind noclprint; show parms program; RUN;

ODS PDF CLOSE; RUN; 
%mend;
