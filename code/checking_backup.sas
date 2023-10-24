* TESTING against back up file!!; 

libname bk2 'S:/FHPC/DATA/HCPF_DATA_files_SECURE\HCPF_SqlServer\AnalyticSubset\backup\backup2';

DATA    int.util_backup0; 
SET     bk2.qry_monthlyutilization (WHERE=(month ge '01Jul2016'd AND month lt '01Jul2023'd));
FORMAT  dt_qrtr date9.;
dt_qrtr =intnx('QTR', month, 0, 'BEGINNING'); 
FY      =year(intnx('year.7', month, 0, 'END'));
run; 
