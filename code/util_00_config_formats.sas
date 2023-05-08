PROC FORMAT library = data;

* Formats for values in datasets in ana library:; 
VALUE budget_grp_new_       
    5          = "MAGI TO 68% FPL"
    3          = "MAGI 69 - 133% FPL"
    6,7,8,9,10 = "Disabled"  
    11         = "Foster Care"  
    12         = "MAGI Eligible Children"
    Other      = "Other"; 

VALUE $race_rc_  
    .         = "Other" 
    1         = "Hispanic/Latino"
    2         = "non-Hispanic White/Caucasian"
    3         = "non-Hispanic Black/African American"
    4,5,6,7,8 = "non-Hispanic Other"
    9         = "non-Hispanic Other People of Color" 
    Other     = "Unknown Race/Ethnicity";

* Formats for values created originally in the util files; 

VALUE age_cat_              
    0 - 5 = 1
    6 -10 = 2
    11-15 = 3
    16-20 = 4 
    21-44 = 5
    45-64 = 6 ;

VALUE $age_cat_
    1 = "ages 0-5"
    2 = "ages 6-10"
    3 = "ages 11-15"
    4 = "ages 16-20"
    5 = "ages 21-44"
    6 = "ages 45-64";
RUN;
