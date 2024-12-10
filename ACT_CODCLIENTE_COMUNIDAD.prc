CREATE OR REPLACE PROCEDURE DSSADM.ACT_CODCLIENTE_COMUNIDAD (P_FECHA DATE) IS

--P_FECHA DATE := to_date('07/02/2023','dd/mm/yyyy');

DESDE DATE := P_FECHA - 1;
HASTA DATE := P_FECHA;

CURSOR C1 IS 
SELECT * FROM LT_PEDIDO_TICKET 
WHERE ID_DIA BETWEEN DESDE AND HASTA;

REG_C1 C1%ROWTYPE;

COD_CLIENTE VARCHAR2(150);
NUM_COMUNIDAD VARCHAR2(150);
PNACION VARCHAR2(150);
CLIENTE_CANAL VARCHAR2(150);


TYPE TYPE4 IS RECORD (  NUMERO VARCHAR2(150), tipo number ); 
V_TYPE4 TYPE4;

TYPE C_LIST4 IS TABLE OF TYPE4 INDEX BY VARCHAR2(125);
LISTA4 C_LIST4;

CURSOR C4 IS
SELECT  U.ID ID_CLIENTE,  TF.NUMERO, tf.idtipo tipo, TF.IDTIPO||U.ID CLAVE
FROM  ATG_C_USER_SNAP U
  INNER JOIN ATG_C_TARJETAFIDELIZADA_SNAP TF ON U.ID = TF.IDCLIENTE 
  INNER JOIN ATG_C_TARJETAFIDELIZADATIPO_SNAP TFT ON TFT.ID = TF.IDTIPO AND TFT.CODIGO = TF.TIPO;


CLAVE4 varchar2(125);  

CURSOR COMUNIDAD IS
SELECT A.*, LENGTH(COMUNIDAD) 
FROM LT_PEDIDO_TICKET A 
WHERE COMUNIDAD IS NOT NULL AND LENGTH(COMUNIDAD) <> 19 
ORDER BY ID_DIA DESC;

NUMERO_COMUNIDAD VARCHAR2(150);

