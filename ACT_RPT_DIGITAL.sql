CREATE OR REPLACE PROCEDURE DSSADM.ACT_RPT_DIGITAL (P_FECHA DATE, P_SUCURSAL NUMBER DEFAULT null, P_TIPO VARCHAR2 DEFAULT 'A') IS

--DECLARE
--
--P_FECHA DATE := TO_DATE('16/06/2021','DD/MM/YYYY');
--P_SUCURSAL NUMBER := NULL;
--P_TIPO VARCHAR2(10):='R';

-- es la fecha del dia logistico
FECHA_PARAM DATE := P_FECHA;

CURSOR PEDIDO IS
SELECT * FROM RPT_PEDIDO_SUCURSAL WHERE TRUNC(PEDIDO_DIALOGISTICO) = FECHA_PARAM
    AND SUCURSAL_ID BETWEEN DECODE(P_SUCURSAL, NULL,0, P_SUCURSAL) AND DECODE(P_SUCURSAL, NULL, 999, P_SUCURSAL);
REG_PEDIDO PEDIDO%ROWTYPE;

CURSOR HECHOS IS
SELECT * FROM AG_PEDIDOS_COTODIGITAL WHERE DIA_LOGISTICO = FECHA_PARAM;
REG_HECHOS HECHOS%ROWTYPE;

V_PERIODO number:=0;

P_TOTAL NUMBER := 0;
P_DERIVADO NUMBER := 0;
P_REPROGRAMADO NUMBER := 0;
P_CATEGORIA VARCHAR2(15) :='';
P_EMAIL NUMBER := 0;

CONTROL_SUCURSAL NUMBER := 0;
CONTROL_ESTADO_PEDIDO NUMBER := 0;
CONTROL_CATEGORIZACION NUMBER := 0;

SUCURSALES_ERROR NUMBER := 0;
REG_INSERTADOS NUMBER := 0;
MAX_SUC NUMBER := 0;
MIN_SUC NUMBER := 0;
P_MSG_ERROR VARCHAR2(500) := '';

V_MENSAJE_APROBACION VARCHAR2(500) := '';

RESULTADO NUMBER := 0;
MENSAJE VARCHAR2(25000);

dif_horas number;
dif_minutos number;
dif_segundos number;

log_proc varchar2(1500);
fecha_ejecucion TIMESTAMP := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
fecha_finalizacion TIMESTAMP;


TYPE REL_TYPE IS TABLE OF VARCHAR2(500)
      INDEX BY PLS_INTEGER;
L_REL REL_TYPE;

CURSOR REL IS
SELECT  A.PEDIDO_COBROMENSAJE, FPID, A.PEDIDO_ID
FROM    RPT_PEDIDO_TARJETA A , RPT_PEDIDO_SUCURSAL B
WHERE   A.PEDIDO_ID = B.PEDIDO_ID AND TRUNC(PEDIDO_DIALOGISTICO) = FECHA_PARAM
    AND A.FPID = (SELECT MAX(B.FPID) FROM RPT_PEDIDO_TARJETA B WHERE B.PEDIDO_ID = A.PEDIDO_ID);
REG_REL REL%ROWTYPE;


BEGIN

log_proc := '<br><BR> '|| 'Inicio procedimiento - ' || to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS')|| '<br><BR> ';

