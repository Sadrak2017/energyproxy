
DROP TYPE IF EXISTS TY_CLASSIFICACAO_CARGA CASCADE;


CREATE TYPE TY_CLASSIFICACAO_CARGA AS (
  ID          NUMERIC(4)    ,
  CARGA       VARCHAR(200)  , 
  POTMAX      NUMERIC(17,4) ,
  POTMIN      NUMERIC(17,4) ,
  CONSUMO     NUMERIC(17,6) ,
  STATUSCARGA NUMERIC(1)     --1 CONSUMINDO, 2 DESATIVADA
);

--DROP FUNCTION SP_CLASSIFICACAO_CARGA(); 

CREATE FUNCTION SP_CLASSIFICACAO_CARGA (
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
RETURNS SETOF TY_CLASSIFICACAO_CARGA

AS $BODY$
DECLARE
  R  TY_CLASSIFICACAO_CARGA%Rowtype;
  i          NUMERIC(2); 
  _rROW_SLOT RECORD;  
  _rPOTMAX   NUMERIC(17,4) ;
  _rPOTMIN   NUMERIC(17,4) ;
  _rCONSUMO  NUMERIC(17,6) ;
  _rPOTMED   NUMERIC(17,4) ;
  _rQTDEPOT  NUMERIC(17,4) ;
  _rSTATUS   NUMERIC(1)    ; 
  
BEGIN
  
  CREATE TEMPORARY TABLE TB_CLASSIFICACAO_CARGA (
    CARGA       VARCHAR(200)  , 
    POTMAX      NUMERIC(17,4) ,
    POTMIN      NUMERIC(17,4) ,
    CONSUMO     NUMERIC(17,4) ,
    STATUSCARGA NUMERIC(1)     --1 CONSUMINDO, 2 DESATIVADA
  ) ON COMMIT DROP;
  
  /*--------------------------------------------------------------------------*/
  /* Etapa 001 - Recupera os valores de potência gravado na tabela CONSUMO    */
  /*--------------------------------------------------------------------------*/
  FOR _rROW_SLOT IN 
    SELECT 
      IDSLOT ,
      STATUS ,
      DTINI  ,
      DTFIM  ,
      DTCAL
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
    AND IDMODULO = ENT_ID_MODULO;  
    -- RECUPERA A POTÊNCIA MÍNIMA EM KW
    SELECT
      COALESCE(MIN(POTENCIA), 0.00)/1000
    INTO       
      _rPOTMIN 
    FROM 
      CONSUMO 
    WHERE 
      DTINC BETWEEN _rROW_SLOT.DTINI AND COALESCE(_rROW_SLOT.DTFIM, NOW())
    AND IDMODULO = ENT_ID_MODULO; 

    -- RECUPERA QUANTIDADE DE POTENCIA ENVIADA NO TEMPO QUE FICOU CONECTADA
    SELECT
      CASE
        WHEN COUNT(*) = 0 THEN 
          1 
        ELSE 
          COUNT(*)
      END
    INTO       
      _rQTDEPOT 
    FROM 
      CONSUMO 
    WHERE 
        DTINC BETWEEN COALESCE(_rROW_SLOT.DTCAL, _rROW_SLOT.DTINI) AND COALESCE(_rROW_SLOT.DTFIM, NOW())  
    AND IDMODULO = ENT_ID_MODULO;   
      
    -- CALCULA A PONTENCIA CONSUMIDA EM KW  
    SELECT
      --recupera a média da potência ao longo do tempo que ficou ligada  
      (COALESCE(SUM(POTENCIA)/_rQTDEPOT, 0.00)/1000)
    INTO       
      _rPOTMED 
    FROM 
      CONSUMO 
    WHERE 
        DTINC BETWEEN COALESCE(_rROW_SLOT.DTCAL, _rROW_SLOT.DTINI) AND COALESCE(_rROW_SLOT.DTFIM, NOW())   
    AND IDMODULO = ENT_ID_MODULO;
  
    -- CALCULA A PONTENCIA CONSUMIDA EM KWH  
    SELECT
      COALESCE(_rPOTMED * 
      -- recupera a quantidade proporcional de horas 
      (EXTRACT(EPOCH FROM (COALESCE(_rROW_SLOT.DTFIM, NOW())  - _rROW_SLOT.DTINI)) / 3600), 0.00)
    INTO       
      _rCONSUMO 
    FROM 
      CONSUMO 
    WHERE 
        DTINC BETWEEN COALESCE(_rROW_SLOT.DTCAL, _rROW_SLOT.DTINI) AND COALESCE(_rROW_SLOT.DTFIM, NOW())  
    AND IDMODULO = ENT_ID_MODULO;

    _rSTATUS  := _rROW_SLOT.STATUS; 
    
    IF EXISTS (SELECT 1 FROM CLASSIFICACAO WHERE POTMIN >= _rPOTMED AND POTMAX <= _rPOTMED) THEN
    
      UPDATE 
        CLASSIFICACAO
      SET   
        CONSUMO = CONSUMO + _rCONSUMO   ,
        STATUSCARGA = _rROW_SLOT.STATUS 
      WHERE 
          POTMIN >= _rPOTMED 
      AND POTMAX <= _rPOTMED;  
      

    END IF;  
  END LOOP;
  
  FOR R IN 
    SELECT
      ID          ,
      CARGA       ,
      POTMAX      ,
      POTMIN      ,
      CONSUMO     ,
      STATUSCARGA 
    FROM
      CLASSIFICACAO
    ORDER BY 
      ID 
    ASC     
    
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
