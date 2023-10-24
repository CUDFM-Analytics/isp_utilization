%macro results_visits(pmodel=,vmodel=,dv=,prob_dv=,visit_dv=);

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
p "Probability DV: &prob_dv";
p "Visit/Count DV: &visit_dv";
p "";
p "prob model plm: out.&pmodel";
p "visit model plm: out.&vmodel";
p "";
RUN; 

TITLE "&dv";  

TITLE "Actual v Predicted"; 
PROC PRINT data = out.&dv._avp; 
RUN;

Title "Means";
PROC MEANS data = out.&dv._mean;
by   exposed;
var  p_prob p_visit a_visit; 
RUN;  

Title "Probability Model Parms";
PROC PLM RESTORE=out.&pmodel; show parms; RUN;

Title "Visit Model Parms"; 
PROC PLM RESTORE=out.&vmodel; show parms; RUN;

ODS PDF CLOSE; RUN; 
%mend;
