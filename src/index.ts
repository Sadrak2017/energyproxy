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
  host: 'energybd.cauhddqrjy4o.us-east-1.rds.amazonaws.com',
  database: 'oficina',
  password: 'theverve21',
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
// Rota para redirecionar para o modulos.html
app.get('/modulos', (req, res) => {
  res.sendFile(__dirname + '/pages/modulos.html');
});
// Rota para redirecionar para o relatorios.html
app.get('/relatorios', (req, res) => {
  res.sendFile(__dirname + '/pages/relatorios.html');
});
// Rota para redirecionar para o parametros.html
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

app.get('/data/classificacao/:modeloID', async (req, res) => {
  try {
    const modeloID = req.params.modeloID;
    const rows = await getDataClassificao(modeloID);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao obter dados da tabela de classificacao:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

app.get('/data/carga/cf/:modeloID', async (req, res) => {
  try {
    const modeloID = req.params.modeloID;
    const rows = await getDataCargaAtual(modeloID);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao obter dados da tabela de classificacao:', error);
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

app.post('/salvar-carga', async (req, res) => {
  console.log(req.body )
  const { carga, potMin, potMax } = req.body;
  if (await cargaJaExiste(carga, potMin, potMax)) {
    res.status(400).send('Essa carga já existe.');
  } else {
    try {
      const query = 'INSERT INTO classificacao (carga, potMax, potMin, consumo, statusCarga, dtInc) VALUES ($1, $2, $3, 0.00, 2, now())';
      const values = [carga, potMax, potMin];

      await pool.query(query, values);
      res.redirect('/relatorios');
  
    } catch (error) {
      console.error('Erro ao salvar carga:', error);
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

async function cargaJaExiste(carga, potMin, potMax ) {
  try {
    const result = await pool.query('SELECT * FROM classificacao WHERE carga = $1 AND potMin = $2 AND potMax = $3', [carga, potMin, potMax]);
    return result.rows.length > 0;
  } catch (error) {
    console.error('Erro ao verificar se a carga já existe:', error);
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

app.delete('/excluir-carga/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query('DELETE FROM classificacao WHERE ID = $1', [id]);
    res.status(200).send('Carga excluída com sucesso.');
  } catch (error) {
    console.error('Erro ao excluir carga:', error);
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

async function getDataCargaAtual(idModulo) {
  try {
    const result = await pool.query('SELECT * FROM SP_DADOS_CARGA($1)', [idModulo]);
    return result.rows;
  } catch (error) {
    console.error('Erro ao consultar dados da carga:', error);
    return true; // Considere como erro se não for possível realizar a verificação
  }
}

async function getDataClassificao(modeloID) {
  try {
    const result = await pool.query(`SELECT * FROM SP_CLASSIFICACAO_CARGA(${modeloID})`);
    return result.rows;
  } catch (error) {
    console.error('Erro ao consultar classificações:', error);
    return true; // Considere como erro se não for possível realizar a verificação
  }
}


async function getDataMetricas(modeloID) {
  try {
    const result = await pool.query(`SELECT * FROM SP_CALCULA_VALOR_CONSUMO_PERIODO(${modeloID})`);
    return result.rows;
  } catch (error) {
    console.error('Erro ao consultar métricas de consumo por hora:', error);
    return true; // Considere como erro se não for possível realizar a verificação
  }
}

async function getDataMetricasPotencia(modeloID) {
  try {
    const result = await pool.query(`SELECT * FROM SP_CALCULA_CONSUMO(${modeloID})`);
    return result.rows;
  } catch (error) {
    console.error('Erro ao consultar métricas:', error);
    return true; // Considere como erro se não for possível realizar a verificação
  }
}


async function getDataMetricasPotenciaDia(modeloID) {
  try {
    const result = await pool.query(`SELECT * FROM SP_CALCULA_CONSUMO_T3(${modeloID})`);
    return result.rows;
  } catch (error) {
    console.error('Erro ao consultar métricas:', error);
    return true; // Considere como erro se não for possível realizar a verificação
  }
}


app.listen(port, () => {
  console.log(`⚡️[server]: Server is running at http://localhost:${port}`);
});
