PROC FORMAT library = data;
*** Add quarter variables, one with text for readability ; 
value fyqrtr_cat
1  = "Q1"
2  = "Q2"
3  = "Q3"
4  = "Q4"
5  = "Q1"
6  = "Q2"
7  = "Q3"
8  = "Q4"
9  = "Q1"
10 = "Q2"
11 = "Q3"
12 = "Q4"
13 = "Q1"
14 = "Q2"
15 = "Q3"
16 = "Q4";

invalue fyqrtr_num
1  = 1
2  = 2
3  = 3
4  = 4
5  = 1
6  = 2
7  = 3
8  = 4
9  = 1
10 = 2
11 = 3
12 = 4
13 = 1
14 = 2
15 = 3
16 = 4;

* Formats for values in datasets in ana library:; 
VALUE budget_grp_r   
 low-<3 = 0   /*"Other"*/
      3 = 1   /*"MAGI 69 - 133% FPL"*/
      4 = 0   /*"Other"*/
      5 = 2   /*"MAGI TO 68% FPL"*/
   6-10 = 3   /*"Disabled"  */
     11 = 4   /*"Foster Care"  */
     12 = 5   /*"MAGI Eligible Children"*/
13-high = 0   /*"Other"*/
; 

* New format for the if/then/else variable in util_01 rows 866-871;
VALUE budget_grp_new_
0 = "Other"
1 = "MAGI 69 - 133% FPL"
2 = "MAGI TO 68% FPL"
3 = "Disabled"
4 = "Foster Care" 
5 = "MAGI Eligible Children";

VALUE budget_group_rc_
3 = "MAGI 69 - 133% FPL"
5 = "MAGI TO 68% FPL"
6-10 = "Disabled"
11 = "Foster Care"
12 = "MAGI Eligible Children"
Other = "Other"; 

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
    1 = "ages 0-5"
    2 = "ages 6-10"
    3 = "ages 11-15"
    4 = "ages 16-20"
    5 = "ages 21-44"
    6 = "ages 45-64";
RUN;
