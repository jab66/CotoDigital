CREATE OR REPLACE PROCEDURE DSSADM.ACT_COMU_BTCFTICKET (PFECHA DATE) IS

--DECLARE

CURSOR TICKET IS
SELECT * FROM LT_PEDIDO_TICKET 
WHERE ID_DIA = PFECHA AND COMUNIDAD IS NOT NULL; 

BEGIN

    FOR TK IN TICKET LOOP

        UPDATE BT_CF_TICKET SET ID_CRED_COMUNIDAD = TK.COMUNIDAD
         WHERE ID_DIA = TK.ID_DIA 
           AND ID_SUC = TK.ID_SUC
           AND ID_TERMINAL = TK.TERMINAL 
           AND ID_TRANSACCION = TK.TRANSACCION;
           
    END LOOP;

    COMMIT;

END;
/