CREATE OR REPLACE PROCEDURE DSSADM.ACT_LT_PEDIDO_TICKET2 (P_FECHA IN DATE) AS

BEGIN

    DELETE LT_PEDIDO_TICKET where id_dia = P_FECHA;

    INSERT INTO LT_PEDIDO_TICKET (ID_PEDIDO, ID_DIA, TERMINAL,
                                  TRANSACCION, ID_SUC, MONTO_TICKET, LINEAS_TICKET, UNIDADES) (  
       SELECT  TO_NUMBER(SUBSTR(A.CRESOPED,6)) PEDIDO, 
                A.FECHAPRO ID_DIA,
                A.CTERMINL TERMINAL, 
                A.NCTRTERM TRANSACCION, 
                A.CNCENTRO ID_SUC, 
                SUM(DECODE(c.ctipvent,'VEN', c.iltrimpo, c.iltrimpo  * -1)) MONTO_TICKET,
                COUNT(1) LINEAS_TICKET,
                SUM(DECODE(c.ctipvent,'VEN', c.qltmedid, c.qltmedid  * -1)) UNIDADES
         FROM   T7744400_BACKUP a, 
                T7740900_BACKUP B,
                t7743100_backup c,
                lt_producto_dw d
         WHERE  A.FECHAPRO = B.FECHAPRO 
            AND A.CTERMINL = B.CTERMINL 
            AND A.NCTRTERM = B.NCTRTERM
            AND A.FECHAPRO = C.FECHAPRO 
            AND A.CTERMINL = C.CTERMINL 
            AND A.NCTRTERM = C.NCTRTERM
            AND C.CARTREFE = D.ID_PRODUCTO
            AND D.ID_DPTO_GDM  NOT IN (10701051, 10707098, 10707099, 10708105, 10701106,10708110)            
            AND A.FECHAPRO = P_FECHA
            AND SUBSTR(CRESOPED,1,5) = '37010'
        GROUP BY  TO_NUMBER(SUBSTR(A.CRESOPED,6)), 
                A.FECHAPRO,
                A.CTERMINL, 
                A.NCTRTERM, 
                A.CNCENTRO 
                );

    COMMIT;

END;
/