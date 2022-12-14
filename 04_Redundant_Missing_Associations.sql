###
### Rimozione duplicati in USEMREL (#10)
###
DELETE
from usemrel
WHERE ID IN (
   SELECT ID
   FROM(
         SELECT ID, ROW_NUMBER() OVER (
               PARTITION BY pos, idUsem, template, idRSem, idUsemTarget, comment, weighting
               ORDER BY idUsem) AS row_num
         FROM usemrel
      ) t
   WHERE row_num > 1
);

###
### R192 - sinonimia: Usemrel riflessive da eliminare (#9) 
###
delete 
from usemrel u 
where u.idRSem = "R192" AND 
u.idUsem = u.idUsemTarget;

#R192 - sinonimia: Usemrel mancanti per simmetria (#1645)
INSERT INTO usemrel
(pos, idUsem, template, idRSem, idUsemTarget, comment, weighting)
select distinct u.pos, ur.idUsemTarget , t.template , "R192", ur.idUsem, "", NULL
from usem u,
 usemrel ur left join usemtemplates ut on ur.idUsemTarget = ut.idUsem 
 left join  templates t on  ut.idTemplate = t.idTemplate 
where ur.idRSem = "R192"
and ur.idUsem = u.idUsem 
AND not exists (select 1
               from usemrel ur2
               where ur.idUsem = ur2.idUsemTarget
               and ur.idUsemTarget = ur2.idUsem
               and ur2.idRSem = "R192" );           

###
### R113 - ispartof without hasaspart (#1699)
###      
INSERT INTO usemrel
(pos, idUsem, template, idRSem, idUsemTarget, comment, weighting)
select distinct u.pos, ur.idUsemTarget , t.template , "R23", ur.idUsem, "", NULL
from usem u,
 usemrel ur left join usemtemplates ut on ur.idUsemTarget = ut.idUsem 
 left join  templates t on  ut.idTemplate = t.idTemplate 
where ur.idRSem = "R113"
and ur.idUsem = u.idUsem 
AND not exists (select 1
               from usemrel ur2
               where ur.idUsem = ur2.idUsemTarget
               and ur.idUsemTarget = ur2.idUsem
               and ur2.idRSem = "R23" );
            
###
### R23 - hasaspart without ispartof (#1364)
###      
INSERT INTO usemrel
(pos, idUsem, template, idRSem, idUsemTarget, comment, weighting)
select  u.pos, ur.idUsemTarget , t.template , "R113", ur.idUsem, "", NULL
from usem u,
 usemrel ur left join usemtemplates ut on ur.idUsemTarget = ut.idUsem 
 left join  templates t on  ut.idTemplate = t.idTemplate 
where ur.idRSem = "R23"
and ur.idUsem = u.idUsem 
AND not exists (select 1
               from usemrel ur2
               where ur.idUsem = ur2.idUsemTarget
               and ur.idUsemTarget = ur2.idUsem
               and ur2.idRSem = "R113" );
               
###              
### R71 - Isamemberof without hasasmember (#531)
###
INSERT INTO usemrel
(pos, idUsem, template, idRSem, idUsemTarget, comment, weighting)
select  u.pos, ur.idUsemTarget , t.template , "R48", ur.idUsem, "", NULL
from usem u,
 usemrel ur left join usemtemplates ut on ur.idUsemTarget = ut.idUsem 
 left join  templates t on  ut.idTemplate = t.idTemplate 
where ur.idRSem = "R71"
and ur.idUsem = u.idUsem 
AND not exists (select 1
               from usemrel ur2
               where ur.idUsem = ur2.idUsemTarget
               and ur.idUsemTarget = ur2.idUsem
               and ur2.idRSem = "R48" ); 
               
###
### R48 - Hasasmember whitout Isamemberof (#678)
###
INSERT INTO usemrel
(pos, idUsem, template, idRSem, idUsemTarget, comment, weighting)
select  u.pos, ur.idUsemTarget , t.template , "R71", ur.idUsem, "", NULL
from usem u,
 usemrel ur left join usemtemplates ut on ur.idUsemTarget = ut.idUsem 
 left join  templates t on  ut.idTemplate = t.idTemplate 
where ur.idRSem = "R48"
and ur.idUsem = u.idUsem 
AND not exists (select 1
               from usemrel ur2
               where ur.idUsem = ur2.idUsemTarget
               and ur.idUsemTarget = ur2.idUsem
               and ur2.idRSem = "R71" );            
