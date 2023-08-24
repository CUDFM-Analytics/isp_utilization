*****************************************************************************************
DATE CREATED: 3/29/2023
PROGRAMMER  : Carter Sevick
PURPOSE     : parallelize a random process 
NOTES       :
UPDATES     :
*****************************************************************************************;

%macro parallel(
                folder=   /* data / program location */,
                progName= /* name of the program that will act on the data  */,
                taskName= mytask /*, place holder names for the individual tasks */,
                nprocess = 8 /* number of processes to activate */,
                nboot    = 500 /* total number of bootstrap iterations*/,
                seed     = /* a seed value for replicability */,
                topseed = 1000000000 /* largest possible seed */
);

* create a random seed for each process ;
data _seeds_;

  call streaminit(&seed);

  array seed(&nprocess);

  do i = 1 to &nprocess;

    seed[i] = round(rand('UNIFORM', 0, 1) * &topseed, 1);

  end;

  output;

  stop;
  drop i;

run;

data _nboots_;
 
  array nboot(&nprocess);

  do i = 1 to &nprocess - 1;

    nboot[i] = round( &nboot/&nprocess, 1);

  end;

  nboot(&nprocess) = &nboot - sum(of nboot(*));

  output;

  stop;
  drop i;

run;

%do i = 1 %to &nprocess;

  * get a seed ;
  data _null_;
    set _seeds_;

    call symputx("seed_i", seed&i);

  run;

  * get a boot sample size ;
  data _null_;
    set _nboots_;

    call symputx("nboot_i", nboot&i);

  run;

   
  * have tried various methods to use better formating, all result in the code breaking ;
  systask command """%sysget(SASROOT)\sas.exe"" -noterminal -nosplash -sysin ""&folder\&progName"" -log ""&folder\%scan(&progName,1,%str(.))_log_&i..txt"" -sysparm ""&i &seed_i &nboot_i""" 
  taskname=task_&taskName&i status=rc_task&i;
/* */

%end;

* wait until all processes have finished ;
%let i=%eval(&i-1);
waitfor _all_
%do j=1 %to &i;
task_&taskName&j
%end;
/**/
%mend;


 
