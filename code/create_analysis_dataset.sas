**********************************************************************************************
 PROGRAMMER       : K Wiggins
 DATE INIT        : 02/2023
 PROJECT          : ISP Util
 PURPOSE          : merges all day
 INPUT FILE(S)    : 
 OUTPUT FILE(S)   : 
 LAST RAN/STATUS  : 20230209
 SPECS            : ISP_Utilization_Analytic_Plan_20221118.docx, 
***********************************************************************************************;

* do telehealth first so you can get pcmp counts easily (without the other columns); 
PROC SQL; 
CREATE TABLE merge0 AS 
SELECT a.*
     , b.*
FROM data.memlist AS A
LEFT JOIN data.memlist_tele_monthly AS B
ON a.mcaid_id = b.mcaid_id;
QUIT; 



