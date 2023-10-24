DATA avps;
SET out.cost_pc_avp_exch 
    out.cost_pc_avp_ind 
    out.cost_rx_avp_ind
    out.cost_total_avp_exch
    out.cost_total_avp_ind
    out.visits_ed_avp_exch
    out.visits_ed_avp_ind
    out.visits_ffsbh_avp_ind
    out.visits_pc_avp_exch
    out.visits_pc_avp_ind
    out.visits_tel_avp_exch
    out.visits_tel_avp_ind     indsname=source;
dsname = scan(source,2,'.');
RUN; 

proc PRINT data = avps; run; 