/********************************************************************
*
* SE CONTROLA QUE TODAS LAS SUCURSALES TENGAN REGISTROS PARA PROCESAR
*
*********************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
IF FNC_CONTROL_SUC_CD(FECHA_PARAM) > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'HAY 1 O MAS SUCURSALES SIN REGISTROS EN LA TABLA RPT_PEDIDO_SUCURSAL.');
END IF;
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'FNC_CONTROL_SUC_CD - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


/********************************************************************
*
* SE CONTROLA QUE LAS TABLAS RPT ESTEN SIN ERRORES PARA PROCESAR
*
*********************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
CTRL_TABLAS_RPT(FECHA_PARAM, RESULTADO);
--IF RESULTADO > 0 THEN
--    RAISE_APPLICATION_ERROR(-20002, 'TABLAS RPT TIENEN REGISTROS CON ERROR.');
--END IF;
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'CTRL_TABLAS_RPT - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';



/********************************************************************************
*
* SE ACTUALIZA EL PEDIDO_PERIODO DE LA TABLA RPT_PEDIDO_SUCURSAL SEGUN ESTADO 70
*
*********************************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_ESTADO_70(FECHA_PARAM);
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_ESTADO_70 - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


/*******************************************************************************
*
* SE ACTUALIZA EL PEDIDO_PERIODO DE LA TABLA RPT_PEDIDO_SUCURSAL SEGUN ESTADO 96
*
********************************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_RPT_PEDSUC_PERIODO(FECHA_PARAM);
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_RPT_PEDSUC_PERIODO - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


/******************************************************
*
* SE ACTUALIZA EL MAESTRO DE SUCURSALES DE COTO DIGITAL
*
*******************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_MAE_SUCURSALES_DIGITAL;
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_MAE_SUCURSALES_DIGITAL - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


/***********************************************
*
* SE ACTUALIZA EL MAESTRO DE ESTADO DE PEDIDOS
*
************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_MAE_ESTADO_PEDIDO;
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_MAE_ESTADO_PEDIDO - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) )) || ' <br> ';


/**********************************************************************
*
* SE CARGA LA MATRIZ PARA GUARDAR LOS MENSAJES DE APROBACION (TARJETAS)
*
***********************************************************************/
fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');

OPEN REL;
LOOP FETCH REL INTO REG_REL;
    EXIT WHEN REL%NOTFOUND;

    -- Se carga la relacion en una matriz
    L_REL(REG_REL.PEDIDO_ID):= REG_REL.PEDIDO_COBROMENSAJE;

END LOOP;
CLOSE REL;

fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'CARGA MATRIZ MENSAJE APROBACION (TARJETAS) - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


