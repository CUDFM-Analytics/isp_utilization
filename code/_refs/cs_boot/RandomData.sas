*****************************************************************************************
DATE CREATED: 3/31/2023

PROGRAMMER  : Carter Sevick

PURPOSE     : Generate random study data

NOTES       :

UPDATES     :

*****************************************************************************************;

%let projRoot = M:\Carter\Examples\boot total cost;
 
%let N = 500; * subjects ;
%let M =  24; * Measurements ;

libname dataRaw "&projRoot\dataRaw";


data dataRaw.studyDat;

  call streaminit(35471);

  do ID = 1 to &N;

     * covariates ;
     ageEmanc = rand('UNIFORM', 17, 21);
     gender = rand('BERNOULLI', 0.5) ;
     rethnic = rand('TABLE', 0.6, 0.15, 0.15, 0.1)  ; 
     pmca_cat = rand('TABLE', 0.5, 0.25, 0.25);
     emanc_yr = 2014 + floor(rand('UNIFORM', 0, 6));

     * random person effect ;
     person = rand('NORMAL', 0, 0.2);

     * last month with data ;
     dropout = 1 + floor(rand('UNIFORM', 0, &M - 1));

     * add a level 3 ID ;
     practice = floor(rand('UNIFORM', 0, 30));

     *follow up measures ;
     do relMonth = 0 to dropout;
        relZero = relmonth = 0;

        * probability model ;
        y_p = -0.84 + 0.05*ageEmanc + 0.55*relzero + .5*gender + 0.1*pmca_cat + person;
        pvar = rand('BERNOULLI', 1/(1 + exp(-y_p)));

        * cost model ;
        if pvar = 0 then cvar = 0;
        if pvar = 1 then do;
           y_c = 6 + 0.15*ageEmanc + 0.5*relzero + .5*gender + 0.1*pmca_cat + person;
           cvar = exp(rand('normal', y_c, 1));
        end;

        output;

     end;

  end;
 
run;

proc means data= dataraw.studydat;
  run;
