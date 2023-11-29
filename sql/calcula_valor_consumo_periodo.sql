
DROP TYPE IF EXISTS TY_CALCULA_VALOR_CONSUMO_PERIODO  CASCADE;

CREATE TYPE TY_CALCULA_VALOR_CONSUMO_PERIODO  AS (
  dia        NUMERIC(17,3),
  semana     NUMERIC(17,3),
  mes        NUMERIC(17,3),
  ano        NUMERIC(17,3), 
  total      NUMERIC(17,3)
);

CREATE FUNCTION SP_CALCULA_VALOR_CONSUMO_PERIODO (
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  :: SISTEMA    : Energy Proxy                                                 ::
  :: MÓDULO     : 1.0.0                                                        ::
  :: UTILIZ. POR: index.ts                                                     ::
  :: OBSERVAÇÃO :                                                              ::
  :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
   /*-------------------------------------------------------------------------------
  DESCRIÇÃO DA FUNCIONALIDADE:
  
  Calula valor do consumo em R$ de acordo com o valor do kwh parametrizado
  -------------------------------------------------------------------------------*/
  ENT_ID_MODULO  NUMERIC(9)    /* ID do módulo                                   */
)
RETURNS SETOF TY_CALCULA_VALOR_CONSUMO_PERIODO 

AS $BODY$
DECLARE
  R  TY_CALCULA_VALOR_CONSUMO_PERIODO %Rowtype;
  _rROW_SLOT  RECORD;  
  _rCONSUMO   NUMERIC(17,6) ;
  _rCONSUMOD  NUMERIC(17,6) ;
  _rCONSUMOS  NUMERIC(17,6) ;
  _rCONSUMOM  NUMERIC(17,6) ;
  _rCONSUMOA  NUMERIC(17,6) ;
  _rPOTMED    NUMERIC(17,4) ;
  _rVLKWH     NUMERIC(17,2) ;
  i  NUMERIC(2); 
  
BEGIN
  
  CREATE TEMPORARY TABLE TB_CONSUMO (
    HORA       NUMERIC(2,0)     NULL,
    POTENCIA   NUMERIC(17,4)    NULL
  ) ON COMMIT DROP;
  
  /*--------------------------------------------------------------------------*/
  /* Etapa 001 - Recupera os valores de potência gravado na tabela CONSUMO    */
  /*--------------------------------------------------------------------------*/
  
   -- RECUPERA O VALOR DO kWh 
    SELECT
      COALESCE(VALORKWH, 0.00)
    INTO       
      _rVLKWH 
    FROM 
      PARAMETRO 
    LIMIT 1;

  /*--------------------------------------------------------------------------*/
  /* Etapa 001 - Recupera os valores de potência do dia                       */
  /*--------------------------------------------------------------------------*/
  FOR _rROW_SLOT IN 
    SELECT 
      IDSLOT ,
      DTINI  ,
      DTFIM  ,
      DTCAL
    FROM 
      slotcontrol
    where 
       TO_CHAR(DTINI, 'YYYY-MM-DD') = TO_CHAR(NOW(), 'YYYY-MM-DD')      
  LOOP
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
    AND IDMODULO = ENT_ID_MODULO;
  
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
    AND IDMODULO = ENT_ID_MODULO;

    _rCONSUMOD := COALESCE(_rCONSUMOD,0) + COALESCE(_rCONSUMO,0);
  END LOOP; 

  /*--------------------------------------------------------------------------*/
  /* Etapa 002 - Recupera os valores de potência da semana                    */
  /*--------------------------------------------------------------------------*/
  _rCONSUMO := 0.00;
  _rPOTMED := 0.00;
  FOR _rROW_SLOT IN 
    SELECT 
      IDSLOT ,
      DTINI  ,
      DTFIM  ,
      DTCAL
    FROM 
      slotcontrol
    where 
       TO_CHAR(DTINI, 'YYYY-WW') = TO_CHAR(NOW(), 'YYYY-WW')
  LOOP
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
    AND IDMODULO = ENT_ID_MODULO;
  
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
    AND IDMODULO = ENT_ID_MODULO;
    _rCONSUMOS := COALESCE(_rCONSUMOS,0) + COALESCE(_rCONSUMO,0);
  END LOOP; 
 
  /*--------------------------------------------------------------------------*/
  /* Etapa 003 - Recupera os valores de potência do mês                       */
  /*--------------------------------------------------------------------------*/
  _rCONSUMO := 0.00;
  _rPOTMED := 0.00;
  FOR _rROW_SLOT IN 
    SELECT 
      IDSLOT ,
      DTINI  ,
      DTFIM  ,
      DTCAL
    FROM 
      slotcontrol
    where 
       TO_CHAR(DTINI, 'YYYY-MM') = TO_CHAR(NOW(), 'YYYY-MM')     
  LOOP
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
    AND IDMODULO = ENT_ID_MODULO;
  
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
    AND IDMODULO = ENT_ID_MODULO;
    
    _rCONSUMOM := COALESCE(_rCONSUMOM,0) + COALESCE(_rCONSUMO,0);
  END LOOP; 

  /*--------------------------------------------------------------------------*/
  /* Etapa 004 - Recupera os valores de potência do ano                       */
  /*--------------------------------------------------------------------------*/
  _rCONSUMO := 0.00;
  _rPOTMED := 0.00;
  FOR _rROW_SLOT IN 
    SELECT 
      IDSLOT ,
      DTINI  ,
      DTFIM  ,
      DTCAL
    FROM 
      slotcontrol
    where 
       TO_CHAR(DTINI, 'YYYY') = TO_CHAR(NOW(), 'YYYY')    
  LOOP
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
    AND IDMODULO = ENT_ID_MODULO;
  
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
    AND IDMODULO = ENT_ID_MODULO;
    
    _rCONSUMOA := COALESCE(_rCONSUMOA,0) + COALESCE(_rCONSUMO,0);
  END LOOP; 

  FOR R IN 
    SELECT 
      COALESCE(_rCONSUMOD , 0.00) ,
      COALESCE(_rCONSUMOS , 0.00) ,
      COALESCE(_rCONSUMOM , 0.00) ,
      COALESCE(_rCONSUMOA , 0.00) ,
      COALESCE(_rCONSUMOA , 0.00)   
  LOOP
    RETURN NEXT R;
  END LOOP;
  RETURN;

/*-------------------------------------------------------------------------------
  RESULT SET:
  dia        NUMERIC(17,2)  -- Valor total do consumo do dia corrente
  semana     NUMERIC(17,2)  -- Valor total do consumo da semana corrente
  mes        NUMERIC(17,2)  -- Valor total do consumo do mes corrente
  ano        NUMERIC(17,2)  -- Valor total do consumo do ano corrente
  total      NUMERIC(17,2)  -- Valor total do consumo do total 
---------------------------------------------------------------------------*/
END;
$BODY$ LANGUAGE PLPGSQL;
