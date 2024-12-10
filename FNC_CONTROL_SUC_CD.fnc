CREATE OR REPLACE FUNCTION DSSADM.FNC_CONTROL_SUC_CD (PFECHA DATE)

RETURN NUMBER IS

CURSOR SUC IS
SELECT  DISTINCT ID_SUC FROM BT_VTAS_DIGITAL WHERE ID_DIA = PFECHA;
REG_SUC SUC%ROWTYPE;

TOTAL_REGISTROS NUMBER := 0;

P_EMAIL NUMBER := 0;
LOG_PROC VARCHAR2(1500);
LOG_PROC2 VARCHAR2(1500);

-- 0 --> OK
-- >=1 --> ERROR
SIN_DATOS number := 0;
RESULTADO NUMBER := 0;

BEGIN

log_proc := '<br><BR> '|| 'CONTROL DE SUCURSALES - Inicio procedimiento - ' || to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS')|| '<br><BR> ';

OPEN SUC;
LOOP FETCH SUC INTO REG_SUC;
EXIT WHEN SUC%NOTFOUND;

    SELECT COUNT(1) INTO TOTAL_REGISTROS
    FROM  RPT_PEDIDO_SUCURSAL
    WHERE PEDIDO_DIALOGISTICO = PFECHA AND SUCURSAL_ID = REG_SUC.ID_SUC;

    log_proc2 := log_proc2 || 'Suc '|| reg_suc.id_suc||' = '||total_registros||'<br>';

    IF TOTAL_REGISTROS = 0 THEN

        log_proc2 := log_proc2 || '<BR>';
        log_proc2 := log_proc2 || 'REPROCESO DE '||'NTS'||LPAD(REG_SUC.ID_SUC,3,'0')||'<BR>';

        RPT.PROC_RPT_PEDIDO_SUCURSAL_2 ('NTS'||LPAD(REG_SUC.ID_SUC,3,'0'), PFECHA);
 
        SELECT COUNT(1) INTO TOTAL_REGISTROS
        FROM  RPT_PEDIDO_SUCURSAL
        WHERE PEDIDO_DIALOGISTICO = PFECHA AND SUCURSAL_ID = REG_SUC.ID_SUC;

        log_proc2 := log_proc2 || 'Suc '|| reg_suc.id_suc||' = '||total_registros||'<br>';

        IF TOTAL_REGISTROS = 0 THEN
           SIN_DATOS := SIN_DATOS + 1;
        END IF;
        
    END IF;

END LOOP;
CLOSE SUC;

IF SIN_DATOS = 0 THEN
    log_proc := log_proc || 'TODAS LAS SUCURSALES OK'||'<BR>';
    RESULTADO := 0;
END IF;

IF SIN_DATOS > 0 THEN
    log_proc := log_proc || 'HAY SUCURSALES SIN DATOS'||'<BR>';
    RESULTADO := 1;
END IF;

LOG_PROC := LOG_PROC || '<BR>' || LOG_PROC2;
log_proc := log_proc || '<BR>'|| 'CONTROL DE SUCURSALES - Fin procedimiento - ' || to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS')|| '<br> ';



SELECT SENT_MAIL_GCD4(PFECHA, NULL, log_proc, 'Control Sucursales')
 INTO P_EMAIL FROM DUAL;


RETURN RESULTADO;


END;
/