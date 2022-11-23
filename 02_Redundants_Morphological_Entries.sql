/*
 * @author Simone Marchi <simone.marchi(at)ilc.cnr.it>
 */
# Redundant Mus status = 1 (#37)
Insert Into RedundantMus (idRedundant, idRedundantOf, status)
Select m2.idMus, m.idMus, 1
From mus m, mus m2
Where m.naming = m2.naming
And m.pos = m2.pos
And m2.idMus > m.idMus
And Coalesce (m.ginp, '') = Coalesce (m2.ginp, '');

# Redundant Mus status = 2 (#944)
Insert Into RedundantMus (idRedundant, idRedundantOf, status)
Select m.idMus, m2.idMus, 2
From mus m, mus m2
Where m.naming = m2.naming
And m.pos = m2.pos
And m2.idMus > m.idMus
And m.ginp Is Null
And m2.ginp Is Not null;
 