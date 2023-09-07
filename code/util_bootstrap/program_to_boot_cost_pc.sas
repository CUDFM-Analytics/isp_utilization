**********************************************************************************************
AUTHOR   : Carter Sevick (adapted KW)
PROJECT  : ISP
PURPOSE  : define the bootstrap process to parallelize
VERSION  : 2023-08-24
HISTORY  : copied on 08-24-2023 from Carter/Examples/boot total cost/
CHANGES  :  -- [row 13] projRoot > %LET projRoot = S:\FHPC\DATA\HCPF_DATA_files_SECURE\Kim\isp\isp_utilization
            -- [row 20] add OPTIONS FMTSEARCH = (in)
            -- [row 73] prob model positive cost > ind_pc_cost
            -- [row 94] cost model DV > adj_pd_pc_tc
***********************************************************************************************;
%LET projRoot = S:\FHPC\DATA\HCPF_DATA_files_SECURE\Kim\isp\isp_utilization;

* location for bootstrap products ;
libname out "C:\Data\isp_utilization_cost_pc";
* location of input data to boot ;
libname in "&projRoot\data";
* get formats; 
OPTIONS FMTSEARCH=(in);

* data to boot ;
%let data = in.analysis;

* include macro programs;
%INCLUDE "&projRoot\code\util_bootstrap\MACRO_resample_V4.sas"; 

* get process parameters ;
** process number ;
%LET   i = %scan(&SYSPARM,1,%str( ));
** seed number ;
%LET   seed = %scan(&SYSPARM,2,%str( ));
** N bootstrap samples ;
%LET    N = %scan(&SYSPARM,3,%str( ));

* Draw bootstrap samples
Two new variables are added
1) bootUnit = the new subject identifier
2) replicate = identifies specific bootstrap samples
!!!!! the old ID variable is still included, BUT YOU CAN NOT USE IT IN THIS DATA FOR STATISTICS!!!!!!!!!!!;
ODS SELECT NONE;
%resample(data= &data
        , out = out._resample_out_&i
        , subject=mcaid_id
        , lightSort = YES
        , reps= &N
        , strata=int
        , seed=&seed
        , bootUnit=bootUnit
        , repName = replicate
        , samprate = (.5 .15)
);

/** save a copy of the booted data ;*/
/*DATA out._resample_out_&i; */
/*SET _resample_out_; */
/*RUN;*/

