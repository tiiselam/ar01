/****** Object:  StoredProcedure [dbo].[SP_PBEGP_BuscarPagosExcluidos]    Script Date: 6/23/2017 12:59:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_PBEGP_BuscarPagosExcluidos]
@Banco as varchar(15),
@userid as varchar(30)
as
begin
	delete from tblPBE002 where userid=@userid
	insert into tblPBE002 (VCHRNMBR,CHEKBKID,PAYDATE,DOCDATE,string1,DOCAMNT,VENDORID,vendname,userid,ConceptoTransf,[PBE_EstatusBanco])
	select t.NUMBERIE,
	t.BANACTID,
	t.DUEDATE,
	t.EMIDATE,
	upper(g.DSCRIPTN),
	t.AMOUNTO,
	d.VENDORID ,
	upper(t.TITACCT),
	@userid,
	CASE when t.MCPTYPID like 'HSBC%' then substring(t.MCPTYPID,6,15) else 'VAR' end,
	case when e.[PBE_EstatusBanco]=0 then 9 else e.[PBE_EstatusBanco] end
	from tblPBE003 ex
	left join nfMCP_PM20100 t on ex.VCHRNMBR=t.NUMBERIE
	left join nfMCP00700 m on m.MEDIOID=t.MEDIOID
	left join nfMCP00200 g on g.GRUPID=m.GRUPID
	left join (select VCHRNMBR,VNDCHKNM,VENDORID,VOIDED from PM20000
				union
				select VCHRNMBR,VNDCHKNM,VENDORID,VOIDED from PM30200) d on d.VCHRNMBR=t.NUMBERIE
	left join tblPBE003 e on t.NUMBERIE=e.vchrnmbr
	where t.BANKID=@Banco and AMOUNTO<>0 and t.BANACTID<>'' and d.VENDORID  is not null and e.pbe_excluido =1 and d.VOIDED=0 and t.VOIDED=0
	order by t.DUEDATE
end
go
GRANT EXECUTE ON dbo.SP_PBEGP_BuscarPagosExcluidos TO DYNGRP
go
