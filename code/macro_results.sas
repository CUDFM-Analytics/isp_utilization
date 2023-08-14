%macro results(pmodel=,cmodel=,dv=);

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
p "DV: &dv";
p "prob model plm: out.&pmodel";
p "cost model plm: out.&cmodel";
p "";
RUN; 

TITLE "&dv";

TITLE "Actual v Predicted"; 
PROC PRINT data = out.&dv._avp; 
RUN;

Title "Means";
PROC MEANS data = out.&dv._meancost;
by   exposed;
var  p_prob p_cost a_cost; 
RUN;  

Title "Probability Model Parms";
PROC PLM RESTORE=out.&dv._pmodel; show parms; RUN;

Title "Cost Model Parms"; 
PROC PLM RESTORE=out.&dv._cmodel; show parms; RUN;

ODS PDF CLOSE; RUN; 
%mend;
