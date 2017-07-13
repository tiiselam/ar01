create procedure [dbo].[SP_PBEGP_BuscarPagos]
@Banco as varchar(15),
@userid as varchar(30)
as
begin
	delete from tblPBE002 where userid=@userid
	insert into tblPBE002 (ord_line,VCHRNMBR,CHEKBKID,PAYDATE,DOCDATE,string1,DOCAMNT,VENDORID,vendname,userid,ConceptoTransf,[PBE_EstatusBanco])
	select ROW_NUMBER() OVER(ORDER BY t.banactid ASC) AS Row#,
	t.NUMBERIE,
	t.BANACTID,
	t.DUEDATE,
	t.EMIDATE,
	upper(g.DSCRIPTN),
	t.AMOUNTO,
	d.VENDORID ,
	upper(t.TITACCT),
	@userid,
	CASE when t.MCPTYPID like 'HSBC%' then substring(t.MCPTYPID,6,15) else 'VAR' end,
	isnull(e.[PBE_EstatusBanco],9)
	from nfMCP_PM20100 t
	left join nfMCP00700 m on m.MEDIOID=t.MEDIOID
	left join nfMCP00200 g on g.GRUPID=m.GRUPID
	left join (select VCHRNMBR,VNDCHKNM,VENDORID,VOIDED from PM20000
				union
				select VCHRNMBR,VNDCHKNM,VENDORID,VOIDED from PM30200) d on d.VCHRNMBR=t.NUMBERIE
	left join tblPBE003 e on t.NUMBERIE=e.vchrnmbr
	where t.BANKID=@Banco and AMOUNTO<>0 and t.BANACTID<>'' and d.VENDORID is not null and isnull(e.pbe_excluido,0) =0 and t.VOIDED=0 and d.VOIDED=0
	order by t.DUEDATE
end
go
GRANT EXECUTE ON dbo.SP_PBEGP_BuscarPagos TO DYNGRP
go