BEGIN

    -- CARGAR TYPE4
    FOR F IN C4 LOOP
        V_TYPE4.NUMERO :=  F.NUMERO;
        V_TYPE4.TIPO := F.TIPO;
        LISTA4(F.CLAVE) := V_TYPE4;  
    END LOOP;


    -- se limpian los campos     
    UPDATE LT_PEDIDO_TICKET SET CODIGO_CLIENTE = NULL, COMUNIDAD = NULL, LANACION = NULL
            WHERE id_dia BETWEEN DESDE AND HASTA;
    COMMIT;

    -- apertura cursor principal 
    OPEN C1;
    LOOP FETCH C1 INTO REG_C1;
        EXIT WHEN C1%NOTFOUND;

        BEGIN
        
            -- obtener el codigo de cliente
            -- Atencion: se encontro un pedido asociado a dos clientes distintos,
            --           por eso se aplica el fetch first aunque tenga
            --          la funcion distinct  
            SELECT  DISTINCT SUBSTR(CODIGO_CLIENTE,1,16) CODIGO_CLIENTE 
            INTO COD_CLIENTE
            FROM AG_PEDIDOS_COTODIGITAL WHERE ID_PEDIDO = REG_C1.ID_PEDIDO
            FETCH FIRST 1 ROWS ONLY;

            UPDATE LT_PEDIDO_TICKET SET CODIGO_CLIENTE = COD_CLIENTE
            WHERE id_dia = REG_C1.ID_DIA AND ID_PEDIDO = REG_C1.ID_PEDIDO;
        
        EXCEPTION
        
        WHEN NO_DATA_FOUND THEN
        
            BEGIN
                SELECT SUBSTR(CLIENTE,1,16) 
                INTO COD_CLIENTE FROM DG_TCONCILIACION 
                WHERE IDPEDIDO = REG_C1.ID_PEDIDO;

                UPDATE LT_PEDIDO_TICKET SET CODIGO_CLIENTE = COD_CLIENTE
                WHERE ID_DIA = REG_C1.ID_DIA AND ID_PEDIDO = REG_C1.ID_PEDIDO;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                COD_CLIENTE := NULL;
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20001, 'Fecha Proceso = ' || P_FECHA || ' - ' || SQLERRM);
            END; 
                        
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Fecha Proceso = ' || P_FECHA || ' - ' ||'Pedido = ' || REG_C1.ID_PEDIDO || ' - ' || SQLERRM);
        END;

        IF COD_CLIENTE IS NOT NULL THEN 
            BEGIN
                -- OBTENER EL ID_CLIENTE_CANAL PARA BUSCAR EN ATG         
                SELECT  ID_CLIENTE_CANAL INTO CLIENTE_CANAL 
                FROM CLIENTE_CANAL_CAC
                        WHERE CODIGO = COD_CLIENTE;        

                -- club lanacion
                CLAVE4 := '1'||CLIENTE_CANAL;
                IF LISTA4.EXISTS(CLAVE4) THEN
                    UPDATE LT_PEDIDO_TICKET SET LANACION = LISTA4(CLAVE4).NUMERO
                    WHERE id_dia = REG_C1.ID_DIA AND ID_PEDIDO = REG_C1.ID_PEDIDO;
                END IF;

                -- COMUNIDAD 
                CLAVE4 := '2'||CLIENTE_CANAL;
                IF LISTA4.EXISTS(CLAVE4) THEN
                    UPDATE LT_PEDIDO_TICKET SET COMUNIDAD = LISTA4(CLAVE4).NUMERO
                    WHERE id_dia = REG_C1.ID_DIA AND ID_PEDIDO = REG_C1.ID_PEDIDO;
                END IF;

                
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN 
                RAISE_APPLICATION_ERROR(-20003, 'Fecha Proceso = ' || P_FECHA || ' - ' ||'Cliente = '||COD_CLIENTE||' - '||SQLERRM);
            END;
        END IF;

    END LOOP;
    CLOSE C1;

    COMMIT;


    --
    -- SE CONTROLA Y ACTUALIZA EL CODIGO DE COMUNIDAD, EL MISMO TIENE UNA LONGITUD DE 19 DIGITOS
    --
    FOR COMU IN COMUNIDAD LOOP
     
        BEGIN
     
            SELECT  numero INTO NUMERO_COMUNIDAD
            FROM  ATG_C_USER_SNAP U
              INNER JOIN ATG_C_TARJETAFIDELIZADA_SNAP TF ON U.ID = TF.IDCLIENTE 
              INNER JOIN ATG_C_TARJETAFIDELIZADATIPO_SNAP TFT ON TFT.ID = TF.IDTIPO AND TFT.CODIGO = TF.TIPO
              WHERE U.ID = ( SELECT  ID_CLIENTE_CANAL FROM CLIENTE_CANAL_CAC 
                            WHERE CODIGO =
                              (SELECT  DISTINCT SUBSTR(CODIGO_CLIENTE,1,16) CODIGO_CLIENTE 
                              FROM AG_PEDIDOS_COTODIGITAL WHERE ID_PEDIDO = COMU.ID_PEDIDO))
                              AND TF.IDTIPO = 2
                   and length(numero) = 19;           
         
            UPDATE LT_PEDIDO_TICKET SET COMUNIDAD = NUMERO_COMUNIDAD WHERE ID_PEDIDO = COMU.ID_PEDIDO;

        EXCEPTION
        WHEN OTHERS THEN
            NULL;
        END; 
     
    END LOOP;

    COMMIT;

    UPDATE LT_PEDIDO_TICKET SET COMUNIDAD = NULL WHERE LENGTH(COMUNIDAD) <> 19;

    COMMIT;
    


END;
/