/***********************************************************
*
* GENERACION INFORMACION PARA LOS REPORTES (TABLA DE HECHOS)
* Carga la tabla AG_PEDIDOS_COTODIGITAL
*
*************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');

DELETE AG_PEDIDOS_COTODIGITAL WHERE DIA_LOGISTICO = FECHA_PARAM
                                AND ID_SUC BETWEEN DECODE(P_SUCURSAL, NULL,0, P_SUCURSAL) AND DECODE(P_SUCURSAL, NULL, 999, P_SUCURSAL);

OPEN PEDIDO;
LOOP FETCH PEDIDO INTO REG_PEDIDO;
EXIT WHEN PEDIDO%NOTFOUND;

    -- BUSCAR SI ES UN PEDIDO DERIVADO ------------------------------------------------------------------
    SELECT COUNT(1) INTO P_TOTAL FROM DATOS_PEDIDO_CAC_DER WHERE ID_PEDIDO = REG_PEDIDO.PEDIDO_ID;
    IF P_TOTAL != 0 THEN
        P_DERIVADO := 1;
    ELSE
        P_DERIVADO := 0;
    END IF;
    -----------------------------------------------------------------------------------------------------

    -- BUSCAR SI ES UN PEDIDO REPROGRAMADO --------------------------------------------------------------
    SELECT COUNT(1) INTO P_TOTAL FROM DATOS_PEDIDO_CAC_RPG WHERE ID_PEDIDO = REG_PEDIDO.PEDIDO_ID;

    IF P_TOTAL != 0 THEN
        P_REPROGRAMADO := 1;
    ELSE
        P_REPROGRAMADO := 0;
    END IF;
    -----------------------------------------------------------------------------------------------------

    /* Se busca el mensaje de aprobacion en la tabla de tarjetas */
    IF L_REL.EXISTS(REG_PEDIDO.PEDIDO_ID) = TRUE THEN
       V_MENSAJE_APROBACION := L_REL(REG_PEDIDO.PEDIDO_ID);
    ELSE
       V_MENSAJE_APROBACION := '(no especificado)';
    END IF;

    -----------------------------------------------------------------------------------------------------

    -- veriicacion del estado pedido = 4

    IF REG_PEDIDO.PEDIDO_PERIODO = 4 THEN
        V_PERIODO := 1;
    ELSE
        V_PERIODO := REG_PEDIDO.PEDIDO_PERIODO;
    END IF;
    ACT_LOG_PEDIDO_PERIODO(FECHA_PARAM, REG_PEDIDO.PEDIDO_ID, V_PERIODO, REG_PEDIDO.PEDIDO_PERIODO, 'ACT_RPT_DIGITAL-PRE INSERT');

    -----------------------------------------------------------------------------------------------------

    INSERT INTO AG_PEDIDOS_COTODIGITAL (ID_SUC, ID_PEDIDO, FECHA_COMPRA, FECHA_ENTREGA, ID_ESTADO_PEDIDO, DERIVADO, REPROGRAMADO,
                                        FECHA_CANCELACION, ID_CATEGORIA_PEDIDO, COBRO_ESTADOAPROBACION, FECHA_PROCESO, PEDIDO_PERIODO,
                                        DIA_LOGISTICO, PICKUP, CANTIDAD, BANDA, VENTA_RESERVA, FECHA_APROBACION, MENSAJE_APROBACION,
                                        CODIGO_CLIENTE, NOMBRE_CLIENTE, TELEFONO_CLIENTE, EMAIL_CLIENTE, DOMICILIO_ENTREGA_CLIENTE,
                                        DESCUENTA_CUPO, ORDEN_NUMERO, ID_CANAL,
                                        PEDIDO_ES_NOA, PEDIDO_PRIMERA_COMPRA, PEDIDO_ESTADO_ACTUAL_DESC, TIPO_RESERVA,
                                        FECHA_CANCELACION_SIN_HORA, ID_ESTADO_PEDIDO_ORIGINAL, ES_FASTLINE
                                        )
                                 VALUES (REG_PEDIDO.SUCURSAL_ID,
                                         REG_PEDIDO.PEDIDO_ID,
                                         REG_PEDIDO.PEDIDO_FECHACOMPRA,
                                         TO_DATE(REG_PEDIDO.PEDIDO_FECHAENTREGA, 'RRRRMMDD'),
                                         REG_PEDIDO.PEDIDO_ESTADOACTUAL,
                                         P_DERIVADO,
                                         P_REPROGRAMADO,
                                         REG_PEDIDO.PEDIDO_FECHAHORACANCELACION,
                                         0, --P_CATEGORIA,
                                         NVL(REG_PEDIDO.COBRO_ESTADOAPROBACION, '(no especificado)'),
                                         REG_PEDIDO.AUD_PROCESS_DATE,
                                         V_PERIODO, -- REG_PEDIDO.PEDIDO_PERIODO,
                                         FECHA_PARAM,
                                         REG_PEDIDO.PEDIDO_VENTAPICKUP,
                                         1,
                                         NVL(REG_PEDIDO.PEDIDO_BANDAENTREGA,'0000'),
                                         REG_PEDIDO.PEDIDO_ESVENTARESERVA,
                                         NVL(REG_PEDIDO.COBRO_ESTADOFECHA, to_date('01/01/1900','dd/mm/yyyy')),
                                         V_MENSAJE_APROBACION, --NVL(REG_PEDIDO.COBRO_ESTDOMENSAJE, '(no especificado)'),
                                         NVL(REG_PEDIDO.CLIENTE_ID,'0'),
                                         NVL(REG_PEDIDO.CLIENTE_NOMBRE, '(no especificado)'),
                                         NVL(REG_PEDIDO.CLIENTE_TELEFONOS, '(no especificado)'),
                                         NVL(REG_PEDIDO.CLIENTE_EMAIL, '(no especificado)'),
                                         NVL(REG_PEDIDO.CLIENTE_DOMICILIOENTREGA, '(no especificado)'),
                                         NVL(REG_PEDIDO.PEDIDO_DESCUENTACUPO, 0),
                                         NVL(REG_PEDIDO.PEDIDO_NUMEROORDEN,0),
                                         NVL(REG_PEDIDO.PEDIDO_IDCANAL,0),
                                         NVL(REG_PEDIDO.PEDIDO_ESNOA, 0),
                                         NVL(REG_PEDIDO.PEDIDO_PRIMERACOMPRA, 0),
                                         NVL(REG_PEDIDO.PEDIDO_ESTADOACTUALDESCRIPCION, ' '),
                                         NVL(REG_PEDIDO.PEDIDO_TIPORESERVA, 0),
                                         TRUNC(NVL(REG_PEDIDO.PEDIDO_FECHAHORACANCELACION,TO_DATE('01/01/1900','DD/MM/YYYY'))),
                                         REG_PEDIDO.PEDIDO_ESTADOACTUAL,
                                         REG_PEDIDO.ES_FASTLINE
                                         );

