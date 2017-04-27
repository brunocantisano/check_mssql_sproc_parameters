SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Bruno Cardoso Cantisano
-- Create date: 25/04/2017
-- Description:	Stored Procedure a ser usada para pelo nagios
-- =============================================
CREATE PROCEDURE [dbo].[checaTabProcessos]
	@nomeProcesso	as varchar(30) = ''
AS
	declare @ultDataHora	datetime
	declare @minutos		int
	declare @intervaloMin	int
	declare @Retorno 		tinyint
	declare @CountErro		tinyint
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	set @Retorno = 0
	SET @CountErro = 0

	DECLARE @Tbl_Final TABLE (Mensagem varchar(50));
	IF LEN(@nomeProcesso) <> 0
		BEGIN
			DECLARE processos_cursor CURSOR FOR
			SELECT T.nomeProcesso, T.ultDataHora, T.intervaloMin
			from TabProcesso T WITH (NOLOCK)
			WHERE T.nomeProcesso = rtrim(@nomeProcesso)
			ORDER BY T.NomeProcesso;
		END
	ELSE
		BEGIN
			DECLARE processos_cursor CURSOR FOR
			SELECT T.nomeProcesso, T.ultDataHora, T.intervaloMin
			from TabProcesso T WITH (NOLOCK)
			ORDER BY T.NomeProcesso;
		END

	OPEN processos_cursor
	FETCH NEXT FROM processos_cursor
	INTO @nomeProcesso, @ultDataHora, @intervaloMin
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @minutos = DATEDIFF(minute, @ultDataHora, GETDATE())
		if @minutos > @intervaloMin
			BEGIN
				INSERT INTO @Tbl_Final (Mensagem) values ('O processo: ' + rtrim(@nomeProcesso) + ' caiu')
				SET @CountErro = @CountErro + 1
			END
		FETCH NEXT FROM processos_cursor
		INTO @nomeProcesso, @ultDataHora, @intervaloMin
	END
	CLOSE processos_cursor;
	DEALLOCATE processos_cursor;

	IF @CountErro > 0
		BEGIN
			SET @Retorno = 2
		END
	ELSE
		BEGIN
			INSERT INTO @Tbl_Final (Mensagem) values ('Não existem processos a monitorar')
		END

	SELECT @Retorno as retorno, Mensagem FROM @Tbl_Final;

	RETURN @Retorno
END
