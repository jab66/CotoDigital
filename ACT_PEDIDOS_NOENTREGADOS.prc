CREATE OR REPLACE PROCEDURE DSSADM.ACT_PEDIDOS_NOENTREGADOS (P_FECHA DATE, P_SUCURSAL NUMBER DEFAULT NULL) IS

/**************************************
*
* Actualiza los pedidos no entregados
*
***************************************/

-- es el dia logistico
FECHA_PARAM DATE := P_FECHA;

CURSOR C1 IS
--SELECT *
--FROM    AG_PEDIDOS_COTODIGITAL
--WHERE   DIA_LOGISTICO = FECHA_PARAM
--    AND PEDIDO_PERIODO = 1
--    AND PICKUP = 0
--    AND ID_CATEGORIA_PEDIDO IN (150,60,70,80,90,100,110,120,130,160,170)
--    AND ID_SUC BETWEEN DECODE(P_SUCURSAL, NULL,0, P_SUCURSAL) AND DECODE(P_SUCURSAL, NULL, 999, P_SUCURSAL)
--    and id_pedido in (16108121);
-- cambiada la consulta el 21/10/2021
SELECT  *
  FROM  AG_PEDIDOS_COTODIGITAL
  where    DIA_LOGISTICO = FECHA_PARAM
  and     ID_CAT_CD in  (3);
REG_C1 C1%ROWTYPE;

CURSOR C2 (P_PEDIDO NUMBER) IS
SELECT * FROM RPT_PEDIDO_HOJARUTA
 WHERE PEDIDO_ID = P_PEDIDO AND TRUNC(HDR_FECHAALTA) = FECHA_PARAM AND HDR_CANCELADA = 0
ORDER BY VAS_RESPONSABLE DESC, VAS_FECHAALTA;
REG_C2 C2%ROWTYPE;

V_MOTIVO VARCHAR2(150) := NULL;
V_RESPONSABLE VARCHAR2(150) := NULL;
V_IDMOTIVO NUMBER := 0;
V_IDRESPONSABLE NUMBER := 0;
V_ENCONTRADO NUMBER := 0;
V_HDR_ID NUMBER := 0;
V_HDR_BANDA NUMBER := 0;
V_HDR_FECHAALTA DATE;
V_HDR_CANCELADA VARCHAR2(25) := NULL;
V_HDR_CADETE  VARCHAR2(25) := NULL;

BEGIN

