CREATE OR REPLACE PROCEDURE DSSADM.ACT_CIERRE_DIARIO_COTODIGITAL (
   PFECHA DATE)
IS

--   declare

--   pfecha date := to_date('12/12/2022','dd/mm/yyyy');

--   Start_Date date := to_date('19/10/2021', 'DD/MM/YYYY');
--   End_Date   date := to_date('19/10/2021', 'DD/MM/YYYY');



   CURSOR SUC
   IS
        SELECT *
          FROM LT_SUC_GDM
         WHERE ID_CANAL_DIGITAL = 1 AND ID_SUC NOT IN (200)
      ORDER BY ID_SUC;

   REG_SUC       SUC%ROWTYPE;

   /**********************************************************
   *
   * CATEGORIA 1
   *
   ***********************************************************/
   CURSOR INFO1 (
      VSUC NUMBER)
   IS
      -- PEDIDOS DE SALON ENVIADOS Y ENTREGADOS POR SUCURSALES
      SELECT ROWID CLAVE,
             TO_CHAR (ID_SUC) AS Sucursal,
             '1 - Entregados' AS Categoria,
             '1 - Envio Sucursal' AS Sub_Categoria,
             TO_CHAR (ID_PEDIDO) PEDIDO,
             P.cobro_estadoaprobacion,
             P.mensaje_aprobacion,
             P.pickup,
             P.venta_reserva,
             P.tipo_reserva,
             P.id_estado_pedido,
             P.id_estado_pedido_original,
             substr(banda,0,2)||':'||substr(banda,3)||' hs.' banda
        FROM AG_PEDIDOS_COTODIGITAL P
       WHERE     PEDIDO_PERIODO = 1
             AND DIA_LOGISTICO = pfecha
             AND ID_SUC = VSUC
             AND P.ID_ESTADO_PEDIDO = 96
             AND P.COBRO_ESTADOAPROBACION = 'APROBADA'
             AND PICKUP = 0
             AND VENTA_RESERVA + TIPO_RESERVA <= 1;

   REG_INFO1     INFO1%ROWTYPE;


   /**********************************************************
   *
   * CATEGORIA 2
   *
   ***********************************************************/
   CURSOR INFO2 (
      VSUC NUMBER)
   IS
      -- PEDIDOS VENTA POR RESERVA ENVIADOS Y ENTREGADOS POR SUCURSALES DE INTERIOR
      SELECT ROWID CLAVE,
             TO_CHAR (ID_SUC) AS Sucursal,
             '2 - Entregados' AS Categoria,
             '1 - Envio Suc. Electro' AS Sub_Categoria,
             TO_CHAR (ID_PEDIDO) PEDIDO,
             P.cobro_estadoaprobacion,
             P.mensaje_aprobacion,
             P.pickup,
             P.venta_reserva,
             P.tipo_reserva,
             P.id_estado_pedido,
             P.id_estado_pedido_original,
             substr(banda,0,2)||':'||substr(banda,3)||' hs.' banda
        FROM AG_PEDIDOS_COTODIGITAL P
       WHERE     PEDIDO_PERIODO = 1
             AND P.ID_SUC = VSUC
             AND DIA_LOGISTICO = PFECHA
             AND P.ID_ESTADO_PEDIDO = 96
             AND P.COBRO_ESTADOAPROBACION = 'APROBADA'
             AND PICKUP = 0
             AND VENTA_RESERVA + TIPO_RESERVA > 1
             AND ID_SUC IN (109, 165, 178, 185, 204, 209);

   REG_INFO2     INFO2%ROWTYPE;


   /**********************************************************
   *
   * CATEGORIA 3
   *
   ***********************************************************/
   CURSOR INFO3 (
      VSUC NUMBER)
   IS
      -- PEDIDOS NO ENTREGADOS NORMALES SIN REPROGRAMAR
      SELECT ROWID CLAVE,
             TO_CHAR (ID_SUC) AS Sucursal,
             '3 - No Entregados' AS Categoria,
             '1 - Sin Reprogramar' AS Sub_Categoria,
             TO_CHAR (ID_PEDIDO) PEDIDO,
             P.cobro_estadoaprobacion,
             P.mensaje_aprobacion,
             P.pickup,
             P.venta_reserva,
             P.tipo_reserva,
             P.id_estado_pedido,
             P.id_estado_pedido_original,
             P.ES_FASTLINE,
             substr(banda,0,2)||':'||substr(banda,3)||' hs.' banda
        FROM AG_PEDIDOS_COTODIGITAL P
       WHERE (    PEDIDO_PERIODO = 1
              AND ID_SUC = VSUC
              AND DIA_LOGISTICO = PFECHA
              AND p.id_estado_pedido NOT IN (96, 999, 990)
              AND VENTA_RESERVA + TIPO_RESERVA <= 1
              AND P.COBRO_ESTADOAPROBACION = 'APROBADA'
              AND PICKUP = 0
              AND NVL (ES_FASTLINE, 1) = 0)
      UNION ALL
      -- PEDIDOS NO ENTREGADOS NORMALES REPROGRAMADOS
      SELECT ROWID CLAVE,
             TO_CHAR (ID_SUC) AS Sucursal,
             '3 - No Entregados' AS Categoria,
             '2 - Reprogramados' AS Sub_Categoria,
             TO_CHAR (ID_PEDIDO) PEDIDO,
             P.cobro_estadoaprobacion,
             P.mensaje_aprobacion,
             P.pickup,
             P.venta_reserva,
             P.tipo_reserva,
             P.id_estado_pedido,
             P.id_estado_pedido_original,
             P.ES_FASTLINE,
             substr(banda,0,2)||':'||substr(banda,3)||' hs.' banda
        FROM AG_PEDIDOS_COTODIGITAL P
       WHERE     (TO_CHAR (ID_PEDIDO) IN
                     (SELECT DISTINCT TO_CHAR (ID_PEDIDO)
                        FROM DATOS_PEDIDO_CAC_RPG
                       WHERE     TO_CHAR (FENTREGAANT) =
                                    (TO_CHAR (P.DIA_LOGISTICO, 'YYYYMMDD'))
                             AND TO_CHAR (FENTREGANEW) >
                                    (TO_CHAR (P.DIA_LOGISTICO, 'YYYYMMDD'))
                             AND TO_CHAR (FINSERT, 'YYYYMMDD') =
                                    TO_CHAR (P.DIA_LOGISTICO, 'YYYYMMDD')))
             AND VENTA_RESERVA + TIPO_RESERVA <= 1
             AND ID_SUC = VSUC
             AND P.id_estado_pedido NOT IN (96, 999, 990)
             AND P.ID_ESTADO_PEDIDO >= 90
             AND DIA_LOGISTICO = PFECHA
             AND PICKUP = 0
      UNION ALL
      -- PEDIDOS ELECTRO SUC INTERIOR NO ENTREGADOS SIN REPROGRAMA
      SELECT ROWID CLAVE,
             TO_CHAR (ID_SUC) AS Sucursal,
             '3 - No Entregados' AS Categoria,
             '3 - Electro Sin Reprogramar' AS Sub_Categoria,
             TO_CHAR (ID_PEDIDO) PEDIDO,
             P.cobro_estadoaprobacion,
             P.mensaje_aprobacion,
             P.pickup,
             P.venta_reserva,
             P.tipo_reserva,
             P.id_estado_pedido,
             P.id_estado_pedido_original,
             P.ES_FASTLINE,
             substr(banda,0,2)||':'||substr(banda,3)||' hs.' banda
        FROM AG_PEDIDOS_COTODIGITAL P
       WHERE     (    PEDIDO_PERIODO = 1
                  AND ID_SUC = VSUC
                  AND DIA_LOGISTICO = PFECHA
                  AND p.id_estado_pedido NOT IN (96, 999, 990)
                  AND VENTA_RESERVA + TIPO_RESERVA > 1
                  AND P.COBRO_ESTADOAPROBACION = 'APROBADA'
                  AND PICKUP = 0
                  AND ID_SUC IN (109, 165, 178, 185, 204, 209))
             AND NVL (ES_FASTLINE, 1) = 0
      UNION ALL
      -- PEDIDOS ELECTRO SUC INTERIOR NO ENTREGADOS REPROGRAMADOS
      SELECT ROWID CLAVE,
             TO_CHAR (ID_SUC) AS Sucursal,
             '3 - No Entregados' AS Categoria,
             '4 - Electro Reprogramados' AS Sub_Categoria,
             TO_CHAR (ID_PEDIDO) PEDIDO,
             P.cobro_estadoaprobacion,
             P.mensaje_aprobacion,
             P.pickup,
             P.venta_reserva,
             P.tipo_reserva,
             P.id_estado_pedido,
             P.id_estado_pedido_original,
             P.ES_FASTLINE,
             substr(banda,0,2)||':'||substr(banda,3)||' hs.' banda
        FROM AG_PEDIDOS_COTODIGITAL P
       WHERE     (TO_CHAR (ID_PEDIDO) IN
                     (SELECT DISTINCT TO_CHAR (ID_PEDIDO)
                        FROM DATOS_PEDIDO_CAC_RPG
                       WHERE     TO_CHAR (FENTREGAANT) =
                                    (TO_CHAR (P.DIA_LOGISTICO, 'YYYYMMDD'))
                             AND TO_CHAR (FENTREGANEW) >
                                    (TO_CHAR (P.DIA_LOGISTICO, 'YYYYMMDD'))
                             AND TO_CHAR (FINSERT, 'YYYYMMDD') =
                                    (TO_CHAR (P.DIA_LOGISTICO, 'YYYYMMDD'))))
             AND VENTA_RESERVA + TIPO_RESERVA > 1
             AND ID_SUC = VSUC
             AND P.id_estado_pedido NOT IN (96, 999, 990)
             AND P.ID_ESTADO_PEDIDO >= 90
             AND DIA_LOGISTICO = PFECHA
             AND PICKUP = 0
             AND ID_SUC IN (109, 165, 178, 185, 204, 209)
      UNION ALL
      -- PEDIDOS CON FAST LINE
      SELECT ROWID CLAVE,
             TO_CHAR (ID_SUC) AS Sucursal,
             '3 - No Entregados' AS Categoria,
             '5 - Fast Line' AS Sub_Categoria,
             TO_CHAR (ID_PEDIDO) PEDIDO,
             P.cobro_estadoaprobacion,
             P.mensaje_aprobacion,
             P.pickup,
             P.venta_reserva,
             P.tipo_reserva,
             P.id_estado_pedido,
             P.id_estado_pedido_original,
             P.ES_FASTLINE,
             substr(banda,0,2)||':'||substr(banda,3)||' hs.' banda
        FROM AG_PEDIDOS_COTODIGITAL P
       WHERE (    PEDIDO_PERIODO = 1
              AND ID_SUC = VSUC
              AND DIA_LOGISTICO = PFECHA
              AND p.id_estado_pedido NOT IN (96, 999, 990)
              AND PICKUP = 0
              AND NVL (ES_FASTLINE, 1) = 1);
   REG_INFO3     INFO3%ROWTYPE;


   /**********************************************************
   *
   * CATEGORIA 4
   *
   ***********************************************************/
   CURSOR INFO4 (
      VSUC NUMBER)
   IS
      -- PEDIDOS CANCELADOS POR PROBLEMA CON TARJETAS NORMALES
      SELECT ROWID CLAVE,
             TO_CHAR (ID_SUC) AS Sucursal,
             '4 - Cancelados' AS Categoria,
             '1 - Normales' AS Sub_Categoria,
             TO_CHAR (ID_PEDIDO) PEDIDO,
             P.cobro_estadoaprobacion,
             P.mensaje_aprobacion,
             P.pickup,
             P.venta_reserva,
             P.tipo_reserva,
             P.id_estado_pedido,
             P.id_estado_pedido_original,
             substr(banda,0,2)||':'||substr(banda,3)||' hs.' banda
        FROM AG_PEDIDOS_COTODIGITAL P
       WHERE     PEDIDO_PERIODO = 1
             AND ID_SUC = VSUC
             AND DIA_LOGISTICO = PFECHA
             AND P.id_estado_pedido <> 96
             AND P.COBRO_ESTADOAPROBACION <> 'APROBADA'
             AND VENTA_RESERVA + TIPO_RESERVA <= 1
      UNION ALL
      -- PEDIDOS ELECTRO SUC INTERIOR CANCELADOS POR PROBLEMA CON TARJETAS
      SELECT ROWID CLAVE,
             TO_CHAR (ID_SUC) AS Sucursal,
             '4 - Cancelados' AS Categoria,
             '2 - Suc. Electro' AS Sub_Categoria,
             TO_CHAR (ID_PEDIDO) PEDIDO,
             P.cobro_estadoaprobacion,
             P.mensaje_aprobacion,
             P.pickup,
             P.venta_reserva,
             P.tipo_reserva,
             P.id_estado_pedido,
             P.id_estado_pedido_original,
             substr(banda,0,2)||':'||substr(banda,3)||' hs.' banda
        FROM AG_PEDIDOS_COTODIGITAL P
       WHERE     PEDIDO_PERIODO = 1
             AND ID_SUC = VSUC
             AND DIA_LOGISTICO = PFECHA
             AND P.id_estado_pedido <> 96
             AND P.COBRO_ESTADOAPROBACION <> 'APROBADA'
             AND VENTA_RESERVA + TIPO_RESERVA > 1
             AND ID_SUC IN (109, 165, 178, 185, 204, 209);

   REG_INFO4     INFO4%ROWTYPE;


   /**********************************************************
   *
   * CATEGORIA 5
   *
   ***********************************************************/
   CURSOR INFO5 (
      VSUC NUMBER)
   IS
      -- PEDIDOS RECUPERADOS CALL CENTER NORMALES
      SELECT ROWID CLAVE,
             TO_CHAR (ID_SUC) AS Sucursal,
             '5 - Pedidos Recuperados Call Center' AS Categoria,
             '1 - Normales' AS Sub_Categoria,
             TO_CHAR (ID_PEDIDO) PEDIDO,
             p.cobro_estadoaprobacion,
             p.mensaje_aprobacion,
             p.pickup,
             p.venta_reserva,
             p.tipo_reserva,
             p.id_estado_pedido,
             p.id_estado_pedido_original,
             substr(banda,0,2)||':'||substr(banda,3)||' hs.' banda
        FROM AG_PEDIDOS_COTODIGITAL P
       WHERE     PEDIDO_PERIODO = 1
             AND ID_SUC = VSUC
             AND DIA_LOGISTICO = PFECHA
             AND p.id_estado_pedido = 96
             AND P.COBRO_ESTADOAPROBACION = 'RECHAZADA'
             AND VENTA_RESERVA + TIPO_RESERVA <= 1
      UNION ALL
      -- PEDIDOS RECUPERADOS CALL CENTER
      SELECT ROWID CLAVE,
             TO_CHAR (ID_SUC) AS Sucursal,
             '5 - Pedidos Recuperados Call Center' AS Categoria,
             '2 - Suc. Electro' AS Sub_Categoria,
             TO_CHAR (ID_PEDIDO) PEDIDO,
             p.cobro_estadoaprobacion,
             p.mensaje_aprobacion,
             p.pickup,
             p.venta_reserva,
             p.tipo_reserva,
             p.id_estado_pedido,
             p.id_estado_pedido_original,
             substr(banda,0,2)||':'||substr(banda,3)||' hs.' banda
        FROM AG_PEDIDOS_COTODIGITAL P
       WHERE     PEDIDO_PERIODO = 1
             AND ID_SUC = VSUC
             AND DIA_LOGISTICO = PFECHA
             AND p.id_estado_pedido = 96
             AND P.COBRO_ESTADOAPROBACION = 'RECHAZADA'
             AND VENTA_RESERVA + TIPO_RESERVA > 1
             AND ID_SUC IN (109, 165, 178, 185, 204, 209);

   REG_INFO5     INFO5%ROWTYPE;


   /**********************************************************
   *
   * CATEGORIA 6
   *
   ***********************************************************/
   CURSOR INFO6 (VSUC NUMBER)
   IS
      -- PEDIDOS DERIVADOS A OTRA SUCURSAL
      SELECT TO_CHAR (SUCURSAL) sucursal,
             '6 - Derivados' AS Categoria,
             '1 - Derivados' AS Sub_Categoria,
             TO_CHAR (NVL (ID_PEDIDO, 0)) PEDIDO
        FROM DATOS_PEDIDO_CAC_DER
       WHERE FINSERT = PFECHA AND SUCURSAL = VSUC;

   REG_INFO6     INFO6%ROWTYPE;


   /**********************************************************
   *
   * CATEGORIA 7
   *
   ***********************************************************/
   CURSOR INFO7 (VSUC NUMBER)
   IS
      -- FALTANTES DE PEDIDOS COBRADOS
      SELECT distinct "sucursal" AS sucursal,
             '7 - Falt.  Prod. Cob. NE.' AS CATEGORIA,
             '1 - Fonocoto' AS Sub_Categoria,
             "fonocoto" FONOCOTO
        FROM interfaz_cotodigital_pnc
       WHERE "fecha" = PFECHA AND "sucursal" = VSUC;

   REG_INFO7     INFO7%ROWTYPE;


   /**********************************************************
   *
   * CATEGORIA 8A
   *
   ***********************************************************/
   CURSOR INFO8A (
      VSUC NUMBER)
   IS
        SELECT DISTINCT
               TO_CHAR (RCD.ID_SUC),
               '8 - Entrega CD',
               'A - Coto Digital',
               COUNT (DISTINCT TO_CHAR (PEDIDO_ID)) pedido,
               COUNT (DISTINCT TO_CHAR (RESERVA_CODIGO)) codigo_reserva
          FROM RPT.rpt_reserva_sucursal R
               INNER JOIN
               (SELECT ID_SUC, CODIGORESERVA, ESTADO
                  FROM DSSADM.bt_env_viaj_despachados
                 WHERE     ID_DIA = pfecha
                       AND ID_SUC = VSUC
                       AND ID_CANAL = 4
                       AND TIPO_OPERACION = 'ENTREGA'
                       AND ESTADO IN ('CF', 'CS')) RCD
                  ON     RCD.CODIGORESERVA = R.RESERVA_CODIGO
                     AND RCD.ID_SUC = R.RESERVA_SUCURSAL
      GROUP BY TO_CHAR (RCD.ID_SUC), '8 - Entrega CD', 'A - Coto Digital';

   REG_INFO8A    INFO8A%ROWTYPE;


   /**********************************************************
   *
   * CATEGORIA 8A - CURSOR PARA IDENTIFICAR LOS PEDIDOS
   *
   ***********************************************************/
   CURSOR INFO8AP (
      VSUC NUMBER)
   IS
      SELECT DISTINCT TO_CHAR (PEDIDO_ID) pedido
        FROM RPT.rpt_reserva_sucursal R
             INNER JOIN
             (SELECT ID_SUC, CODIGORESERVA, ESTADO
                FROM DSSADM.bt_env_viaj_despachados
               WHERE     ID_DIA = PFECHA
                     AND ID_SUC = VSUC
                     AND ID_CANAL = 4
                     AND TIPO_OPERACION = 'ENTREGA'
                     AND ESTADO IN ('CF', 'CS')) RCD
                ON     RCD.CODIGORESERVA = R.RESERVA_CODIGO
                   AND RCD.ID_SUC = R.RESERVA_SUCURSAL;

   REG_INFO8AP   INFO8AP%ROWTYPE;


   /**********************************************************
   *
   * CATEGORIA 8B
   *
   ***********************************************************/
   CURSOR INFO8B (
      VSUC NUMBER)
   IS
        SELECT TO_CHAR (ID_SUC) SUCURSAL,
               '8 - Entrega CD' AS CATEGORIA,
               'B - Venta Totem' AS Sub_Categoria,
               COUNT (DISTINCT TO_CHAR (ID_RESERVA)) RESERVA,
               COUNT (DISTINCT TO_CHAR (CODIGORESERVA)) AS CODIGO_RESERVA
          FROM DSSADM.bt_env_viaj_despachados
         WHERE     ID_CANAL IN (3, 5)
               AND TIPO_OPERACION = 'ENTREGA'
               AND ID_DIA = PFECHA
               AND ID_SUC = VSUC
               AND ESTADO = 'CF'
      GROUP BY TO_CHAR (ID_SUC), '8 - Entrega CD', 'B - Venta Totem';

   REG_INFO8B    INFO8B%ROWTYPE;



   /*****************************************
   *
   * DEFINICION DE VARIABLES
   *
   ******************************************/
   CANTIDAD      NUMBER := 0;
   PCANTIDAD     VARCHAR2 (100);
   DETALLE       VARCHAR2 (3000);
   MARCA         NUMBER := 0;
   CUPO_MAXIMO   NUMBER := 0;
   TOTAL         NUMBER := 0;


    BEGIN
