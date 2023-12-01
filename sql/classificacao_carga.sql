
DROP TYPE IF EXISTS TY_CLASSIFICACAO_CARGA CASCADE;


CREATE TYPE TY_CLASSIFICACAO_CARGA AS (
  ID          NUMERIC(4)    ,
  CARGA       VARCHAR(200)  , 
  POTMAX      NUMERIC(17,4) ,
  POTMIN      NUMERIC(17,4) ,
  CONSUMO     NUMERIC(17,6) ,
  KWH         NUMERIC(17,6) , 
  SLOT        NUMERIC(2)    ,
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
  _rPOTMAX   NUMERIC(17,6) ;
  _rPOTMIN   NUMERIC(17,6) ;
  _rCONSUMO  NUMERIC(17,6) ;
  _rPOTMED   NUMERIC(17,6) ;
  _rVLKWH    NUMERIC(17,6) ;
  _rKWH      NUMERIC(17,6) ;
  _rSTATUS   NUMERIC(1)    ; 
  
BEGIN
  
  CREATE TEMPORARY TABLE TB_CLASSIFICACAO_CARGA (
    CARGA       VARCHAR(200)  , 
    POTMAX      NUMERIC(17,4) ,
    POTMIN      NUMERIC(17,4) ,
    CONSUMO     NUMERIC(17,4) ,
    STATUSCARGA NUMERIC(1)     --1 CONSUMINDO, 2 DESATIVADA
  ) ON COMMIT DROP;
  
  -- RECUPERA O VALOR DO kWh 
    SELECT
      COALESCE(VALORKWH, 0.00)
    INTO       
      _rVLKWH 
    FROM 
      PARAMETRO 
    LIMIT 1;

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
    AND IDMODULO = ENT_ID_MODULO
    AND SLOT =  _rROW_SLOT.IDSLOT;
    
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
    AND SLOT =  _rROW_SLOT.IDSLOT;
   
    -- CALCULA A PONTENCIA CONSUMIDA EM KW  
    SELECT
      --recupera a média da potência ao longo do tempo que ficou ligada  
      (COALESCE(AVG(POTENCIA), 0.00)/1000)
    INTO       
      _rPOTMED 
    FROM 
      CONSUMO 
    WHERE 
        DTINC BETWEEN COALESCE(_rROW_SLOT.DTCAL, _rROW_SLOT.DTINI) AND COALESCE(_rROW_SLOT.DTFIM, NOW())   
    AND IDMODULO = ENT_ID_MODULO
    AND SLOT = _rROW_SLOT.IDSLOT;
   
    -- CALCULA O kWh 
    SELECT
     _rPOTMED *
      -- recupera a quantidade proporcional de horas 
      COALESCE((EXTRACT(EPOCH FROM (COALESCE(_rROW_SLOT.DTFIM, NOW())  - _rROW_SLOT.DTINI)) / 3600), 0.00)
    INTO       
      _rKWH 
    FROM 
      CONSUMO 
    WHERE 
        DTINC BETWEEN COALESCE(_rROW_SLOT.DTCAL, _rROW_SLOT.DTINI) AND COALESCE(_rROW_SLOT.DTFIM, NOW())  
    AND IDMODULO = ENT_ID_MODULO
    AND SLOT =  _rROW_SLOT.IDSLOT;

    -- CALCULA O VALOR kWh CONSUMIDA EM KWH  
    SELECT
     _rPOTMED *
      -- recupera a quantidade proporcional de horas 
      COALESCE((EXTRACT(EPOCH FROM (COALESCE(_rROW_SLOT.DTFIM, NOW())  - _rROW_SLOT.DTINI)) / 3600), 0.00) *
      _rVLKWH
    INTO       
      _rCONSUMO 
    FROM 
      CONSUMO 
    WHERE 
        DTINC BETWEEN COALESCE(_rROW_SLOT.DTCAL, _rROW_SLOT.DTINI) AND COALESCE(_rROW_SLOT.DTFIM, NOW())  
    AND IDMODULO = ENT_ID_MODULO
    AND SLOT =  _rROW_SLOT.IDSLOT;

    _rSTATUS  := _rROW_SLOT.STATUS; 
    IF EXISTS (SELECT 1 FROM CLASSIFICACAO WHERE POTMIN <= _rPOTMED AND POTMAX >= _rPOTMED AND IDMODULO = ENT_ID_MODULO) THEN
      UPDATE 
        CLASSIFICACAO
      SET   
        CONSUMO = CONSUMO + COALESCE(_rCONSUMO, 0)   ,
        STATUSCARGA = _rROW_SLOT.STATUS ,
        KWH = COALESCE(KWH, 0) +_rKWH,
        SLOT = _rROW_SLOT.IDSLOT
      WHERE 
          POTMIN <= _rPOTMED 
      AND POTMAX >= _rPOTMED
      AND IDMODULO = ENT_ID_MODULO;

      PERFORM SP_CONTROLE_SLOT('U', _rROW_SLOT.IDSLOT);
    END IF;  
  END LOOP; 
  
  FOR R IN 
    SELECT
      ID          ,
      CARGA       ,
      POTMAX      ,
      POTMIN      ,
      CONSUMO     ,
      KWH         ,
      CASE 
        WHEN STATUSCARGA = 1 THEN
          SLOT        
        ELSE 
          NULL
      END AS SLOT,
      STATUSCARGA 
    FROM
      CLASSIFICACAO
    WHERE 
      IDMODULO = ENT_ID_MODULO  
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
