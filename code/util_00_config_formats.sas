PROC FORMAT library = data;

* Formats for values in datasets in ana library:; 
VALUE budget_grp_new_       
    5          = "MAGI TO 68% FPL"
    3          = "MAGI 69 - 133% FPL"
    6,7,8,9,10 = "Disabled"  
    11         = "Foster Care"  
    12         = "MAGI Eligible Children"
    Other      = "Other"; 

VALUE fqhc_rc_              
    32, 45, 61, 62 = 1
    Other          = 0;

VALUE $race_rc_  
    .         = "Other" 
    1         = "Hispanic/Latino"
    2         = "non-Hispanic White/Caucasian"
    3         = "non-Hispanic Black/African American"
    4,5,6,7,8 = "non-Hispanic Other"
    9         = "non-Hispanic Other People of Color" 
    Other     = "Unknown Race/Ethnicity";

* Formats for values created originally in the util files; 
VALUE adj_pd_total_YRcat_   
    0 = 0
    1 - 50  = 1
    51 - 75 = 2
    76 - 95 = 3
    96 - 99 = 4 
    Other = .;

VALUE age_cat_              
    0 - 5 = 1
    6 -10 = 2
    11-15 = 3
    16-20 = 4 
    21-44 = 5
    45-64 = 6 ;

RUN;
