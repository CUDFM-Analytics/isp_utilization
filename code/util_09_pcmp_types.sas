
PROC SQL ; 
CREATE TABLE int.pcmp_types AS 
SELECT pcmp_loc_id
     , pcmp_loc_type_cd 
FROM int.qrylong_1621 
QUIT ; 

PROC SORT DATA = int.pcmp_types NODUPKEY ; BY _ALL_ ; RUN ; *1421 ; 
DATA int.pcmp_types ; 
SET  int.pcmp_types (WHERE=(pcmp_loc_id ne ' ' )) ; 
RUN ; 
