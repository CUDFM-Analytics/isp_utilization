FILES, role: 
Only manually run 01_run_parallel and 02_boot_analysis. 
The other three are called from 01_run_parallel
STRATA: int (set in program_to_boot)
ANALYSIS: int_imp (set in hurdle models and 02_boot_analysis)

Logs prior to 10/24 in util_bootstrap weren't on final dataset; logs prior to 10/3 were with samprates backwards :(

(1) 01_run_parallel executes (2) macro_parallel and (3) program_to_boot; 
(3) program_to_boot executes macro_resample_v4
(2) boot_analysis is then run (on int_imp)

TO SETUP the bootstrap, edit the following sas code files: 
1. 01_run_parallel.sas
	- 
	- 
2. program_to_boot.sas
	- set strata: INT
	- set samprate (.2, 1)
3. 02_boot_analysis.sas
	- set compare, ... INT_IMP

TO EXECUTE: 
|--run_parallel.sas
	|-- %INCLUDEs macro_parallel
	|-- runs program_to_boot.sas
		|-- program_to_boot.sas runs macro_resample_V4
2. boot_analysis.sas
	- scores int_imp

NOTES: 
subjectID: ID of sampling units; if subj has > 1 row, all are selected into the sample
bootUnit: Names a column that makes each booted unit unique (if a subj is selected 2x in the bootUnit column, will have different IDs in each instance
