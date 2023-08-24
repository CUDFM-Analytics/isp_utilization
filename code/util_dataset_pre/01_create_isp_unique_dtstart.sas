
PROC SORT DATA = data.isp_key (WHERE = (pcmp_loc_id ne '.' ))  
     NODUPKEY out =isp (KEEP = dt_prac_isp pcmp_loc_id)    ; 
BY pcmp_loc_id dt_prac_isp ; 
RUN ; *119; 

DATA isp;
SET  isp ; 
dt_prac_isp2 = input(dt_prac_isp, date9.);
FORMAT dt_prac_isp2 date9.;
DROP   dt_prac_isp;
RENAME dt_prac_isp2 = dt_prac_isp;
RUN  ;  *118;

* there was a duplicate pcmp_loc_id with two different start dates: pcmp 162015 
* kids first id_split 3356 dt_start 01Mar2020 & their brighton high school id_split 3388 start date 01Jul2020
* I chose the 01Mar one for this
PER MARK G 2/28 = OK;
data data.isp_un_pcmp_dtstart;
set  data.isp_un_pcmp ;
if   pcmp_loc_id = "162015" and dt_prac_isp = '01JUL2020'd then delete ; 
pcmp2 = input(pcmp_loc_id, 8.); 
drop pcmp_loc_id;
rename pcmp2 = pcmp_loc_id; 
run ; *117;
