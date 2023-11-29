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
   dtInc  timestamp not null,
   potencia numeric(17,4) null, 
   slot numeric(2) null
);

--Exemplo de insert na base 
insert into consumo values (
	(select max(id) +1 from consumo), 
	(select id from modulo where modelo = 'a320'), 
	13, 
	34, 
	now(),
   180,
   1
)

--
ALTER TABLE CONSUMO ADD COLUMN potencia numeric(17,4) null
ALTER TABLE CONSUMO ADD COLUMN SLOT numeric(2) null
ALTER TABLE slotcontrol ADD COLUMN dtcal timestamp null
ALTER TABLE classificacao ADD COLUMN kwh numeric(17,4) null
ALTER TABLE classificacao ADD COLUMN slot numeric(2) null

--INSERT INTO SLOTCONTROL VALUES((select COALESCE(max(id),0) +1 from SLOTCONTROL), 1, 1, NOW())
--Controle de slot
create table slotcontrol (
   id SERIAL PRIMARY KEY, 	 
   idSlot numeric(1),
   status numeric(2),  -- 1 ligado , 2 desligado
   dtini  timestamp,	
   dtini  timestamp,
   dtcal  timestamp,
   kwh    numeric(17,4) 
)
