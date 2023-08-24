SETUP: 
1. run_parallel.sas
2. program_to_boot.sas
3. boot_analysis.sas
MACROS: 
4. macro_parallel
5. macro_resample_V4

EXECUTE: 
|--run_parallel.sas
	|-- %INCLUDEs macro_parallel
	|-- runs program_to_boot.sas
		|-- program_to_boot.sas runs macro_resample_V4
2. boot_analysis.sas
	- scores int_imp