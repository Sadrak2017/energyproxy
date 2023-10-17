const { Pool } = require('pg');
import express, { Express, Request, Response } from 'express';
import dotenv from 'dotenv';
import { HttpService } from './service/HttpService'
import { DataHandler } from './service/DataHandler'
const bodyParser = require('body-parser');
dotenv.config();

const app: Express = express();
const port = process.env.PORT;
process.env['NODE_TLS_REJECT_UNAUTHORIZED'] = '0';
const httpService = new HttpService()
const dataHandler = new DataHandler()
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json())
app.use(express.static('src'));
// Configurações de conexão com o banco de dados
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'oficina',
  password: '1234',
  port: 5432, // Porta padrão do PostgreSQL
});

// Função para se conectar ao banco de dados
async function conectarAoBanco() {
  try {
    // Conecta ao banco de dados
    await pool.connect();
    console.log('Conectado ao banco de dados');
  } catch (error) {
    console.error('Erro ao conectar ao banco de dados:', error);
  }
}
conectarAoBanco();
// Rota para redirecionar para o index.html
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/src/index.html');
});
// Rota para redirecionar para o index.html
app.get('/modulos', (req, res) => {
  res.sendFile(__dirname + '/pages/modulos.html');
});
// Rota para redirecionar para o index.html
app.get('/param', (req, res) => {
  res.sendFile(__dirname + '/pages/parametros.html');
});