END LOOP;
CLOSE PEDIDO;
COMMIT;

fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'TABLA DE HECHOS - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


/***********************************************************************
*
* Llamada al procedimiento para la actualizacion del estado de pedido
*
************************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_CAMBIO_ESTADO_PEDIDO(FECHA_PARAM);
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_CAMBIO_ESTADO_PEDIDO - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


/***********************************************
*
*  Se determina la categoria de un pedido
*
************************************************/
fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');

OPEN HECHOS;
LOOP FETCH HECHOS INTO REG_HECHOS;
EXIT WHEN HECHOS%NOTFOUND;

    SELECT FUNC_CAT_PEDIDO(REG_HECHOS.ID_ESTADO_PEDIDO,
                           REG_HECHOS.DERIVADO,
                           REG_HECHOS.REPROGRAMADO,
                           REG_HECHOS.FECHA_ENTREGA,
                           REG_HECHOS.FECHA_CANCELACION,
                           REG_HECHOS.COBRO_ESTADOAPROBACION)
        INTO P_CATEGORIA FROM DUAL;

    UPDATE AG_PEDIDOS_COTODIGITAL SET ID_CATEGORIA_PEDIDO = P_CATEGORIA
    WHERE ID_SUC = REG_HECHOS.ID_SUC AND ID_PEDIDO = REG_HECHOS.ID_PEDIDO AND DIA_LOGISTICO = REG_HECHOS.DIA_LOGISTICO;

END LOOP;
CLOSE HECHOS;
COMMIT;

fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'CATEGORIA DE PEDIDO - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


/***********************************************************************
*
* Llamada al procedimiento para la generacion de la informacion diaria
*
************************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_AG_INFO_DIARIA(FECHA_PARAM, P_SUCURSAL);
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_AG_INFO_DIARIA - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


--/*************************************************************
--*
--* SE ACTUALIZA LA TABLA DE RELACION NUMERO DE PEDIDO / TICKET
--*
--**************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_LT_PEDIDO_TICKET2(FECHA_PARAM);
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_LT_PEDIDO_TICKET2 - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


--/***********************************************************************
--*
--* SE ACTUALIZA LA TABLA AG_PEDIDO_ENTREGA CON ESTADISTICA DE CADA PEDIDO
--*
--************************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_AG_PEDIDO_ENTREGA(FECHA_PARAM);
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_AG_PEDIDO_ENTREGA - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';

/*************************************************************
--*
--* SE ACTUALIZA LA TABLA DE RECIBOS PEDIDOS
--*
--* A PARTIR DEL 15.02.2023, NO SE USA MAS ESTE PROCESO PORQUE HUBO 
--* UN CAMBIO EN COMO SE CIERRA LA CAJA
--*
**************************************************************/

--fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
--ACT_RECIBOS_PEDIDOS(FECHA_PARAM);
--fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
--log_proc := log_proc || 'ACT_RECIBOS_PEDIDOS - ' || (((fecha_finalizacion - fecha_ejecucion) ) ) || ' minutos <br> ';


