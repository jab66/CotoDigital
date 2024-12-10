CREATE OR REPLACE PROCEDURE DSSADM.CTRL_TABLAS_RPT (PFECHA DATE, RESULTADO OUT NUMBER)
IS

P_ID_DIA DATE := PFECHA;
FECHA_PROCESO DATE := P_ID_DIA + 1;

CURSOR SUC IS
SELECT  DISTINCT ID_SUC FROM BT_VTAS_DIGITAL WHERE ID_DIA = P_ID_DIA;
REG_SUC SUC%ROWTYPE;


LOG_PROC VARCHAR2(15000);
LOG_PROC2 VARCHAR2(15000);
MENSAJE VARCHAR2(500) :=NULL;
ESTADO VARCHAR2(15);
PROCESADO TIMESTAMP;
DETALLE VARCHAR2(1500);
TOTAL1 NUMBER:=0;
TOTAL2 NUMBER:=0;
P_EMAIL NUMBER := 0;
VERROR BOOLEAN;

BEGIN

    log_proc := '<br><BR> '|| 'CONTROL TABLAS RPT - Inicio procedimiento - ' 
              || to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS')|| '<br> <br>';

    LOG_PROC := LOG_PROC||'DIA LOGISTICO: '||PFECHA|| '<br>';
    LOG_PROC := LOG_PROC||'FECHA PROCESO: '||FECHA_PROCESO|| '<br> <br>';

    --
    -- Control RPT_RESERVA_SUCURSAL
    --

    log_proc := log_proc || '** TABLA: RPT_RESERVA_SUCURSAL **' || '<br><br>';

    VERROR := FALSE;

    OPEN SUC;
    LOOP FETCH SUC INTO REG_SUC;
    EXIT WHEN SUC%NOTFOUND;

    BEGIN
    
        SELECT AUD_STATUS, AUD_PROCESS_DATE, AUD_DETAILS
        INTO ESTADO, PROCESADO, DETALLE
        FROM RPT.RPT_PROCESO
        WHERE   AUD_NAME = 'PROC_RPT_RESERVA_SUCURSAL'
            AND TRUNC(AUD_PROCESS_DATE) = FECHA_PROCESO
            AND AUD_SUCURSAL  =  LPAD(REG_SUC.ID_SUC,3,'0')
        ORDER BY AUD_PROCESS_DATE DESC
        FETCH FIRST ROW ONLY;
    
        LOG_PROC := LOG_PROC || REG_SUC.ID_SUC|| ' ' || ESTADO|| ' FECHAPRO: ' ||PROCESADO|| ' ' || DETALLE ||'<br>';

        IF ESTADO <> 'OK' THEN
            VERROR := TRUE;
            MENSAJE := 'CONTROL TABLAS RPT CON ERRORES';
        END IF;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        LOG_PROC := LOG_PROC || REG_SUC.ID_SUC|| ' NO DATA FOUND ' || FECHA_PROCESO ||'<br>';
    WHEN OTHERS THEN
        LOG_PROC := LOG_PROC || REG_SUC.ID_SUC|| ' ' || SQLERRM ||'<br>';
        VERROR := TRUE;
        MENSAJE := 'CONTROL TABLAS RPT CON ERRORES';
    END;

    END LOOP;
    CLOSE SUC;


    --
    -- Control RPT_PEDIDO_TARJETA
    --

    log_proc := log_proc || '<br>' ||  '** TABLA: RPT_PEDIDO_TARJETA **' || '<br><br>';

    OPEN SUC;
    LOOP FETCH SUC INTO REG_SUC;
    EXIT WHEN SUC%NOTFOUND;

    BEGIN
    
        SELECT AUD_STATUS, AUD_PROCESS_DATE, AUD_DETAILS
        INTO ESTADO, PROCESADO, DETALLE
        FROM RPT.RPT_PROCESO
        WHERE   AUD_NAME = 'PROC_RPT_PEDIDO_TARJETA'
            AND TRUNC(AUD_PROCESS_DATE) = FECHA_PROCESO
            AND AUD_SUCURSAL  =  LPAD(REG_SUC.ID_SUC,3,'0')
        ORDER BY AUD_PROCESS_DATE DESC
        FETCH FIRST ROW ONLY;
  
        LOG_PROC := LOG_PROC || REG_SUC.ID_SUC|| ' ' || ESTADO|| ' FECHAPRO: ' ||PROCESADO|| ' ' || DETALLE ||'<br>';

        IF ESTADO <> 'OK' THEN
            VERROR := TRUE;
            MENSAJE := 'CONTROL TABLAS RPT CON ERRORES';
        END IF;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        LOG_PROC := LOG_PROC || REG_SUC.ID_SUC|| ' NO DATA FOUND ' || FECHA_PROCESO ||'<br>';
    WHEN OTHERS THEN
        LOG_PROC := LOG_PROC || REG_SUC.ID_SUC|| ' ' || SQLERRM ||'<br>';
        VERROR := TRUE;
        MENSAJE := 'CONTROL TABLAS RPT CON ERRORES';
    END;

    END LOOP;
    CLOSE SUC;


    LOG_PROC := LOG_PROC || LOG_PROC2;
    LOG_PROC := LOG_PROC || '<BR>' || 'Codigo de respuesta = ' ||sys.diutil.bool_to_int(VERROR)||'<br>';
    log_proc := log_proc || '<BR>'|| 'CONTROL TABLAS RPT - Fin procedimiento - ' || to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS')|| '<br> ';

    resultado := sys.diutil.bool_to_int(VERROR);

    -- Envio de email
    SELECT SENT_MAIL_GCD4(PFECHA, MENSAJE, log_proc, 'Control Tablas RPT')
    INTO P_EMAIL FROM DUAL;

END;
/