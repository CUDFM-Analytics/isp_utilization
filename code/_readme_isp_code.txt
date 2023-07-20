****************************************************************************
03/30 Working Notes 
	1) MEMSIZE notes
	2) adj_: missing values > 2 members were blank, which is definitely wrong... FIXED
	3) re-ran int.a3 to end to get new final data set (util_30_create_final row 65 on... )
FINAL LOG FILE: log_20230330_fix_elig1618_part2.log / .txt in logs for final outcomes 
-----------------------------------------------------------------------------
1) MEMSIZE 
 - link: https://blogs.sas.com/content/iml/2015/07/31/large-matrices.html
 - ran ```proc options option=memsize value; run;```  
	- results: 12G with adjusting in the icon thingie 

2) Two members had blanks in their adj: columns (why only 2?) (G657131 and N039812) (is that a 0 or O make sure) 
SAVED LOG in _logs/log_20230330_fix_elig1618.log and log_...part2.log
Notes: I had subset on our fields and shouldn't have filtered -only needed eligibility 
	 


****************************************************************************
03/28 Working Notes 
-----------------------------------------------------------------------------

file: util_03_create_final_dataset...

CHECKS / crosstabs : 

Issues came up with the following values for mcaid_id's: 

  - Y591173 (why?)
  - G002318 
  - G010516 on data.a8 demographic info didn't come in for time = 4 - demo data in int.qrylong_1921 only had time 1:3 for this person, which does NOT make sense...
  - A000405 has BH but not mcaid, I think? Was that the issue? 
  - L155867 - check months of intervention * imp was a good check 
  - 0748682
  - P861018 - months, intervention * implementation 
  - A001791, A003524, A000405, A003219 > two were there, two should have been missing (1618 longitudinal) 
  - G6438649
  - A023159 A020536 A027267
  
PCMP LOC ID 
Check 103320 alternating months int*imp 


****************************************************************************
03/22 MTG NOTES KW/MG  
****************************************************************************
- crosstabs, simple summary / run analysis file 
- cost: univariates
- cats: freq's 
counts freqs

- outcome measure summary by intervention*implementation 

top code after dividing by months 

run logit on zero/non-zero costs, then do gamma on the positives 

****************************************************************************

  - 