app.get('/data/', async (req, res) => {
  try {
    const rows = await getData();
    res.json(rows);
  } catch (error) {
    console.error('Erro ao obter dados da tabela:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

app.get('/data/metricas/:modeloID', async (req, res) => {
  try {
    const modeloID = req.params.modeloID;
    const rows = await getDataMetricas(modeloID);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao obter dados de métricas:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

app.get('/data/metricas/potencia/:modeloID', async (req, res) => {
  try {
    const modeloID = req.params.modeloID;
    const rows = await getDataMetricasPotencia(modeloID);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao obter dados de métricas de potencia:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

app.get('/data/metricas/potencia/dia/:modeloID', async (req, res) => {
  try {
    const modeloID = req.params.modeloID;
    const rows = await getDataMetricasPotenciaDia(modeloID);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao obter dados de métricas de potencia:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

app.get('/dataParam', async (req, res) => {
  try {
    const rows = await getDataParam();
    res.json(rows);
  } catch (error) {
    console.error('Erro ao obter dados da tabela:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});
app.post('/salvar-modulo', async (req, res) => {
  console.log(req.body )
  const { modelo, serie, data } = req.body;
  if (await moduloJaExiste(modelo, serie)) {
    res.status(400).send('Este módulo já existe.');
  } else {
    try {
      const query = 'INSERT INTO modulo (modelo, serie, dtInc) VALUES ($1, $2, now())';
      const values = [modelo, serie];

      await pool.query(query, values);
      res.redirect('/modulos');
  
    } catch (error) {
      console.error('Erro ao salvar módulo:', error);
      res.status(500).send('Erro interno do servidor');
    }
  }
});

app.post('/salvar-parametro', async (req, res) => {
  console.log(req.body )
  var query = '';
  const { parametro, fator } = req.body;
  if (await parametroJaExiste()) {
    await pool.query('DELETE FROM parametro');
  }
  try {
    query = 'INSERT INTO parametro (valorKWH, fatorCorrecao, dtInc) VALUES (cast($1 as numeric), cast($2 as numeric), now())';
    const values = [parametro.replace(',', '.'), fator.replace(',', '.')];

    await pool.query(query, values);
    res.redirect('/param');

  } catch (error) {
    console.error('Erro ao salvar parametro:', error);
    res.status(500).send('Erro interno do servidor');
  }
  
});

async function parametroJaExiste() {
  try {
    const result = await pool.query('SELECT * FROM parametro');
    return result.rows.length > 0;
  } catch (error) {
    console.error('Erro ao verificar parametrização já existe:', error);
    return true; // Considere como erro se não for possível realizar a verificação
  }
}


async function getDataParam() {
  try {
    const result = await pool.query('SELECT * FROM parametro');
    return result.rows;
  } catch (error) {
    console.error('Erro ao consultar parametrização:', error);
    return true; // Considere como erro se não for possível realizar a verificação
  }
}

async function moduloJaExiste(modelo, serie) {
  try {
    const result = await pool.query('SELECT * FROM modulo WHERE modelo = $1 AND serie = $2', [modelo, serie]);
    return result.rows.length > 0;
  } catch (error) {
    console.error('Erro ao verificar se o módulo já existe:', error);
    return true; // Considere como erro se não for possível realizar a verificação
  }
}

app.delete('/excluir-modulo/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query('DELETE FROM modulo WHERE ID= $1', [id]);
    res.status(200).send('Módulo excluído com sucesso.');
  } catch (error) {
    console.error('Erro ao excluir o módulo:', error);
    res.status(500).send('Erro interno do servidor.');
  }
});

async function getData() {
  try {
    const result = await pool.query('SELECT * FROM modulo ORDER BY dtInc DESC');
    return result.rows;
  } catch (error) {
    console.error('Erro ao consultar módulos:', error);
    return true; // Considere como erro se não for possível realizar a verificação
  }
}

async function getDataMetricas(modeloID) {
  try {
    const result = await pool.query(`
        WITH valor as(
          SELECT 
            (SELECT
              CAST(COALESCE(AVG(TENSAO), 0) * 
            COALESCE(AVG(CORRENTE), 0) * 
            COALESCE(VALORKWH, 0) * 
            COALESCE(FATORCORRECAO, 0) *
            EXTRACT(EPOCH FROM (MAX(dtInc) - MIN(dtInc))) / 3600 AS NUMERIC(17,2)) AS horas_dial
          FROM consumo
          WHERE to_char(dtInc, 'YYYY-mm-dd') = to_char(now(), 'YYYY-mm-dd') and IDMODULO = ${modeloID}
          ) AS consumoDiario,
          (SELECT
              CAST(COALESCE(AVG(TENSAO), 0) * 
            COALESCE(AVG(CORRENTE), 0) * 
            COALESCE(VALORKWH, 0) * 
            COALESCE(FATORCORRECAO, 0) * 
            EXTRACT(EPOCH FROM (MAX(dtInc) - MIN(dtInc))) / 3600 AS NUMERIC(17,2)) AS horas_semanal
          FROM consumo
          WHERE to_char(dtInc, 'IYYY-IW') = to_char(now(), 'IYYY-IW') and IDMODULO = ${modeloID}
            )  as consumoSemanal, 
          (SELECT
                CAST(COALESCE(AVG(TENSAO), 0) * 
            COALESCE(AVG(CORRENTE), 0) * 
            COALESCE(VALORKWH, 0) * 
            COALESCE(FATORCORRECAO, 0) *
            EXTRACT(EPOCH FROM (MAX(dtInc) - MIN(dtInc))) / 3600 AS NUMERIC(17,2)) AS horas_mensal
          FROM consumo
          WHERE to_char(dtInc, 'YYYY-MM') = to_char(now(), 'YYYY-MM') and IDMODULO = ${modeloID}
          ) as consumoMensal,
          (SELECT
              CAST(COALESCE(AVG(TENSAO), 0) * 
            COALESCE(AVG(CORRENTE), 0) *  
            COALESCE(VALORKWH, 0) * 
            COALESCE(FATORCORRECAO, 0) *
            EXTRACT(EPOCH FROM (MAX(dtInc) - MIN(dtInc))) / 3600 AS NUMERIC(17,2)) AS horas_anual
          FROM consumo
          WHERE to_char(dtInc, 'YYYY') = to_char(now(), 'YYYY') and IDMODULO = ${modeloID}
          ) as consumoAnual,
          (SELECT
            CAST(COALESCE(AVG(TENSAO), 0) * 
           COALESCE(AVG(CORRENTE), 0) *  
           COALESCE(VALORKWH, 0) * 
           COALESCE(FATORCORRECAO, 0) *
           EXTRACT(EPOCH FROM (MAX(dtInc) - MIN(dtInc))) / 3600 AS NUMERIC(17,2)) AS horas_anual
         FROM consumo
         WHERE IDMODULO = ${modeloID}
         ) as consumototal
        FROM PARAMETRO	
        ) select 
            coalesce(consumoDiario, 0.00) dia,
            coalesce(consumoSemanal, 0.00) semana,
            coalesce(consumoMensal, 0.00) mes,
            coalesce(consumoAnual, 0.00) ano,
            coalesce(consumototal, 0.00) total
        from 
            valor
        `);
    return result.rows;
  } catch (error) {
    console.error('Erro ao consultar métricas:', error);
    return true; // Considere como erro se não for possível realizar a verificação
  }
}

async function getDataMetricasPotencia(modeloID) {
  try {
    const result = await pool.query(`
      SELECT
        to_char(DATE_TRUNC('hour', dtInc), 'HH') horario,
        cast(COALESCE(AVG(TENSAO), 0) * 
        COALESCE(AVG(CORRENTE), 0)/1000 as numeric(17,2)) as potencia 
      FROM CONSUMO 
      WHERE 
        to_char(dtInc, 'YYYY-mm-dd') = to_char(now(), 'YYYY-mm-dd') AND
        IDMODULO = ${modeloID}
      GROUP BY DATE_TRUNC('hour', dtInc)
    `);
    return result.rows;
  } catch (error) {
    console.error('Erro ao consultar métricas:', error);
    return true; // Considere como erro se não for possível realizar a verificação
  }
}


async function getDataMetricasPotenciaDia(modeloID) {
  try {
    const result = await pool.query(`
      SELECT
        to_char(DATE_TRUNC('hour', dtInc), 'HH') horario,
        cast(COALESCE(AVG(TENSAO), 0) * 
        COALESCE(AVG(CORRENTE), 0)/1000 as numeric(17,2)) as potencia 
      FROM CONSUMO 
      WHERE 
        to_char(dtInc, 'YYYY-mm-dd') = to_char(now(), 'YYYY-mm-dd') AND
        IDMODULO = ${modeloID}
      GROUP BY DATE_TRUNC('hour', dtInc)
      ORDER BY potencia
      limit 3
    `);
    return result.rows;
  } catch (error) {
    console.error('Erro ao consultar métricas:', error);
    return true; // Considere como erro se não for possível realizar a verificação
  }
}


app.listen(port, () => {
  console.log(`⚡️[server]: Server is running at http://localhost:${port}`);
});
