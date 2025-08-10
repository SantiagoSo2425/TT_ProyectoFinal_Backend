-- Script de inicialización para Docker
-- La base de datos 'festivos' ya es creada por la variable POSTGRES_DB

-- Crear base de datos para SonarQube (en una conexión separada)
CREATE DATABASE sonarqube;

-- Las siguientes tablas se crean en la base de datos 'festivos' actual

-- Crear secuencias personalizadas para las entidades JPA
CREATE SEQUENCE secuencia_tipo START 1 INCREMENT 1;
CREATE SEQUENCE secuencia_pais START 1 INCREMENT 1;
CREATE SEQUENCE secuencia_festivo START 1 INCREMENT 1;

--Crear la tabla TIPO
CREATE TABLE Tipo(
	Id INT PRIMARY KEY DEFAULT nextval('secuencia_tipo'),
	Tipo VARCHAR(100) NOT NULL
	);

--Crear la tabla PAIS
CREATE TABLE Pais(
	Id INT PRIMARY KEY DEFAULT nextval('secuencia_pais'),
	Nombre VARCHAR(100) NOT NULL
	);

--Crear la tabla FESTIVO
CREATE TABLE Festivo(
	Id INT PRIMARY KEY DEFAULT nextval('secuencia_festivo'),
	IdPais INT NOT NULL,
	CONSTRAINT fkFestivo_Pais FOREIGN KEY (IdPais) REFERENCES Pais(Id),
	Nombre VARCHAR(100) NOT NULL,
	Dia INT NOT NULL,
	Mes INT NOT NULL,
	DiasPascua INT NOT NULL,
	IdTipo INT NOT NULL,
	CONSTRAINT fkFestivo_Tipo FOREIGN KEY (IdTipo) REFERENCES Tipo(Id)
	);

--Registros tabla TIPO
INSERT INTO Tipo(Id, Tipo) VALUES(1, 'Fijo');
INSERT INTO Tipo(Id, Tipo) VALUES(2, 'Ley Puente Festivo');
INSERT INTO Tipo(Id, Tipo) VALUES(3, 'Basado en Pascua');
INSERT INTO Tipo(Id, Tipo) VALUES(4, 'Basado en Pascua y Ley Puente Festivo');
INSERT INTO Tipo(Id, Tipo) VALUES(5, 'Ley Puente Festivo Viernes');

--Registros tabla PAIS
INSERT INTO Pais (Id, Nombre) VALUES( 1,'COLOMBIA');
INSERT INTO Pais (Id, Nombre) VALUES( 2,'ARGENTINA');
INSERT INTO Pais (Id, Nombre) VALUES( 3,'BOLIVIA');
INSERT INTO Pais (Id, Nombre) VALUES( 4,'BRASIL');
INSERT INTO Pais (Id, Nombre) VALUES( 5,'CANADA');
INSERT INTO Pais (Id, Nombre) VALUES( 6,'COSTA RICA');
INSERT INTO Pais (Id, Nombre) VALUES( 7,'REPUBLICA DOMINICANA');
INSERT INTO Pais (Id, Nombre) VALUES( 8,'CUBA');
INSERT INTO Pais (Id, Nombre) VALUES( 9,'CHILE');
INSERT INTO Pais (Id, Nombre) VALUES(10,'ECUADOR');
INSERT INTO Pais (Id, Nombre) VALUES(11,'ESTADOS UNIDOS DE AMÉRICA');
INSERT INTO Pais (Id, Nombre) VALUES(12,'GUATEMALA');
INSERT INTO Pais (Id, Nombre) VALUES(13,'HONDURAS');
INSERT INTO Pais (Id, Nombre) VALUES(14,'MÉXICO');
INSERT INTO Pais (Id, Nombre) VALUES(15,'NICARAGUA');
INSERT INTO Pais (Id, Nombre) VALUES(16,'PANAMA');
INSERT INTO Pais (Id, Nombre) VALUES(17,'PARAGUAY');
INSERT INTO Pais (Id, Nombre) VALUES(18,'PERU');
INSERT INTO Pais (Id, Nombre) VALUES(19,'URUGUAY');
INSERT INTO Pais (Id, Nombre) VALUES(20,'VENEZUELA');
INSERT INTO Pais (Id, Nombre) VALUES(21,'ESPAÑA');

--Registros tabla FESTIVO
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 1, 1, 'Año nuevo', 1, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 6, 1, 'Santos Reyes', 2, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 19, 3, 'San José', 2, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 0, 0, 'Jueves Santo', 3, -3);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 0, 0, 'Viernes Santo', 3, -2);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 0, 0, 'Domingo de Pascua', 3, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 1, 5, 'Día del Trabajo', 1, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 0, 0, 'Ascensión del Señor', 4, 40);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 0, 0, 'Corpus Christi', 4, 61);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 0, 0, 'Sagrado Corazón de Jesús', 4, 68);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 29, 6, 'San Pedro y San Pablo', 2, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 20, 7, 'Independencia Colombia', 1, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 7, 8, 'Batalla de Boyacá', 1, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 15, 8, 'Asunción de la Virgen', 2, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 12, 10, 'Día de la Raza', 2, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 1, 11, 'Todos los santos', 2, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 11, 11, 'Independencia de Cartagena', 2, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 8, 12, 'Inmaculada Concepción', 1, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(1, 25, 12, 'Navidad', 1, 0);

INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(10, 1, 1, 'Año nuevo', 1, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(10, 0, 0, 'Carnaval 1', 3, -43);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(10, 0, 0, 'Carnaval 2', 3, -42);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(10, 0, 0, 'Viernes Santo', 3, -2);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(10, 1, 5, 'Día del Trabajo', 5, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(10, 24, 5, 'Batalla de Pichincha', 1, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(10, 10, 8, 'Primer Grito de Independencia', 5, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(10, 9, 10, 'Independencia de Guayaquil', 5, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(10, 2, 11, 'Día de los Difuntos', 5, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(10, 3, 11, 'Independencia de Cuenca', 5, 0);
INSERT INTO Festivo (IdPais, Dia, Mes, Nombre, IdTipo, DiasPascua) VALUES(10, 25, 12, 'Navidad', 5, 0);

-- Ajustar los valores de las secuencias después de los inserts
SELECT setval('secuencia_tipo', (SELECT MAX(id) FROM Tipo));
SELECT setval('secuencia_pais', (SELECT MAX(id) FROM Pais));
SELECT setval('secuencia_festivo', (SELECT MAX(id) FROM Festivo));
