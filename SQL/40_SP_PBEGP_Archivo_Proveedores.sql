IF EXISTS (
  SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_SCHEMA = 'dbo'
     AND SPECIFIC_NAME = 'SP_PBEGP_Archivo_Proveedores' 
)
   DROP PROCEDURE dcem.dcemCorrigePoliza;
GO


--27/07/17 jcf zipcode es obligatorio. Indicar cuit si no tiene num ingresos brutos.
--29/08/17 jcf quita caracteres especiales de dirección
--14/09/17 jcf comenta proveedores de tblPBE301
--18/09/17 jcf Agrega filtro PBE_Estatus>0
--05/12/19 jcf Corrige bug. Obtiene datos si el proveedor existe en tblPBE001 y pm00200
--12/12/19 jcf Corrige el conteo de proveedores y autorizados

alter procedure [dbo].[SP_PBEGP_Archivo_Proveedores]
@compania as bigint,
@fecha as datetime
as
begin
	delete from tblpbe999;
	declare @iProveedores INT, @iAutorizados INT;

 	select  @iProveedores = count(*) 
	from tblPBE001 d
	inner join PM00200 p 
			on p.VENDORID=d.VENDORID
	where d.PBE_generado=0 
	and d.PBE_Estatus>0;
	
	select @iAutorizados = count(*) 
	from tblPBE001 d
	inner join PM00200 p 
		on p.VENDORID=d.VENDORID
	where d.PBE_generado=0 
	and d.PBE_Estatus>0
	and d.PBE_IdAutorizado<>'';

	--Cabecera
	insert into tblpbe999 (id,txtfield)
	select '0','FH,'+													--- campo 1 Tipo de Registro
		replace(convert(varchar(19),@fecha,103),'/','')+','+			--- campo 2 fecha archivo
		'PCBE,'+														--- campo 3 Objeto. De uso para HSBC
		ltrim(str(
			1+( isnull(@iProveedores, 0) + isnull(@iAutorizados, 0))
			))+','+														--- campo 4 Cantidad de Registros del archivo
		'A,C,AR,HBAR,'+													--- campo 5 Tipo de Autorización, 6 Tipo de Archivo,7 País Cliente. De uso en HSBC, 8 Banco del Cliente. De uso en HSBC
		rtrim(replace(left(c.TAXREGTN,12),'-',''))+',,'					--- campo 9 Identificación del Cliente, 10 Nombre del archivo
	from DYNAMICS.dbo.SY01500 c 
	where c.CMPANYID=@compania

	--Registro del proveedor
	insert into tblpbe999 (id,txtfield)
	select p.VENDORID,'SP,I,'+											--- CAMPO 1 Tipo de Registro,	CAMPO 2 Indicador de Template. Uso HSBC
		case PBE_Estatus when 1 then 'U' when 2 then 'D' end+','+		--- CAMPO 3 Tipo de Acción
		rtrim(left(p.TXRGNNUM,11))+','+									--- CAMPO 4 CUIT Proveedor
		replace(rtrim(left(p.VENDNAME,40)),',','')+','+					--- CAMPO 5 Razón Social/Nombre Proveedor
		replace(replace(replace(rtrim(left(p.ADDRESS1+' '+p.ADDRESS2+' '+p.ADDRESS3,40)),',',''), 'º', '' ), '"', '')+','+   ---- CAMPO 6 Domicilio Proveedor
		REPLACE(rtrim(left(p.CITY,20)),',','')+','+						--- CAMPO 7 Localidad Proveedor
		left(rtrim(p.zipcode), 4) + ','+								--- CAMPO 8 Código Postal del Proveedor
		','+															--- CAMPO 9 Provincia Proveedor
		rtrim(left(pbe_sucursal,3))+','+								--- CAMPO 10 Sucursal de Entrega de Cheques
		--case when r.GrossIncomeNumber != '' then						--- CAMPO 11 Número de Ingresos Brutos Proveedor
		--	rtrim(left(CAST(R.GrossIncomeNumber AS VARCHAR(15)),15))
		--else
			left(p.TXRGNNUM,11)
		--end 
		+','+	
		replace(left(rtrim(m.RESPBLE),25),',','')+',,'+					--- campo 12 Condcion iva, campo 13,
		replace(rtrim(e.INET1),',',' ')+',,'+							--- CAMPO 14 Email, CAMPO 15
		','+	--- CAMPO 16
		','		--- campo 17
	from tblPBE001 d
	inner join PM00200 p on p.VENDORID=d.VENDORID
	left join AWLI_PM00200 r on r.VENDORID=d.VENDORID
	left join DYNAMICS.dbo.AWLI40330 m on m.RESP_TYPE=r.RESP_TYPE
	left join SY01200 e on e.Master_Type='VEN' and e.Master_ID=d.VENDORID  
	 where d.PBE_generado=0
	   and d.PBE_Estatus>0

	--Registro del autorizado
	insert into tblpbe999 (id,txtfield)
	select p.VENDORID,'SP,I,'+											--- campo 1	Tipo de Registro, campo 2	Indicador de Template. Uso HSBC
		case PBE_Estatus when 1 then 'U,' when 2 then 'D,' end+			----campo 3	Tipo de Acción
		rtrim(substring(p.TXRGNNUM,1,11))+','+							--- campo 4	CUIT Proveedor
		replace(rtrim(left(p.VENDNAME,40)),',','')+','+					---- campo 5	Razón Social/Nombre Proveedor
		replace(replace(replace(rtrim(left(p.ADDRESS1+' '+p.ADDRESS2+' '+p.ADDRESS3,40)),',','') , 'º', '' ), '"', '')+','+	---campo 6	Domicilio Proveedor
		replace(rtrim(left(p.CITY,20)),',','')+','+						--- campo 7	Localidad Proveedor
		','+															---- campo 8	Código Postal del Proveedor
		','+															--- campo 9		Provincia Proveedor
		rtrim(left(pbe_sucursal,3))+','+								--- campo 10	Sucursal de Entrega de Cheques
		','+															--- campo 11	Número de Ingresos Brutos Proveedor
		replace(rtrim(left(d.PBE_CondicionIVA,25)),',','')+',,,,'+		--- campo 12	Condición de IVA,13	Número de Teléfono Proveedor, 14 E-mail proveedor, 15 Nombre del Contacto
		case d.pbe_tipoid when 1 then '50' when 2 then '52' when 3 then '53' when 4 then '54' end+rtrim(left(d.PBE_IdAutorizado,8))+','+	--- campo 16 Tipo y Número de documento del Autorizado
		replace(rtrim(left(d.PBE_NombreAutorizado,40)),',','')+','		--- campo 17 Nombre del Autorizado
	from tblPBE001 d
	inner join PM00200 p on p.VENDORID=d.VENDORID
	where d.PBE_generado=0 
	and d.PBE_IdAutorizado<>''
	and d.PBE_Estatus>0

end
go

IF (@@Error = 0) PRINT 'Creación exitosa de: SP_PBEGP_Archivo_Proveedores'
ELSE PRINT 'Error en la creación de: SP_PBEGP_Archivo_Proveedores'
GO

GRANT EXECUTE ON dbo.SP_PBEGP_Archivo_Proveedores TO DYNGRP
go
