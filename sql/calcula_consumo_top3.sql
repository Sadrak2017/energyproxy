
DROP TYPE IF EXISTS TY_CALCULA_CONSUMO_T3 CASCADE;

CREATE TYPE TY_CALCULA_CONSUMO_T3 AS (
  horario             NUMERIC(2)   ,
  potencia            NUMERIC(17,2)
);

CREATE FUNCTION SP_CALCULA_CONSUMO_T3 (
/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  :: SISTEMA    : Energy Proxy                                                 ::
  :: MÓDULO     : 1.0.0                                                        ::
  :: UTILIZ. POR: index.ts                                                     ::
  :: OBSERVAÇÃO :                                                              ::
  :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/
   /*-------------------------------------------------------------------------------
  DESCRIÇÃO DA FUNCIONALIDADE:
  
  Calula o consumo em kwh para o dia corrente
  -------------------------------------------------------------------------------*/
  ENT_ID_MODULO  NUMERIC(9)    /* ID do módulo                                   */
)
RETURNS SETOF TY_CALCULA_CONSUMO_T3

AS $BODY$
DECLARE
  R  TY_CALCULA_CONSUMO_T3%Rowtype;
  i  NUMERIC(2); 
  
BEGIN
  
  CREATE TEMPORARY TABLE TB_CONSUMO (
    HORA       NUMERIC(2,0)     NULL,
    POTENCIA   NUMERIC(17,4)    NULL
  ) ON COMMIT DROP;
  
  /*--------------------------------------------------------------------------*/
  /* Etapa 001 - Recupera os valores de potência gravado na tabela CONSUMO    */
  /*--------------------------------------------------------------------------*/
  INSERT INTO TB_CONSUMO (
    HORA,
    POTENCIA
  )
  SELECT
    CAST(TO_CHAR(DATE_TRUNC('HOUR', DTINC), 'HH') AS NUMERIC(2))  HORARIO,
    CAST(SUM(POTENCIA)/1000 AS NUMERIC(17,2)) POTENCIA 
  FROM 
    CONSUMO 
  WHERE 
    TO_CHAR(DTINC, 'YYYY-MM-DD') = TO_CHAR(NOW(), 'YYYY-MM-DD') 
  AND IDMODULO = ENT_ID_MODULO
  GROUP BY 
    DATE_TRUNC('HOUR', DTINC);
  
  FOR R IN 
    SELECT
      HORA,
      POTENCIA
    FROM
      TB_CONSUMO
    ORDER BY 
      POTENCIA 
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