--/*****************************************************************
--*
--* SE ACTUALIZA LA TABLA PARA PEDIDOS CERRADOS ADMINISTRATIVAMENTE
--*
--* A PARTIR DEL 15.02.2023, NO SE USA MAS ESTE PROCESO PORQUE HUBO 
--* UN CAMBIO EN COMO SE CIERRA LA CAJA
--*
--******************************************************************/

--fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
--ACT_BT_PEDIDO_CERRADO_ADM(FECHA_PARAM);
--fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
--log_proc := log_proc || 'ACT_BT_PEDIDO_CERRADO_ADM - ' || (((fecha_finalizacion - fecha_ejecucion) ) ) || ' minutos <br> ';

--/*****************************************************************
--*
--* SE ACTUALIZA LA TABLA RPT_PEDIDO_DISTRIBUCION
--*
--******************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_RPT_PEDIDO_DISTRIBUCION(FECHA_PARAM);
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_RPT_PEDIDO_DISTRIBUCION - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


--/*****************************************************************
--*
--* SE ACTUALIZA LA TABLA CIERRE_DIARIO_COTO_DIGITAL
--*
--******************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_CIERRE_DIARIO_COTODIGITAL(FECHA_PARAM);
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_CIERRE_DIARIO_COTODIGITAL - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';

/***********************************************************************
*
* Llamada al procedimiento que actualiza los pedidos no entregados
* (Responsable / Motivo no entregado)
*
************************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_PEDIDOS_NOENTREGADOS(FECHA_PARAM, P_SUCURSAL);
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_PEDIDOS_NOENTREGADOS - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


/***********************************************************************
*
* Llamada al procedimiento que agrega codigo cliente, tarjeta comunidad
* y club la nacion en la tabla LT_PEDIDO_TICKET
*
************************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_CODCLIENTE_COMUNIDAD(FECHA_PARAM);
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_CODCLIENTE_COMUNIDAD - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


/***********************************************************************
*
* Llamada al procedimiento que actualiza tarjeta comunidad en la
* tabla BT_CF_TICKET
*
************************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_COMU_BTCFTICKET(FECHA_PARAM);
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_COMU_BTCFTICKET - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';


/***********************************************************************
*
* Llamada al procedimiento que actualiza el codigo de ATG  en la
* tabla LT_PEDIDO_TICKET
*
************************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_ID_ATG(FECHA_PARAM);
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_ID_ATG - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';



/********************************************************************
*
* SE ACTUALIZA LA FECHA DE COMPRA DEL PEDIDO 
*
*********************************************************************/

fecha_ejecucion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
ACT_FECHA_COMPRA_PEDIDO(FECHA_PARAM, RESULTADO, MENSAJE);
IF RESULTADO > 0 THEN
    log_proc := log_proc || MENSAJE || ' <br> ';
END IF;
fecha_finalizacion := TO_DATE(to_char(sysdate,'dd/mm/rrrr HH24:MI:SS'),'dd/mm/rrrr HH24:MI:SS');
log_proc := log_proc || 'ACT_FECHA_COMPRA_PEDIDO - ' || (((substr(Fecha_finalizacion - fecha_ejecucion, 11, 9 )) ) ) || ' <br> ';




log_proc := log_proc || '<BR>'|| 'Fin procedimiento - ' || to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS')|| '<br> ';


-- Envio de email
SELECT SENT_MAIL_GCD4(FECHA_PARAM, NULL, log_proc, 'Ejecución Proceso')
INTO P_EMAIL FROM DUAL;


EXCEPTION
WHEN OTHERS THEN

    P_MSG_ERROR := substr(SQLERRM, 500);

    ROLLBACK;

    -- Envio de email
    SELECT SENT_MAIL_GCD2(FECHA_PARAM, DBMS_UTILITY.format_error_stack) INTO P_EMAIL FROM DUAL;

END;
/
