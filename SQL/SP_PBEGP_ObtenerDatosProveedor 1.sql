create procedure [dbo].[SP_PBEGP_ObtenerDatosProveedor]
@IdProveedor as varchar(25),
@respble as varchar(25) out,
@nfrfcdsctp as varchar(15) out,
@cuit as varchar(11) out

as
begin
	select @respble=m.RESPBLE,@nfrfcdsctp=p.GrossIncomeNumber,@cuit=rtrim(left(gpp.TXRGNNUM,11)) from AWLI_PM00200 p
	left join DYNAMICS.dbo.AWLI40330 m on m.RESP_TYPE=p.RESP_TYPE
	left join nfRFC_PM00200 a on a.VENDORID=p.VENDORID
	left join nfRFC_SY00101 i on i.NFRFCTXCOD=a.NFRFCTXCOD
	left join PM00200 gpp on gpp.VENDORID=p.VENDORID
	where p.VENDORID=@IdProveedor
end 

GRANT EXECUTE ON dbo.SP_PBEGP_ObtenerDatosProveedor TO DYNGRP