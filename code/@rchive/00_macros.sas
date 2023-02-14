**********************************************************************************************
 PROGRAM NAME       : isp_utilization macros
 PROGRAMMER         : K Wiggins
 DATE OF CREATION   : 11 18 2022
 PROJECT            : isp utilization
 PURPOSE            : macros
 INPUT FILE(S)      : 
 OUTPUT FILE(S)     : 
***********************************************************************************************;

* for 00_getMembers file, get / keep ages; 
%macro keep_age(data     =,
                fy       =,      
                age_sfy  =);
data &data (keep=clnt_id &age_sfy &fy);
set  meddemog3;
where &fy = 1;
run;
%mend;
