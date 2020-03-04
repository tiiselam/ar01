--Propósito. Crea los resgistros para el archivo de pagos
--may/17 ltoro
--27/07/17 JCF Modifica campos de pagos: 6, 10, 15. De retenciones: 3,6,12,13,14,15. Ref. 170727 proe ALTA PAP HSBC - PROENERGY SRL.ajustes a archivos by a svar.htm
--10/08/17 jcf Corrige aplicación de facturas en registros DC y RE
--14/08/17 jcf Corrige porcentajes y monto acumulado de retención. Registro RE
--20/09/17 jcf No debe generar retenciones con monto cero sin número de certificado
--13/10/17 jcf Fecha de emisión y pago debe ser el parámetro @fecha. El hsbc rebota el archivo cuando la fecha del pago es de ayer o anterior.
--20/12/17 jcf Ajustes varios campo 15 del ID
--04/03/20 jcf Agrega caso de retenciones de Tucumán
--
IF EXISTS (
  SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_SCHEMA = 'dbo'
     AND SPECIFIC_NAME = 'SP_PBEGP_Archivo_Pag_Fac_Ret' 
)
   DROP PROCEDURE dbo.SP_PBEGP_Archivo_Pag_Fac_Ret;
GO

create procedure [dbo].[SP_PBEGP_Archivo_Pag_Fac_Ret]
@compania as bigint,
@fecha as datetime
as
begin
	delete from tblpbe999
	---Registro de Pagos
	insert into tblpbe999 (id,txtfield)
	select trx.VCHRNMBR,'ID,I,CC,ARS,N,'+														------ campos 1,2,3,4,5
			left(replace(replace(rtrim(isnull(ch.BANACTNU,'')),'/',''), '-', ''), 10) +','+		------ campo 6 cuenta emision
			--replace(convert(varchar,trx.DOCDATE,103),'/','')+','+								------ campo 7 fecha emisión
			replace(convert(varchar(19),@fecha,103),'/','')+ ','+								------ campo 7 fecha emisión
			convert(varchar,cast(trx.DOCAMNT as decimal(11,2)))+','+							------ campo 8 Importe del pago
			rtrim(left(trx.VCHRNMBR,15))+','+													------ campo 9 Numero de Orden de Pago
			case when trx.CUIBenfTransf != '' then
				rtrim(left(trx.CUIBenfTransf,11))
			else 
				rtrim(left(p.TXRGNNUM,11))
			end +','+																							-- campo 10 cuit del proveedor
			--replace(convert(varchar,trx.PAYDATE,103),'/','')+',Y,Y,'+											-- campo 11 fecha de pago campo 12, 13
			replace(convert(varchar(19), @fecha, 103),'/','') +													-- campo 11 fecha de pago 
			',Y,Y,'	+																							-- campo 12, 13
			RTRIM(case trx.String1 when 'TRANSFERENCIA' THEN 'T' WHEN 'CHEQUE DIFERIDO' THEN 'D' ELSE 'N' end)+','+	---campo 14 Forma de Pago N Cheque D Cheque Diferido T Transferencia
			case when trx.String1 = 'TRANSFERENCIA' and rtrim(PR.PBE_Sucursal) = '' then
				'140'
			else RTRIM(left(PR.PBE_Sucursal,3))
			end +','+																							--- campo 15 Sucursal
			replace(RTRIM(left(p.VNDCHKNM,60)),',','')+',,'+													--- campo 16 Nombre del Beneficiario campo 17
			RTRIM(CASE WHEN TRX.String1='TRANSFERENCIA' THEN left(PR.PBE_CBUAutorizado,22) ELSE '' END)+','+	--- campo 18 CBU del Beneficiario solo T
			RTRIM(CASE WHEN TRX.String1='TRANSFERENCIA' THEN CASE PR.PBE_TipoCUB WHEN 1 THEN '01' WHEN 2 THEN '02' END ELSE '' END)+',02,'+	--- campo 19 Tipo de Cuenta solo para t campo 20
			rtrim(case when trx.String1='TRANSFERENCIA' THEN left(p.TXRGNNUM,11) ELSE '' END) +','+				--- campo 21 cuit del proveedor SOLO PARA T
			RTRIM(CASE WHEN TRX.String1='TRANSFERENCIA' THEN left(TRX.ConceptoTransf,3) ELSE '' END)+','		--- campo 22 Cuit del beneficiario
	from tblPBE002 trx
	left join PM00200 p on p.VENDORID=trx.VENDORID
	left join nfMCP_PM20100 t on trx.VCHRNMBR=t.NUMBERIE
	left join nfMCP00700 m on m.MEDIOID=t.MEDIOID
	left join nfMCP00200 g on g.GRUPID=m.GRUPID
	left join (select VCHRNMBR,VNDCHKNM,VENDORID,CHEKBKID from PM20000
				union
				select VCHRNMBR,VNDCHKNM,VENDORID,CHEKBKID from PM30200) d on d.VCHRNMBR=t.NUMBERIE
	left join nfMCP00400 ch on ch.BANACTID=trx.CHEKBKID
	left join tblPBE003 e on t.NUMBERIE=e.vchrnmbr
	left join tblPBE001 pr on pr.VENDORID=trx.VENDORID
	where trx.SelectedToSave=1

	---Registro de Facturas
	insert into tblpbe999 (id,txtfield)
	select trx.VCHRNMBR,'DC,I,'+											--- CAMPO 1, CAMPO 2
		isnull(ltrim(right(rtrim(d.APTODCNM),15)),'')+','+					--- CAMPO 3 NRO. DOCUMENTO
		isnull(convert(varchar(4), year(d.aptodcdt)),'')+','+								--- CAMPO 4 AÑO
		isnull(replace(convert(varchar,d.duedate,103),'/',''),'')+','+		--- campo 5 fecha vencimiento
		isnull(replace(convert(varchar,d.APTODCDT,103),'/',''),'')+','+		--- campo 6 fecha documento
		isnull(RTRIM(left(d.APTODCNM,2)),'')+','+							--- campo 7 Tipo Documento
		isnull(convert(varchar,cast(d.APPLDAMT as decimal(18,2))),'')+','+	--- campo 8 importe
		+','+																--- campo 9 signo
		'$,'																--- campo 10 $
	from tblPBE002 trx
	left join nfMCP_PM20100 t on trx.VCHRNMBR=t.NUMBERIE
	left join nfMCP00700 m on m.MEDIOID=t.MEDIOID
	left join nfMCP00200 g on g.GRUPID=m.GRUPID
	inner join dbo.tii_vwPmAplicadosExtendido d
			on d.VCHRNMBR = t.NUMBERIE
			and d.doctype = 6
	left join nfMCP00400 ch on ch.BANACTID=trx.CHEKBKID
	--left join tblPBE003 e on t.NUMBERIE=e.vchrnmbr
	--left join tblPBE001 pr on pr.VENDORID=trx.VENDORID
	where trx.SelectedToSave=1

	---Registro de Retenciones
	insert into tblpbe999 (id,txtfield)
	select trx.VCHRNMBR,'RE,I,'+							--- campo 1 campo 2
		CASE when dr.nfRET_tipo_id like 'GCIA%' then 'G'
			when dr.nfRET_tipo_id like 'IVA%' then 'I'
			when dr.nfRET_tipo_id like 'IIBB%' then 'B'
			else 'O'
		end+','+											--- campo 3 Tipo de Retención
		rtrim(left(r.nfMCP_Printing_Number,15))+','+		--- campo 4 numero retencion
		LEFT(RTRIM(LTRIM(DR.nfRET_Descripcion)),15)+','+ 	--- campo 5 descripcion
		
		CASE when dr.nfRET_tipo_id like 'IIBB%' or dr.nfRET_tipo_id like 'SUSS%' then '0000' 
			else rtrim(substring(dr.nfRET_Regimen, CHARINDEX('-',DR.nfRET_Regimen,1)+1, 4))
		end+','+											--- campo 6 codigo oficial de la retención iiibb o SUSS = 0000

		CASE when dr.nfRET_tipo_id like 'IIBB%' --'Ingresos Brutos' 
			then left(rtrim(tipoRet.nfRET_Descripcion), 20)
			else rtrim(left(replace(C.Descripcion, ',', ''), 20))
		end +','+																				--- campo 7 descripcion codigo oficial
		CONVERT(VARCHAR,CAST(sum(R.nfRET_Base_Calculo) AS DECIMAL(18,2)))+','+					--- campo 8 Base imponible
		CONVERT(VARCHAR,CAST(sum(R.nfRET_Importe_Retencion) AS DECIMAL(18,2)))+','+				--- campo 9 Monto Retencion
		'$,'+																					--- campo 10
		RIGHT(CONVERT(VARCHAR,R.nfRET_Fec_Retencion,103),7)+','+								--- campo 11 fecha declaracion jurada

		CASE when dr.nfRET_tipo_id like 'IIBB%' then
			CASE WHEN CHARINDEX('-',dr.nfRET_Descripcion,1)=0 THEN 'DGR' 
				else substring(dr.nfRET_Descripcion, 1, CHARINDEX('-',dr.nfRET_Descripcion,1)-1) 
			end 
		ELSE ''
		END +','+																				--- campo 12 Resolución DGR
		CASE when dr.nfRET_tipo_id like 'IIBB%' then rtrim(left(C.Descripcion, 20)) ELSE '' END +','+	--- campo 13 Provincia

		CASE when dr.nfRET_tipo_id like 'IIBB%' then 
			ISNULL(CONVERT(VARCHAR,CAST(case when p.porc=0 then DR.nfRET_Porcentaje/100 
														else p.porc 
														end AS DECIMAL(18,2))),'') 
		 ELSE '' 
		 END +','+																				--- campo 14 Porcentaje

		CASE when dr.nfRET_tipo_id like 'IIBB%' then 
			ISNULL(CONVERT(VARCHAR,CAST(case when p.porc=0 then DR.nfRET_Porcentaje/100 
														else p.porc 
														end AS DECIMAL(18,2))),'') 
			ELSE '' 
		END +','+																				--- campo 15 alicuota
		
		CASE when dr.nfRET_tipo_id = 'GCIA' then 
					isnull(CONVERT(VARCHAR,CAST(
										(sum(r.nfRET_importe_retencion  + r.nfRET_Monto_Retenciones))
										--(select sum(x.nfRET_Importe_Retencion) 
										--from nfRET_GL10020 x 
										--where x.VENDORID=trx.VENDORID 
										--and month(x.nfRET_Fec_Retencion)=month(trx.DOCDATE) 
										--and year(x.nfRET_Fec_Retencion)=year(trx.DOCDATE) 
										--and x.nfRET_Retencion_ID=r.nfRET_Retencion_ID 
										--and x.DEX_ROW_ID<=r.DEX_ROW_ID) 
										AS DECIMAL(18,2))
									)
						,'') 
		else ''
		end	+','+																				--- campo 16 Monto acumulado
		CASE when dr.nfRET_tipo_id = 'SUSS' then 
					isnull(CONVERT(VARCHAR,CAST(
										(select sum(nfRET_Monto_Retenciones)
										from nfRET_GL10010
										where VENDORID = trx.VENDORID
										and nfRET_Retencion_ID = r.nfRET_Retencion_ID
										and nfRET_Periodo_Year = year(trx.DOCDATE)
										and nfRET_Period_Month = month(trx.DOCDATE)
										)
										AS DECIMAL(18,2))
									)
						,'') 
		else ''
		end	+','+																				--- campo 17 pago a cuenta 
		','+																					--- campo 18 
		(
		SELECT STUFF(
			(SELECT '/'+ltrim(right(rtrim(APTODCNM),15))
			FROM dbo.tii_vwPmAplicadas 
			WHERE vchrnmbr = TRX.VCHRNMBR 
			and doctype = 6
			FOR XML PATH(''))
			,1,1,'')
		)+','																					--- campo 19 Relacion Retencion Factura
	from dbo.tblPBE002 trx
	inner join dbo.nfRET_GL10020 r 
		on R.APFRDCNM = TRX.VCHRNMBR
		AND R.VENDORID = trx.VENDORID
	inner join dbo.nfret_gl00030 dr 
		on dr.nfRET_Retencion_ID = r.nfRET_Retencion_ID
	left join dbo.nfRET_GL00010 tipoRet
		on tipoRet.nfRET_tipo_id = dr.nfRET_tipo_id
	outer apply (select max(b.PRCNTAGE) as porc
				from nfRET_PM00201 b
				where TII_MCP_From_Date=(select max(TII_MCP_From_Date)
										from nfRET_PM00201 a
										where a.VENDORID = b.VENDORID
										and a.nfRET_Tipo_ID = b.nfRET_Tipo_ID) 
				and nfRET_Tipo_ID = dr.nfRET_tipo_id
				and vendorid = trx.VENDORID
				) p
	LEFT JOIN dbo.nfRET_SM40050 C 
		ON C.nfRET_ID_Regimen=SUBSTRING(DR.nfRET_Regimen,case when charindex('-',dr.nfRET_Regimen,1)=0 then 20 else charindex('-',dr.nfRET_Regimen,1)+1 end,20)
	where trx.SelectedToSave = 1
	and r.nfRET_Importe_Retencion <> 0
	group by r.nfRET_Retencion_ID, dr.nfRET_tipo_id, trx.VCHRNMBR,r.nfMCP_Printing_Number,trx.VENDORID,trx.DOCDATE,dr.nfRET_Regimen,c.nfRET_File_Code,c.Descripcion,r.nfRET_Fec_Retencion,dr.nfRET_Descripcion,dr.nfRET_Porcentaje,p.porc, tipoRet.nfRET_Descripcion, r.DEX_ROW_ID

	--DROP TABLE #TMP
	---Cabecera
	insert into tblpbe999 (id,txtfield)
	select '0','FH,'+		---campo 1
		replace(convert(varchar(19),@fecha,103),'/','')+	--- campo 2 fecha archivo
		',PCBE,'+	--- capon 3
		ltrim(str((select count(*) from tblPBE999)+1))+','+	--- campo 4 cantidad reg
		'A,C,AR,HBAR,'+	--- campo 5 a, campo 6 c, campo 7 AR, campo 8 HBAR
		rtrim(replace(left(c.TAXREGTN,12),'-',''))+',,'	--- campo 9 Cuit empresa	campo 10
	from DYNAMICS.dbo.SY01500 c where c.CMPANYID=@compania
end
go
GRANT EXECUTE ON dbo.SP_PBEGP_Archivo_Pag_Fac_Ret TO DYNGRP
go

IF (@@Error = 0) PRINT 'Creación exitosa de: SP_PBEGP_Archivo_Pag_Fac_Ret'
ELSE PRINT 'Error en la creación de: SP_PBEGP_Archivo_Pag_Fac_Ret'
GO
