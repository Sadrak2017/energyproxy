create database oficina;

--drop table modulo;
CREATE TABLE modulo(
   id SERIAL PRIMARY KEY, 	 
   modelo varchar(20) not null, 
   serie  varchar(20) not null,
   dtInc  timestamp not null
);
 
--drop table consumo;
CREATE TABLE consumo(
   id SERIAL PRIMARY KEY, 	 
   idModulo numeric not null, 
   tensao  numeric not null,
   corrente  numeric not null,
   dtInc  timestamp not null
);
--drop table parametro;
CREATE TABLE parametro(
   id SERIAL PRIMARY KEY, 	 
   valorKWH numeric not null, 
   fatorCorrecao numeric not null,
   dtInc  timestamp not null
);

--drop table classificacao;
CREATE TABLE classificacao(
   id SERIAL PRIMARY KEY, 	 
   carga varchar(200) not null, 
   potMax numeric(17,4) not null,
   potMin numeric(17,4) not null,
   consumo numeric(17,4) not null,
   statusCarga numeric(1) not null, --1 consumindo, 2 desativada
   dtInc  timestamp not null
);

--Exemplo de insert na base 
insert into consumo values (
	(select max(id) +1 from consumo), 
	(select id from modulo where modelo = 'a320'), 
	13, 
	34, 
	now()
)

--
ALTER TABLE CONSUMO ADD COLUMN potencia numeric(17,4) null