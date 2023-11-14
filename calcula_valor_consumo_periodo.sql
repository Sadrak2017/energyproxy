
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
  i  NUMERIC(2); 
  
BEGIN
  
  CREATE TEMPORARY TABLE TB_CONSUMO (
    HORA       NUMERIC(2,0)     NULL,
    POTENCIA   NUMERIC(17,4)    NULL
  ) ON COMMIT DROP;
  
  /*--------------------------------------------------------------------------*/
  /* Etapa 001 - Recupera os valores de potência gravado na tabela CONSUMO    */
  /*--------------------------------------------------------------------------*/
  
  FOR R IN 
    WITH VALORES AS(
    SELECT 
      (
        SELECT
          CAST(COALESCE(AVG(POTENCIA/1000), 0) *  
          COALESCE(VALORKWH, 0) * 
          COALESCE(FATORCORRECAO, 0) *
          EXTRACT(EPOCH FROM (MAX(DTINC) - MIN(DTINC))) / 3600 AS NUMERIC(17,4)) AS HORAS_DIAL
        FROM
          CONSUMO
        WHERE 
            TO_CHAR(DTINC, 'YYYY-MM-DD') = TO_CHAR(NOW(), 'YYYY-MM-DD') 
        AND IDMODULO = ENT_ID_MODULO
      ) AS CONSUMODIARIO,
      (
        SELECT
          CAST(COALESCE(AVG(POTENCIA/1000), 0) *  
          COALESCE(VALORKWH, 0) * 
          COALESCE(FATORCORRECAO, 0) * 
          EXTRACT(EPOCH FROM (MAX(DTINC) - MIN(DTINC))) / 3600 AS NUMERIC(17,4)) AS HORAS_SEMANAL
        FROM 
          CONSUMO
        WHERE 
           TO_CHAR(DTINC, 'IYYY-IW') = TO_CHAR(NOW(), 'IYYY-IW') 
       AND IDMODULO = ENT_ID_MODULO
      ) AS CONSUMOSEMANAL, 
      (
        SELECT
          CAST(COALESCE(AVG(POTENCIA/1000), 0) *  
          COALESCE(VALORKWH, 0) * 
          COALESCE(FATORCORRECAO, 0) *
          EXTRACT(EPOCH FROM (MAX(DTINC) - MIN(DTINC))) / 3600 AS NUMERIC(17,4)) AS HORAS_MENSAL
        FROM 
          CONSUMO
        WHERE 
            TO_CHAR(DTINC, 'YYYY-MM') = TO_CHAR(NOW(), 'YYYY-MM') 
        AND IDMODULO = ENT_ID_MODULO
      ) AS CONSUMOMENSAL,
      (
        SELECT
          CAST(COALESCE(AVG(POTENCIA/1000), 0) *   
          COALESCE(VALORKWH, 0) * 
          COALESCE(FATORCORRECAO, 0) *
          EXTRACT(EPOCH FROM (MAX(DTINC) - MIN(DTINC))) / 3600 AS NUMERIC(17,4)) AS HORAS_ANUAL
        FROM 
          CONSUMO
        WHERE 
            TO_CHAR(DTINC, 'YYYY') = TO_CHAR(NOW(), 'YYYY') 
        AND IDMODULO = ENT_ID_MODULO
      ) AS CONSUMOANUAL,
      (
        SELECT
          CAST(COALESCE(AVG(POTENCIA/1000), 0) *    
          COALESCE(VALORKWH, 0) * 
          COALESCE(FATORCORRECAO, 0) *
          EXTRACT(EPOCH FROM (MAX(DTINC) - MIN(DTINC))) / 3600 AS NUMERIC(17,4)) AS HORAS_ANUAL
        FROM 
          CONSUMO
        WHERE 
          IDMODULO = ENT_ID_MODULO
      ) AS CONSUMOTOTAL
    FROM 
      PARAMETRO	
    ) 
    SELECT 
      COALESCE(CONSUMODIARIO , 0.00) ,
      COALESCE(CONSUMOSEMANAL, 0.00) ,
      COALESCE(CONSUMOMENSAL , 0.00) ,
      COALESCE(CONSUMOANUAL  , 0.00) ,
      COALESCE(CONSUMOTOTAL  , 0.00) 
    FROM 
    VALORES     
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
