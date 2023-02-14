**********************************************************************************************
 PROGRAM NAME		: mem_list_long
 PROGRAMMER			: K Wiggins
 DATE OF CREATION	: 11 28 2022
 PROJECT			: ISP
 PURPOSE			: create member lists
 INPUT FILE(S)		: out.mem_list
 OUTPUT FILE(S)		: out.mem_list_long
					  out.clntid_1819

***********************************************************************************************;
%include "S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/02_code/00_global.sas"; 


proc transpose data = out.mem_list out=mem_long (where=(Col1 = 1));
by clnt_id;
var fy1819--fy2122;
run; *10704656 when using where statement;

data out.mem_list_long (keep = clnt_id fy);
set  mem_long;
rename _name_ = fy;
run;

data out.clntid_1819 (keep = clnt_id);
set  out.mem_list_long;
where fy = "fy1819";
run;

proc sort data = out.clntid_1819 nodupkey;
by clnt_id; 
run; *no duplicates;

	*check; 
	proc freq data = out.mem_list;
	tables fy1819--fy2122;
	run;
	** RESULTS ** 
	Should total all the 1's summed  from below frequencies: PERFECT!!!
	*fy1819	1: 2,651,615
	 fy1920 1: 2,670,614 
	 fy2021 1: 2,685,956 
	 fy2122 1: 2,696,471 
	Total = 10704656 yay;
