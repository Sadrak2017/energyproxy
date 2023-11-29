
DROP TYPE IF EXISTS TY_DADOS_CARGA CASCADE;

CREATE TYPE TY_DADOS_CARGA AS (
  POTMAX      NUMERIC(17,4) ,
  POTMIN      NUMERIC(17,4) ,
  SLOT        NUMERIC(1)     
);

--DROP FUNCTION SP_DADOS_CARGA(); 

CREATE FUNCTION SP_DADOS_CARGA (
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  :: SISTEMA    : Energy Proxy                                                 ::
  :: MÓDULO     : 1.0.0                                                        ::
  :: UTILIZ. POR: index.ts                                                     ::
  :: OBSERVAÇÃO :                                                              ::
  :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
   /*-------------------------------------------------------------------------------
  DESCRIÇÃO DA FUNCIONALIDADE:
  
  Verifica se os dados da carga conectada pertence a uma carga já cadastrada
  -------------------------------------------------------------------------------*/
  ENT_ID_MODULO  NUMERIC(9)    /* ID do módulo                                   */
)
RETURNS SETOF TY_DADOS_CARGA

AS $BODY$
DECLARE
  R  TY_DADOS_CARGA%Rowtype;
  _rROW_SLOT RECORD;  
  _rPOTMAX   NUMERIC(17,4) ;
  _rPOTMIN   NUMERIC(17,4) ;
  _rSLOT     NUMERIC(2) ; 
  
BEGIN

  /*--------------------------------------------------------------------------*/
  /* Etapa 001 - Recupera os valores de potência gravado na tabela CONSUMO    */
  /*--------------------------------------------------------------------------*/
  FOR _rROW_SLOT IN 
    SELECT 
      IDSLOT ,
      STATUS ,
      DTINI  ,
      DTFIM  
    FROM 
      SLOTCONTROL
    WHERE 
      STATUS = 1  
  LOOP
    -- RECUPERA A POTENCIA MÁXIMA EM KW
    SELECT
      COALESCE(MAX(POTENCIA), 0.00)/1000
    INTO       
      _rPOTMAX 
    FROM 
      CONSUMO 
    WHERE 
        DTINC BETWEEN _rROW_SLOT.DTINI AND COALESCE(_rROW_SLOT.DTFIM, NOW())   
    AND IDMODULO = ENT_ID_MODULO
    AND SLOT = _rROW_SLOT.IDSLOT;
     
    -- RECUPERA A POTÊNCIA MÍNIMA EM KW
    SELECT
      COALESCE(MIN(POTENCIA), 0.00)/1000
    INTO       
      _rPOTMIN 
    FROM 
      CONSUMO 
    WHERE 
        DTINC BETWEEN _rROW_SLOT.DTINI AND COALESCE(_rROW_SLOT.DTFIM, NOW()) 
    AND IDMODULO = ENT_ID_MODULO
    AND SLOT = _rROW_SLOT.IDSLOT;

    _rSLOT = _rROW_SLOT.IDSLOT;

  END LOOP;

  FOR R IN 
    SELECT
      COALESCE(_rPOTMAX,0)    ,
      COALESCE(_rPOTMIN,0)    ,
      _rSLOT       
  LOOP
    RETURN NEXT R;
  END LOOP;
  RETURN;

/*-------------------------------------------------------------------------------
  RESULT SET:
  HORA        NUMERIC(2)      HORA 
  POTENCIA    NUMERIC(17,2)   POTENCIA ACUMULADA POR HORA
---------------------------------------------------------------------------*/
END;
$BODY$ LANGUAGE PLPGSQL;
