--ingresa cbu de proveedores
insert into tblPBE001 (VENDORID, PBE_CBUAutorizado,PBE_CondicionIVA,PBE_Cuit,PBE_Estatus,PBE_Fecha,PBE_generado,
						PBE_IdAutorizado,PBE_NombreAutorizado,PBE_NumIngresos,PBE_Sucursal,PBE_TipoCUB,PBE_TipoID,USERID)
select v.vendorid, pp.CBU, '', '', 1, 0, 1,
	'', '', '', '', 1, 1, 'ini'
from _proe_proveedores pp
inner join pm00200 v
	on v.VENDORID = pp.[Vendor ID]
and pp.CBU != ''
go
