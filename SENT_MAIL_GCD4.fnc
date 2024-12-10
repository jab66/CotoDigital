CREATE OR REPLACE FUNCTION DSSADM.SENT_MAIL_GCD4
(FECHA_PARAM DATE, PERROR VARCHAR2, logger varchar2, proceso varchar2)

RETURN NUMBER
IS

RETORNO NUMBER := 0;
MENSAJE VARCHAR2(12000) := '';
RESULTADO NUMBER;


BEGIN

    IF PERROR IS NOT NULL THEN
        MENSAJE := 'El proceso de Gestion Coto Digital para el dia logistico <STRONG>'
                    ||FECHA_PARAM||'</STRONG> finalizo con el siguiente ERROR: </BR></BR>'||PERROR;
        RESULTADO := 1;
    END IF;

    IF PERROR IS NULL THEN
        MENSAJE := 'El proceso de Gestion Coto Digital para el dia logistico <STRONG>'
                    ||FECHA_PARAM||'</STRONG> finalizo CORRECTAMENTE'||logger;
        RESULTADO := 0;
    END IF;



--    SEND_MAIL ('jbianculli@coto.com.ar',
--                'GCDIGITAL - '||FECHA_PARAM||' - SUCURSALES ('||RESULTADO||')',
--                MENSAJE);

    SEND_MAIL ('jbianculli@coto.com.ar',
                'GCDIGITAL - '||FECHA_PARAM||' - ' || proceso || ' ('||RESULTADO||')',
                MENSAJE);

    RETURN RETORNO;

END;
/