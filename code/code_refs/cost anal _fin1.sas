


libname bhjt 'X:\HCPF_SqlServer\queries';    /* I need race/ethnicity from here, and budget group, maybe others */
options fmtsearch=(bhjt);


proc format;
value agecat 1="0-19" 2="20-64" 3="65+";
value agehcpf 1="0-3" 2="4-6" 3="7-12" 4="13-20" 5="21-64" 6="65+";
value age7cat 1="0-5" 2="6-10" 3="11-15" 4="16-20" 5="21-44" 6="45-64" 7="65+";
value nserve 1="1" 2="2" 3="3" 4="4" 5="5" 6="6" 7="7+";
value capvsh 1="Same month" 2="Short term first" 3="Cap first" 4="Short term only" 5="Cap only" 6="Neither";

value clmType  1 = 'Pharmacy' 2='Hospitalizations' 3 = 'ER' 4 = 'Primary care'  100='Other';
run;




libname cost 'X:\Jake\short_term_bh\final datasets';
data tri_year9; set cost.cost_stbh1; run;

proc freq data=tri_year9; format rethnic_hcpf rethnic_hcpf.; tables fy6 mths_elig_all age_last_cat mths_elig_no_mc gender rethnic_hcpf enr_cnty 
           BUDGET_GROUP RAE_ID SIM_practice FQHC pcmp_had_bh tot_serve_cat;
run;
proc means data=tri_year9 min p10 p25 p50 p75 p90 max mean stddev maxdec=1; 
var tot_serv_year PC_tot_pd_fy tot_pd_fy bho_hosp_y bho_er_y bho_other_y tot_serve_cat tot_serve_lin_cap total_cost_pmpm pctotal_cost_pmpm;
run;



data county;
  set county_conv;
  start = put(hcpf_county_code, z2.);
  label = county_name;
  fmtname='$hcpfCnty';
run; 
proc format cntlin=county;
run;

/*proc freq data=tri_year9; format enr_cnty $hcpfCnty.; tables enr_cnty; run;*/



data tri_yearfin1; set tri_year9; 
 if mths_elig_no_mc=0 or gender='U' or BUDGET_GROUP=1 then delete;
 if enr_cnty in ('81','AP') or enr_cnty=' ' then enr_cnty='0';
 if RAE_ID=' ' then RAE_ID='0';
run;
 

proc tabulate data=tri_yearfin1 format=8.1 Style=[just=c]; 
class tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID fy6; classlev tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID/style=[pretext='a0a0'x];
var total_cost_pmpm;
 table all tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID, 
 total_cost_pmpm=''*fy6='Year'*(Mean)/ nocellmerge misstext='0' box='Category';
run;
proc tabulate data=tri_yearfin1 format=8.1 Style=[just=c]; 
class tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID fy6; classlev tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID/style=[pretext='a0a0'x];
var pctotal_cost_pmpm;
 table all tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID, 
 pctotal_cost_pmpm=''*fy6='Year'*(Mean)/ nocellmerge misstext='0' box='Category';
run;



***Do the same, but separately for members who had at least one stbh in last 3 fy's and members with none in last 3 fy;
proc contents data=tri_yearfin1 varnum; run;

proc sql;
 create table tri_yearfin2 as
 select *,
  max(case when fy6 in (2018,2019,2020) and tot_serv_year ge 1 then 1 else 0 end) as stbh_yes_3yr
from tri_yearfin1
group by clnt_id;
quit; 

proc tabulate data=tri_yearfin2 format=8.1 Style=[just=c]; where stbh_yes_3yr=0; 
class tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID fy6; classlev tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID/style=[pretext='a0a0'x];
var total_cost_pmpm;
 table all tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID, 
 total_cost_pmpm=''*fy6='Year'*(Mean)/ nocellmerge misstext='0' box='Category';
run;
proc tabulate data=tri_yearfin2 format=8.1 Style=[just=c]; where stbh_yes_3yr=0;
class tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID fy6; classlev tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID/style=[pretext='a0a0'x];
var pctotal_cost_pmpm;
 table all tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID, 
 pctotal_cost_pmpm=''*fy6='Year'*(Mean)/ nocellmerge misstext='0' box='Category';
run;

proc tabulate data=tri_yearfin2 format=8.1 Style=[just=c]; where stbh_yes_3yr=1; 
class tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID fy6; classlev tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID/style=[pretext='a0a0'x];
var total_cost_pmpm;
 table all tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID, 
 total_cost_pmpm=''*fy6='Year'*(Mean)/ nocellmerge misstext='0' box='Category';
run;
proc tabulate data=tri_yearfin2 format=8.1 Style=[just=c]; where stbh_yes_3yr=1;
class tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID fy6; classlev tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID/style=[pretext='a0a0'x];
var pctotal_cost_pmpm;
 table all tot_serve_lin_cap pcmp_had_bh FQHC SIM_practice RAE_ID, 
 pctotal_cost_pmpm=''*fy6='Year'*(Mean)/ nocellmerge misstext='0' box='Category';
run;
