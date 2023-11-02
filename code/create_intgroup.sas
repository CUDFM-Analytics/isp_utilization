
data data.intgroup;
  set data.utilization data.utilization (in = b);
  where int_imp = 1;
  if ^b then int_imp = 0;
  exposed = b;
run;
