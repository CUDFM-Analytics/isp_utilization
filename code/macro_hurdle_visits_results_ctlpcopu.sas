%macro results(pmodel=,vmodel=,dv=,pvar=,vvar=);

OPTIONS pageno=1 linesize=88 pagesize=60 SOURCE;
%LET root    = S:\FHPC\DATA\HCPF_Data_files_SECURE\Kim\fphc_ctlp\code\sas; 
%LET today   = %SYSFUNC(today(), YYMMDD10.);
%LET pdf     = &root.\results_hurdle_&dv._&today..pdf;

ODS PDF FILE = "&pdf" STARTPAGE = no;

TITLE "&dv";

proc odstext;
p "Probability DV: &pvar";
p "Visits DV: &vvar"; 
p ""; 
p "prob plm: ctlp.&pmodel";
p "visit plm: ctlp.&vmodel";
p "";
RUN; 

TITLE "&dv";

TITLE "Actual v Predicted"; 
PROC PRINT data = ctlp.&dv._avp; 
RUN;

Title "Means";
PROC MEANS data = ctlp.&dv._mean;
by   exposed;
var  p_prob p_visit a_visit; 
RUN;  

Title "Probability Model Parms";
PROC PLM RESTORE=ctlp.&dv._pmodel; show parms fit; RUN;

Title "Visit Model Parms"; 
PROC PLM RESTORE=ctlp.&dv._vmodel; show parms fit; RUN;

ODS PDF CLOSE; RUN; 
%mend;
