/*
 * @author Simone Marchi <simone.marchi(at)ilc.cnr.it>
 */
/*
 * 1 - MUSPHU linked to redundant PHU (to be removed) (#112)
 */               
Update musphu mp, RedundantPhu r
Set
mp.idPhu = r.idRedundantOf
Where mp.idPhu = r.idRedundant
And r.idRedundantOf not in
      (Select rp.idRedundant
From RedundantPhu rp);       

/* 
 * 2 - MUSPHU linked to redundant MUS (status = 1) (#71)
 */
Update musphu mp, RedundantMus r
Set mp.idMus = r.idRedundantOf
Where mp.idMus = r.idRedundant
And r.status = 1
and mp.idMus not in
      (Select rm.idRedundantOf
From RedundantMus rm
where rm.status = 1);

/*
 * 3 - Duplicated MUSPHU (idKey excluded) (#38)
 */       
Delete 
From musphu m
Where m.idKey in
      (Select *
       From
          (Select mp.idKey 
           From musphu mp,
                musphu mp2
           Where mp.idMus = mp2.idMus
              And mp.idPhu = mp2.idPhu
              And mp.pos = mp2.pos
              And mp.morphFeat = mp2.morphFeat
              And mp.idKey > mp2.idKey ) As c);     

/*
 * 4 - Remove redundant PHU (#89)
 */ 
Delete
From phu p
Where p.idPhu In
      (Select Distinct rp.idRedundant
       From RedundantPhu rp);
       
/*
 * 5 - Affected da modifiche in Usyn (#0)
 */

/*
 * 6 - USYNUSEM linked to removed USEM (#41) 
 */
Update usynusem i,
     RedundantUsem ru
Set i.idUsem = ru.idRedundantOf
Where i.idUsem = ru.idRedundant
   And ru.status = 15;


/*
 * 7 - USYNUSEM duplicates (#688)
 */   
# Update (#688)
Delete
From usynusem
Where usynusem.ID in
      (Select *
       From
          (Select Distinct u.ID
           From usynusem u,
                usynusem u2
           Where u.idUsyn = u2.idUsyn
              And u.idUsem = u2.idUsem
              And u.idCorresp = u2.idCorresp
              And Coalesce (u.description,"") = Coalesce (u2.description,"")
              And u.ID > u2.ID) As C);
                
 /* 
 * 8 - Remove USEMPREDICATE linked to removed usem (#1)
 */
Delete
From usempredicate i
Where i.idUsem in
      (Select r.idRedundant
       From usem u,
            RedundantUsem r
       Where u.idUsem = r.idRedundant
          And r.status = 15);        
          
/* 
 * 9 - Remove USEMTEMPLATES linked to removed usem (#41)
 */
Delete          
From usemtemplates i
Where i.idUsem in
      (Select r.idRedundant
       From usem u,
            RedundantUsem r
       Where u.idUsem = r.idRedundant
          And r.status = 15);          
          
          
/* 
 * 10 - Remove USEMTRAITS linked to removed usem (#47)
 */           
Delete
From usemtraits i
Where i.idUsem in
      (Select r.idRedundant
       From usem u,
            RedundantUsem r
       Where u.idUsem = r.idRedundant
          And r.status = 15);         
          
/* 
 * 11 - Remove USEMREL linked to removed usem (#42)
 */ 
Delete
From usemrel i
Where i.idUsem in
      (Select r.idRedundant
       From usem u,
            RedundantUsem r
       Where u.idUsem = r.idRedundant
          And r.status = 15);        
          
          
/* 
 * 12 - Remove redundant USEM with status = 15 (#41)
 */ 
Delete
From usem
Where usem.idUsem in
      (Select r.idRedundant
       From RedundantUsem r
       Where status = 15);

/*
 * 13 - Remove redundant USYN with status = 15 (#4)
 */
Delete
From usyns u
Where u.idUsyn in
      (Select ru.idRedundant
       From RedundantUsyn ru
       Where status = 15);          

/*
 * 14 - Update usyn ponting to removed mus (status  1 and 2) (#1168)
 */

Update usyns mp,
       RedundantMus r
Set mp.idUms  = r.idRedundantOf
Where mp.idUms  = r.idRedundant;
      
/*
 * 15 - Remove redundant mus (status = 1) (#37)
 */
Delete
From mus m
Where m.idMus in
      (Select rm.idRedundant
       From RedundantMus rm);
