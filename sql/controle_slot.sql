
--DROP FUNCTION SP_CONTROLE_SLOT(); 

CREATE FUNCTION SP_CONTROLE_SLOT (
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  :: SISTEMA    : Energy Proxy                                                 ::
  :: MÓDULO     : 1.0.0                                                        ::
  :: UTILIZ. POR: index.ts                                                     ::
  :: OBSERVAÇÃO :                                                              ::
  :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
   /*-------------------------------------------------------------------------------
  DESCRIÇÃO DA FUNCIONALIDADE:
  
  INICIALIZA OU FINALIZA o STATUS DA CARGA 
  -------------------------------------------------------------------------------*/
  ENT_ID_OPER CHAR(1)  ,    /* I - Iniciliza , F - Finaliza                      */
  ENT_ID_SLOT NUMERIC(1)    /* ID do SLOT                                        */
)
RETURNS VOID
AS $BODY$
DECLARE

BEGIN

  IF ENT_ID_OPER = 'I' THEN
    IF NOT EXISTS(SELECT 1 FROM SLOTCONTROL WHERE idSlot = ENT_ID_SLOT AND STATUS = 1) THEN
      INSERT INTO SLOTCONTROL VALUES(
        (SELECT COALESCE(MAX(ID),0) +1 FROM SLOTCONTROL),
        ENT_ID_SLOT,
        1     ,   -- status 1: Em operação!!!
        NOW() ,   -- Data início
        null  ,   -- Data Fim
        null      -- Data calculo
      );
    END IF;
  
  ELSIF ENT_ID_OPER = 'F' THEN
    UPDATE 
      SLOTCONTROL 
    SET DTFIM = NOW(), 
        STATUS = 2 
    WHERE
        IDSLOT = ENT_ID_SLOT 
    AND STATUS = 1 
    AND dtfim IS NULL;
    
    UPDATE 
      CLASSIFICACAO
    SET   
      STATUSCARGA = 2
    WHERE 
      SLOT = ENT_ID_SLOT;  
      
  ELSIF ENT_ID_OPER = 'U' THEN
    
    UPDATE 
      SLOTCONTROL 
    SET DTCAL = NOW()
    WHERE
        IDSLOT = ENT_ID_SLOT 
    AND STATUS = 1;
  
  END IF;

RETURN;

END;
$BODY$ LANGUAGE PLPGSQL;