--       while start_date <= trunc(End_Date) loop

--           pfecha := start_date;

       DELETE CIERRE_DIARIO_COTO_DIGITAL
        WHERE ID_DIA = PFECHA;

       OPEN SUC;

       LOOP
          FETCH SUC INTO REG_SUC;

          EXIT WHEN SUC%NOTFOUND;

          MARCA := 0;

          /*
          *  CUPOS DE LA SUCURSAL
          */
          SELECT SUM (cupomaximo)
            INTO CUPO_MAXIMO
            FROM HENTRCUPOSFECHA
           WHERE     IDSUCURSAL = REG_SUC.ID_SUC
                 AND TO_DATE (FECHACUPO, 'yyyymmdd') = PFECHA
                 AND ( HORACUPO IN ('0900','1300','1800') or (HORACUPO = '0700' and IDSUCURSAL = 189)); --Hugo Calero 15/11/2024 Restricción de Cupos



          --        P_CATEGORIA := 'Pedidos Entregados (Env­os Sucursal)';
          --        P_COD_CATEGORIA := '1';
          CANTIDAD := 0;

          OPEN INFO1 (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO1 INTO REG_INFO1;

             EXIT WHEN INFO1%NOTFOUND;
             CANTIDAD := CANTIDAD + 1;

             UPDATE AG_PEDIDOS_COTODIGITAL
                SET ID_CAT_CD = 1
              WHERE ROWID = REG_INFO1.CLAVE;
          END LOOP;

          CLOSE INFO1;

          PCANTIDAD := CANTIDAD;

          INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
               VALUES (PFECHA,
                       REG_SUC.ID_SUC,
                       PCANTIDAD,
                       NULL,
                       NULL,
                       CUPO_MAXIMO,
                       1);



          --        P_CATEGORIA := 'Pedidos Entregados (Envios Suc. Electro)';
          --        P_COD_CATEGORIA := '2';
          CANTIDAD := 0;

          OPEN INFO2 (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO2 INTO REG_INFO2;

             EXIT WHEN INFO2%NOTFOUND;
             CANTIDAD := CANTIDAD + 1;

             UPDATE AG_PEDIDOS_COTODIGITAL
                SET ID_CAT_CD = 2
              WHERE ROWID = REG_INFO2.CLAVE;
          END LOOP;

          CLOSE INFO2;

          PCANTIDAD := CANTIDAD;

          INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
               VALUES (PFECHA,
                       REG_SUC.ID_SUC,
                       PCANTIDAD,
                       NULL,
                       NULL,
                       CUPO_MAXIMO,
                       2);



          --        P_CATEGORIA := 'Pedidos no entregados';
          --        P_COD_CATEGORIA := '3';
          CANTIDAD := 0;

          OPEN INFO3 (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO3 INTO REG_INFO3;

             EXIT WHEN INFO3%NOTFOUND;
             CANTIDAD := CANTIDAD + 1;

             UPDATE AG_PEDIDOS_COTODIGITAL
                SET ID_CAT_CD = 3
              WHERE ROWID = REG_INFO3.CLAVE;
          END LOOP;

          CLOSE INFO3;

          PCANTIDAD := CANTIDAD;

          OPEN INFO3 (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO3 INTO REG_INFO3;

             EXIT WHEN INFO3%NOTFOUND;

             IF REG_INFO3.ES_FASTLINE = 1
             THEN
                DETALLE :=
                      'Pedido: '
                   || REG_INFO3.PEDIDO || ' [' || REG_INFO3.BANDA || ']'
                   || ' FASTLINE '
                   || '- Estado Cobro: '
                   || REG_INFO3.COBRO_ESTADOAPROBACION
                   || ' - Mensaje Cobro: '
                   || REG_INFO3.MENSAJE_APROBACION;
             ELSE
                DETALLE :=
                      'Pedido: '
                   || REG_INFO3.PEDIDO || ' [' || REG_INFO3.BANDA || '] '
                   || '- Estado Cobro: '
                   || REG_INFO3.COBRO_ESTADOAPROBACION
                   || ' - Mensaje Cobro: '
                   || REG_INFO3.MENSAJE_APROBACION;
             END IF;



             INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
                  VALUES (PFECHA,
                          REG_SUC.ID_SUC,
                          PCANTIDAD,
                          DETALLE,
                          NULL,
                          CUPO_MAXIMO,
                          3);
          END LOOP;

          CLOSE INFO3;

          IF CANTIDAD = 0
          THEN
             INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
                  VALUES (PFECHA,
                          REG_SUC.ID_SUC,
                          PCANTIDAD,
                          NULL,
                          NULL,
                          CUPO_MAXIMO,
                          3);
          END IF;



          --        P_CATEGORIA := 'Pedidos cancelados - Por Problemas con Tarjeta (Falta de Fondo | Denegadas)';
          --        P_COD_CATEGORIA := '4';
          CANTIDAD := 0;

          OPEN INFO4 (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO4 INTO REG_INFO4;

             EXIT WHEN INFO4%NOTFOUND;

             SELECT COUNT (*) INTO TOTAL FROM LT_PEDIDO_TICKET WHERE ID_PEDIDO = REG_INFO4.PEDIDO;

             IF TOTAL > 0 THEN 

                 CANTIDAD := CANTIDAD + 1;

                 UPDATE AG_PEDIDOS_COTODIGITAL
                    SET ID_CAT_CD = 4
                  WHERE ROWID = REG_INFO4.CLAVE;

             END IF;

          END LOOP;

          CLOSE INFO4;

          PCANTIDAD := CANTIDAD;

          OPEN INFO4 (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO4 INTO REG_INFO4;

             EXIT WHEN INFO4%NOTFOUND;

             SELECT COUNT (*) INTO TOTAL FROM LT_PEDIDO_TICKET WHERE ID_PEDIDO = REG_INFO4.PEDIDO;

            IF TOTAL > 0 THEN

                 DETALLE :=
                       'Pedido: '
                    || REG_INFO4.PEDIDO || ' [' || REG_INFO4.BANDA || '] '
                    || '- Estado Cobro: '
                    || REG_INFO4.COBRO_ESTADOAPROBACION
                    || ' - Mensaje Cobro: '
                    || REG_INFO4.MENSAJE_APROBACION;

                 INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
                      VALUES (PFECHA,
                              REG_SUC.ID_SUC,
                              PCANTIDAD,
                              DETALLE,
                              NULL,
                              CUPO_MAXIMO,
                              4);

            END IF;

          END LOOP;

          CLOSE INFO4;

          IF CANTIDAD = 0
          THEN
             INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
                  VALUES (PFECHA,
                          REG_SUC.ID_SUC,
                          PCANTIDAD,
                          NULL,
                          NULL,
                          CUPO_MAXIMO,
                          4);
          END IF;



          --        P_CATEGORIA := 'Pedidos Recurperados por Call Center';
          --        P_COD_CATEGORIA := '5';
          CANTIDAD := 0;

          OPEN INFO5 (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO5 INTO REG_INFO5;

             EXIT WHEN INFO5%NOTFOUND;
             CANTIDAD := CANTIDAD + 1;

             UPDATE AG_PEDIDOS_COTODIGITAL
                SET ID_CAT_CD = 5
              WHERE ROWID = REG_INFO5.CLAVE;
          END LOOP;

          CLOSE INFO5;

          PCANTIDAD := CANTIDAD;

          OPEN INFO5 (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO5 INTO REG_INFO5;

             EXIT WHEN INFO5%NOTFOUND;

             DETALLE :=
                   'Pedido: '
                || REG_INFO5.PEDIDO || ' [' || REG_INFO5.BANDA || '] '
                || '- Estado Cobro: '
                || REG_INFO5.COBRO_ESTADOAPROBACION
                || ' - Mensaje Cobro: '
                || REG_INFO5.MENSAJE_APROBACION;

             INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
                  VALUES (PFECHA,
                          REG_SUC.ID_SUC,
                          PCANTIDAD,
                          DETALLE,
                          NULL,
                          CUPO_MAXIMO,
                          5);
          END LOOP;

          CLOSE INFO5;

          IF CANTIDAD = 0
          THEN
             INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
                  VALUES (PFECHA,
                          REG_SUC.ID_SUC,
                          PCANTIDAD,
                          NULL,
                          NULL,
                          CUPO_MAXIMO,
                          5);
          END IF;



          --        P_CATEGORIA := 'Pedidos Derivados';
          --        P_COD_CATEGORIA := '6';
          CANTIDAD := 0;

          OPEN INFO6 (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO6 INTO REG_INFO6;

             EXIT WHEN INFO6%NOTFOUND;
             CANTIDAD := CANTIDAD + 1;

             UPDATE AG_PEDIDOS_COTODIGITAL
                SET ID_CAT_CD = 6
              WHERE     ID_PEDIDO = REG_INFO6.PEDIDO
                    AND ID_SUC = REG_SUC.ID_SUC
                    AND DIA_LOGISTICO = PFECHA
                    AND ID_CAT_CD = 0;
          END LOOP;

          CLOSE INFO6;

          PCANTIDAD := CANTIDAD;

          INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
               VALUES (PFECHA,
                       REG_SUC.ID_SUC,
                       PCANTIDAD,
                       NULL,
                       NULL,
                       CUPO_MAXIMO,
                       6);



          --        P_CATEGORIA := 'Faltantes de Productos Cobrados No Entregados';
          --        P_COD_CATEGORIA := '7';
          CANTIDAD := 0;

          OPEN INFO7 (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO7 INTO REG_INFO7;

             EXIT WHEN INFO7%NOTFOUND;
             CANTIDAD := CANTIDAD + 1;
          END LOOP;

          CLOSE INFO7;

          PCANTIDAD := CANTIDAD;

          OPEN INFO7 (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO7 INTO REG_INFO7;

             EXIT WHEN INFO7%NOTFOUND;

             DETALLE := REG_INFO7.FONOCOTO;

             INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
                  VALUES (PFECHA,
                          REG_SUC.ID_SUC,
                          PCANTIDAD,
                          DETALLE,
                          NULL,
                          CUPO_MAXIMO,
                          7);
          END LOOP;

          CLOSE INFO7;

          IF CANTIDAD = 0
          THEN
             INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
                  VALUES (PFECHA,
                          REG_SUC.ID_SUC,
                          PCANTIDAD,
                          NULL,
                          NULL,
                          CUPO_MAXIMO,
                          7);
          END IF;



          --        P_CATEGORIA := 'CD - Entrega Digital';
          --        P_COD_CATEGORIA := '8A';
          MARCA := 0;

          OPEN INFO8A (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO8A INTO REG_INFO8A;

             EXIT WHEN INFO8A%NOTFOUND;

             PCANTIDAD :=
                   REG_INFO8A.PEDIDO
                || ' Pedidos ('
                || REG_INFO8A.codigo_reserva
                || ' Reservas del CD)';

             INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
                  VALUES (PFECHA,
                          REG_SUC.ID_SUC,
                          PCANTIDAD,
                          NULL,
                          NULL,
                          CUPO_MAXIMO,
                          8);

             MARCA := 1;
          END LOOP;

          CLOSE INFO8A;

          IF MARCA = 0
          THEN
             INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
                  VALUES (PFECHA,
                          REG_SUC.ID_SUC,
                          '0',
                          NULL,
                          NULL,
                          CUPO_MAXIMO,
                          8);
          END IF;

          OPEN INFO8AP (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO8AP INTO REG_INFO8AP;

             EXIT WHEN INFO8AP%NOTFOUND;

             UPDATE AG_PEDIDOS_COTODIGITAL
                SET ID_CAT_CD = 8
              WHERE     ID_PEDIDO = REG_INFO8AP.PEDIDO
                    AND ID_SUC = REG_SUC.ID_SUC
                    AND DIA_LOGISTICO = PFECHA
                    AND ID_CAT_CD = 0;
          END LOOP;

          CLOSE INFO8AP;



          --        P_CATEGORIA := 'CD - Entrega Totem';
          --        P_COD_CATEGORIA := '8B';
          MARCA := 0;

          OPEN INFO8B (REG_SUC.ID_SUC);

          LOOP
             FETCH INFO8B INTO REG_INFO8B;

             EXIT WHEN INFO8B%NOTFOUND;

             PCANTIDAD := REG_INFO8B.RESERVA || ' Reservas';

             INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
                  VALUES (PFECHA,
                          REG_SUC.ID_SUC,
                          PCANTIDAD,
                          NULL,
                          NULL,
                          CUPO_MAXIMO,
                          9);

             MARCA := 1;

             UPDATE AG_PEDIDOS_COTODIGITAL
                SET ID_CAT_CD = 9
              WHERE     ID_PEDIDO = REG_INFO8A.PEDIDO
                    AND ID_SUC = REG_SUC.ID_SUC
                    AND DIA_LOGISTICO = PFECHA
                    AND ID_CAT_CD = 0;
          END LOOP;

          CLOSE INFO8B;

          IF MARCA = 0
          THEN
             INSERT INTO CIERRE_DIARIO_COTO_DIGITAL
                  VALUES (PFECHA,
                          REG_SUC.ID_SUC,
                          '0',
                          NULL,
                          NULL,
                          CUPO_MAXIMO,
                          9);
          END IF;
       END LOOP;

       CLOSE SUC;

       COMMIT;


       parche_cdcd(pfecha);


--       start_date := start_date + 1;
--    end loop;


    END;

/*select * 
from dba_objects
where object_name='ACT_CIERRE_DIARIO_COTODIGITAL'
and owner='DSSADM';

select * from dba_synonyms
where synonym_name='ACT_CIERRE_DIARIO_COTODIGITAL';*/
/