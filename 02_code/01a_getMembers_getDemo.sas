**********************************************************************************************
 PROGRAM NAME       : ISP Utilization
 PROGRAMMER         : K Wiggins
 DATE OF CREATION   : 08 18 2022
 PROJECT            : ISP
 PURPOSE            : Get client ID's for members 0-64 in SFY's 18/19 through 21/22
 INPUT FILE(S)      : 
 OUTPUT FILE(S)     : 
 ABBREV             : bhjt, hcpf (include bdmconnect file has varlen)

 MODIFICATION HISTORY:
 Date       Author      Description of Change
 --------   -------     -----------------------------------------------------------------------
 08/18/22   KTW         Copied this from 00_ISP_Counts in NPI_Matching - Documents
 09/13/22   KTW         Ran;

* global paths, settings  ---------------------------;
  %include "S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/02_code/00_global.sas"; 
  %include "S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/02_code/00_macros.sas"; 
  *use age range; 
* Includes formats, connect to bdm, setting libnames, options, bhjt, varlen;


***********************************************************************************************;
*Init: Sept 2022;

data meddemog1; set bhjt.medicaiddemog_bidm; run; *2,991,591, 7 (same 11/18);  

* Create age variable with clnt_id and dob - LATER merge back with meddemog1 for gender, county, rethnic_hcpf;
data meddemog2 (keep=clnt_id dob );
set  meddemog1;
run; * dropped to 5 variables; 

* Get age from meddemog;
data meddemog3;
set  meddemog2;
age_sfy1819 = floor((intck('month', dob, '01Jul2018'd) - (day('01Jul2018'd) < day(dob))) / 12); 
age_sfy1920 = floor((intck('month', dob, '01Jul2019'd) - (day('01Jul2019'd) < day(dob))) / 12); 
age_sfy2021 = floor((intck('month', dob, '01Jul2020'd) - (day('01Jul2020'd) < day(dob))) / 12); 
age_sfy2122 = floor((intck('month', dob, '01Jul2021'd) - (day('01Jul2021'd) < day(dob))) / 12); 
fy1819 = input(age_sfy1819, age_range.);
fy1920 = input(age_sfy1920, age_range.);
fy2021 = input(age_sfy2021, age_range.);
fy2122 = input(age_sfy2122, age_range.); 
run;  

* get each year members individually from 00_macros file; 
%keep_age(data     = mem1819,
          fy       = fy1819,
          age_sfy  = age_sfy1819);  *2651615 (same as without macro);

%keep_age(data     = mem1920,
          fy       = fy1920,
          age_sfy  = age_sfy1920);  *2670614;

%keep_age(data     = mem2021,
          fy       = fy2021,
          age_sfy  = age_sfy2021);  *2685956;

%keep_age(data     = mem2122,
          fy       = fy2122,
          age_sfy  = age_sfy2122);  *2696471;

* Get members aged 0-64 in at least one of the SFY's only, save to out.; 
proc sql;
create table mem_list as 
select coalesce(a.clnt_id, b.clnt_id) as clnt_id
     , a.age_sfy1819
     , b.age_sfy1920
     , a.fy1819
     , b.fy1920
from mem1819 as a
full join mem1920 as b
on a.clnt_id = b.clnt_id;
quit; *2690472;  

proc sql; 
create table mem_list2 as 
select coalesce(a.clnt_id, b.clnt_id) as clnt_id
     , a.age_sfy1819
     , a.age_sfy1920
     , b.age_sfy2021
     , a.fy1819
     , a.fy1920
     , b.fy2021
from mem_list as a
full join mem2021 as b
on a.clnt_id = b.clnt_id;
quit; *;  

proc sql; 
create table mem_list3 as 
select coalesce(a.clnt_id, b.clnt_id) as clnt_id
     , a.age_sfy1819
     , a.age_sfy1920
     , a.age_sfy2021
     , b.age_sfy2122
     , a.fy1819
     , a.fy1920
     , a.fy2021
     , b.fy2122
from mem_list2 as a
full join mem2122 as b
on a.clnt_id = b.clnt_id;
quit; *;  

* Save to library 'out' and change all . to 0's ;
data out.mem_list;
set  mem_list3;
array fy fy1819 -- fy2122;
do over fy;
    if fy = . then fy = 0;
    end;
run; *2759411;

* Merge in with meddemog1;
proc sql; 
create table out.mem_list_demo as 
select a.*
     , b.*
from out.mem_list as a
left join meddemog1 as b 
on a.clnt_id = b.clnt_id; 
quit;  *2759411, 15 cols';

proc print data = out.mem_list_demo (obs = 200); 
run;


proc freq data = out.meddemog;
tables age_:;
run; * it keps 65-67... 