OPEN C1;
LOOP FETCH C1 INTO REG_C1;
EXIT WHEN C1%NOTFOUND;

    -- Inicializan variables
    V_MOTIVO := NULL;
    V_RESPONSABLE := NULL;
    V_IDMOTIVO := 0;
    V_IDRESPONSABLE := 0;
    V_ENCONTRADO := 0;
    V_HDR_ID := 0;
    V_HDR_BANDA := 0;
    V_HDR_CANCELADA := NULL;
    V_HDR_CADETE := NULL;

    OPEN C2 (REG_C1.ID_PEDIDO);
    LOOP FETCH C2 INTO REG_C2;
    EXIT WHEN C2%NOTFOUND;

        -- responsable y motivo de la no entrega
        V_MOTIVO := REG_C2.VAS_MOTIVO;
        V_RESPONSABLE := REG_C2.VAS_RESPONSABLE;

        -- datos de la hoha de ruta
        V_HDR_ID := REG_C2.HDR_ID;
        V_HDR_BANDA := REG_C2.HDR_BANDA;
        V_HDR_FECHAALTA := REG_C2.HDR_FECHAALTA;
        V_HDR_CANCELADA := REG_C2.HDR_CANCELADA;
        V_HDR_CADETE := REG_C2.HDR_CADETE;

        V_ENCONTRADO := 1;

        EXIT;

    END LOOP;
    CLOSE C2;

    /*******************************************************************************************************************
    *
    * MOTIVO NO ENTREGADO
    *
    ********************************************************************************************************************/

    IF V_MOTIVO IS NOT NULL THEN

        BEGIN
            SELECT ID_MOTIVO_NOENTREGADO INTO V_IDMOTIVO FROM MAE_MOTIVO_NOENTREGADO WHERE DESC_MOTIVO_NOE = V_MOTIVO;
        EXCEPTION
            WHEN OTHERS THEN
                V_IDMOTIVO := 0;
        END;

    END IF;

    IF V_MOTIVO IS NULL THEN

        IF ( REG_C1.ID_ESTADO_PEDIDO < 94 AND REG_C1.ID_ESTADO_PEDIDO <> 70 ) THEN
            V_IDMOTIVO := 12;  --  'Sin movil asignado'
        ELSE
            IF ( REG_C1.ID_ESTADO_PEDIDO >= 94 AND REG_C1.REPROGRAMADO = 1  AND V_ENCONTRADO = 1 ) THEN
                V_IDMOTIVO := 13;  -- 'Pedido Reprogramado - Con Hoja de Ruta sin Cerrar'
                ELSE
                    IF ( REG_C1.ID_ESTADO_PEDIDO >= 94 AND REG_C1.REPROGRAMADO = 1  AND V_ENCONTRADO = 0 ) THEN
                        V_IDMOTIVO := 14;  -- 'Pedido Reprogramado - Sin movil asignado'
                    ELSE
                        IF ( REG_C1.ID_ESTADO_PEDIDO = 94 AND V_IDMOTIVO = 0) THEN
                            V_IDMOTIVO := 15;  -- 'Hoja de Ruta pendiente de Cierre'
                        END IF;
                    END IF;
            END IF;
        END IF;

    END IF;

    UPDATE AG_PEDIDOS_COTODIGITAL SET ID_MOTIVO_NOENTREGADO = V_IDMOTIVO
    WHERE ID_PEDIDO = REG_C1.ID_PEDIDO AND ID_SUC = REG_C1.ID_SUC AND DIA_LOGISTICO = FECHA_PARAM;

    /*******************************************************************************************************************
    *
    * RESPONSABLE
    *
    ********************************************************************************************************************/

    IF V_RESPONSABLE IS NOT NULL THEN

        BEGIN
            SELECT ID_RESPONSABLE INTO V_IDRESPONSABLE FROM MAE_RESPONSABLE WHERE DESC_RESPONSABLE = V_RESPONSABLE;
        EXCEPTION
            WHEN OTHERS THEN
                V_IDRESPONSABLE := 0;
        END;

    END IF;

    IF V_RESPONSABLE IS NULL OR V_RESPONSABLE = 'Otros' THEN
        V_IDRESPONSABLE := 1;
    END IF;

    UPDATE AG_PEDIDOS_COTODIGITAL SET ID_RESPONSABLE = V_IDRESPONSABLE
    WHERE ID_PEDIDO = REG_C1.ID_PEDIDO AND ID_SUC = REG_C1.ID_SUC AND DIA_LOGISTICO = FECHA_PARAM;

    /*******************************************************************************************************************
    *
    * DATOS DE LA HOJA DE RUTA
    *
    ********************************************************************************************************************/

        UPDATE AG_PEDIDOS_COTODIGITAL
        SET ID_HOJA_RUTA = NVL(V_HDR_ID, 0),
            BANDA_HOJA_RUTA = NVL(V_HDR_BANDA, 0),
            FECHA_HOJA_RUTA = NVL(V_HDR_FECHAALTA, TO_DATE('01/01/1900','DD/MM/YYYY')),
            CANCELADA_HOJA_RUTA = NVL(V_HDR_CANCELADA,'N'),
            CADETE_ENTREGA = NVL(V_HDR_CADETE, '0')
        WHERE ID_PEDIDO = REG_C1.ID_PEDIDO AND ID_SUC = REG_C1.ID_SUC AND DIA_LOGISTICO = FECHA_PARAM;

    /*
    ***********************************************************************************************************************
    */


END LOOP;
CLOSE C1;
COMMIT;

END;
/