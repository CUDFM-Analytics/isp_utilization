   
proc contents data = data.ANALYIS_DATASET VARNUM; 
TITLE "Contents: Final Dataset" ; 
RUN ; 

proc univariate data = data.analyis_dataset ; 
VAR cost: ; 
Title "Univariate: Cost DV's" ; 
RUN; 

proc univariate data = data.analyis_dataset ; 
VAR util: ; 
Title "Univariate: Util DV's" ; 
RUN; 

proc freq data = data.analysis_dataset ; 
tables int*ind: ; 
Title "Intervention * Indicator if DV 0 or ge 1"; 
RUN; 

proc freq data= data.analysis_dataset ; 
Title "Intervention Status Frequency" ;
tables int*pcmp_loc_id ; 
run ; 

