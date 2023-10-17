create database oficina;
senha: 1234
usuario: postgress
port: 5432

drop table modulo;
CREATE TABLE modulo(
   id SERIAL PRIMARY KEY, 	 
   modelo varchar(20) not null, 
   serie  varchar(20) not null,
   dtInc  timestamp not null
);
 
drop table consumo;
CREATE TABLE consumo(
   id SERIAL PRIMARY KEY, 	 
   idModulo numeric not null, 
   tensao  numeric not null,
   corrente  numeric not null,
   dtInc  timestamp not null
);
drop table parametro;
CREATE TABLE parametro(
   id SERIAL PRIMARY KEY, 	 
   valorKWH numeric not null, 
   fatorCorrecao numeric not null,
   dtInc  timestamp not null
);