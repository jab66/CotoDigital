CREATE OR REPLACE FUNCTION DSSADM.SENT_MAIL_GCD2
(FECHA_PARAM DATE, PERROR VARCHAR2)

RETURN NUMBER
IS

RETORNO NUMBER := 0;
MENSAJE VARCHAR2(500) := '';


BEGIN

    IF PERROR IS NOT NULL THEN
        MENSAJE := 'El proceso de Gestion Coto Digital para el dia logistico <STRONG>'
                    ||FECHA_PARAM||'</STRONG> finalizo con el siguiente ERROR: </BR></BR>'||PERROR;
    END IF;

    IF PERROR IS NULL THEN
        MENSAJE := 'El proceso de Gestion Coto Digital para el dia logistico <STRONG>'
                    ||FECHA_PARAM||'</STRONG> finalizo CORRECTAMENTE';
    END IF;


    SEND_MAIL ('jbianculli@coto.com.ar',
                'GESTION COTO DIGITAL',
                MENSAJE);

    RETURN RETORNO;

END;
/