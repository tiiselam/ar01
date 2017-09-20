use PSARP
GO

update p set pbe_generado = 0, PBE_Estatus = 1
from tblPBE001 p
where p.PBE_CBUAutorizado <> ''
and p.PBE_generado = 1
GO
