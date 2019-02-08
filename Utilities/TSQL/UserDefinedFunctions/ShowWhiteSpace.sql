

USE dnb
GO

IF OBJECT_ID('dnb.dbo.ShowWhiteSpace') IS NOT NULL
    DROP FUNCTION [dbo].[ShowWhiteSpace]
GO


CREATE FUNCTION [dbo].[ShowWhiteSpace]
(
    @str VARCHAR(8000)
)
RETURNS VARCHAR(8000)
AS
    BEGIN
        DECLARE @ShowWhiteSpace VARCHAR(8000);
        SET @ShowWhiteSpace = @str
        SET @ShowWhiteSpace = REPLACE(@ShowWhiteSpace,CHAR(32),'[?]')
        SET @ShowWhiteSpace = REPLACE(@ShowWhiteSpace,CHAR(13),'[CR]')
        SET @ShowWhiteSpace = REPLACE(@ShowWhiteSpace,CHAR(10),'[LF]')
        SET @ShowWhiteSpace = REPLACE(@ShowWhiteSpace,CHAR(9),'[TAB]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(1),  '[SOH]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(2),  '[STX]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(3),  '[ETX]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(4),  '[EOT]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(5),  '[ENQ]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(6),  '[ACK]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(7),  '[BEL]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(8),  '[BS]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(11), '[VT]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(12), '[FF]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(14), '[SO]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(15), '[SI]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(16), '[DLE]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(17), '[DC1]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(18), '[DC2]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(19), '[DC3]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(20), '[DC4]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(21), '[NAK]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(22), '[SYN]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(23), '[ETB]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(24), '[CAN]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(25), '[EM]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(26), '[SUB]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(27), '[ESC]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(28), '[FS]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(29), '[GS]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(30), '[RS]')
        --   SET @ShowWhiteSpace = REPLACE( @ShowWhiteSpace, CHAR(31), '[US]')

        RETURN ( @ShowWhiteSpace )
    END