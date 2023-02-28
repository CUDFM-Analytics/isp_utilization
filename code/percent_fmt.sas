ods path work.templat(update) sashelp.tmplmst(read); 

* Create picture format for percents;
proc format;
 picture pctfmt low-high='000.00%';
run;

* Edit the template using PROC TEMPLATE;
proc template;
 edit Base.Freq.OneWayFreqs;
 edit Percent;
 header="; Relative; Frequency ;";
 format= pctfmt.;
 justify= on;
 end;
 edit CumPercent;
 header = ";Cumulative; Relative Frequency;";
 format= pctfmt.;
 justify= on;
 end;
end;
run; 

ods path work.templat(update) sashelp.tmplmst(read);
proc template;
 edit Base.Freq.OneWayList;
 edit Percent;
 header="; Relative Frequency ;";
 format= pctfmt.;
 justify= on;
 end;
 edit CumPercent;
 header = ";Cumulative; Relative Frequency;";
 format= pctfmt.;
 justify= on;
 end;
 end;
run; 

