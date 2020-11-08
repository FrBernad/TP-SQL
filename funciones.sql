-------------------------------------------------------
--  TABLES CREATION  --
-------------------------------------------------------


CREATE TABLE PAIS
(
    id_pais    SERIAL NOT NULL PRIMARY KEY,
    nombrePais TEXT   NOT NULL UNIQUE
);

CREATE TABLE PROVINCIA
(
    id_prov INT NOT NULL PRIMARY KEY,
    id_pais INT NOT NULL,
    FOREIGN KEY (id_pais) REFERENCES PAIS ON DELETE RESTRICT
);

CREATE TABLE DEPARTAMENTO
(
    id_departamento SERIAL NOT NULL PRIMARY KEY,
    nombreDepto     TEXT   NOT NULL,
    provincia       INT    NOT NULL,
    FOREIGN KEY (provincia) REFERENCES PROVINCIA ON DELETE RESTRICT
);

CREATE TABLE LOCALIDAD
(
    id_localidad    SERIAL NOT NULL PRIMARY KEY,
    nombre          TEXT   NOT NULL,
    id_departamento INT    NOT NULL,
    canthab         INT,
    FOREIGN KEY (id_departamento) REFERENCES DEPARTAMENTO ON DELETE RESTRICT
);

CREATE VIEW AUXILIAR (nombreLocalidad, nombrePais, idProv, nombreDepto, cantHab) as
(
select nombre, nombrePais, id_prov, nombreDepto, canthab
from ((select *
       from PAIS
                join PROVINCIA P on PAIS.id_pais = P.id_pais) as AUX
         join
     (select *
      from DEPARTAMENTO
               join LOCALIDAD L on DEPARTAMENTO.id_departamento = L.id_departamento) as AUX2
     on AUX.id_prov = AUX2.provincia));


-------------------------------------------------------
-- TRIGGER FUNCTIONS --
-------------------------------------------------------


CREATE OR REPLACE FUNCTION seedData() RETURNS TRIGGER AS
$$
DECLARE
    auxIdPais      PAIS.id_pais%TYPE;
    auxIdDepto     DEPARTAMENTO.id_departamento%TYPE;
    auxIdProvincia PROVINCIA.id_prov%TYPE;

BEGIN

    SELECT id_pais INTO auxIdPais FROM PAIS WHERE nombrePais = new.nombrePais;
    IF (auxIdPais IS NULL) THEN
        INSERT INTO PAIS(nombrePais) VALUES (new.nombrePais);
        SELECT id_pais INTO auxIdPais FROM PAIS WHERE nombrePais = new.nombrePais;
    END IF;

    SELECT id_prov INTO auxIdProvincia FROM PROVINCIA WHERE id_prov = new.idProv;
    IF (auxIdProvincia IS NULL) THEN
        auxIdProvincia := cast(new.idProv as integer);
        INSERT INTO provincia values (auxIdProvincia, auxIdPais);
    END IF;

    SELECT id_departamento
    INTO auxIdDepto
    FROM DEPARTAMENTO
    WHERE nombreDepto = new.nombreDepto
      and provincia = auxIdProvincia;
    IF (auxIdDepto IS NULL) THEN
        INSERT INTO DEPARTAMENTO(nombreDepto, provincia) VALUES (new.nombreDepto, auxIdProvincia);
        SELECT id_departamento INTO auxIdDepto FROM DEPARTAMENTO WHERE nombreDepto = new.nombreDepto and provincia = auxIdProvincia;
    END IF;

    INSERT INTO LOCALIDAD(nombre, id_departamento, canthab)
    VALUES (new.nombreLocalidad, auxIdDepto, new.canthab);

    RETURN new;
END
$$ LANGUAGE plpgsql;

--------------------------------

CREATE OR REPLACE FUNCTION removeData() RETURNS TRIGGER AS
$$
DECLARE
    auxIdPais      PAIS.id_pais%TYPE;
    auxIdDepto     DEPARTAMENTO.id_departamento%TYPE;
    auxIdProvincia PROVINCIA.id_prov%TYPE;

BEGIN
    SELECT id_pais INTO auxIdPais FROM PAIS WHERE nombrePais = old.nombrePais;
    SELECT id_prov INTO auxIdProvincia FROM PROVINCIA WHERE id_prov = old.idProv;
    SELECT id_departamento INTO auxIdDepto FROM DEPARTAMENTO WHERE nombreDepto = old.nombreDepto and provincia=auxIdProvincia;

    DELETE FROM LOCALIDAD WHERE nombre = old.nombreLocalidad;

    IF ((SELECT count(*) FROM LOCALIDAD WHERE id_departamento = auxIdDepto) = 0) THEN
        DELETE FROM DEPARTAMENTO WHERE id_departamento = auxIdDepto;
    END IF;

    IF ((SELECT count(*) FROM DEPARTAMENTO WHERE provincia = auxIdProvincia) = 0) THEN
        DELETE FROM PROVINCIA WHERE id_prov = auxIdProvincia;
    END IF;

    IF ((SELECT count(*) FROM PROVINCIA WHERE id_pais = auxIdPais) = 0) THEN
        DELETE FROM PAIS WHERE id_pais = auxIdPais;
    END IF;

    RETURN old;
END
$$ LANGUAGE plpgsql;


-------------------------------------------------------
--  TABLES TRIGGERS  --
-------------------------------------------------------

CREATE TRIGGER seedDataTrigger
    INSTEAD OF INSERT
    ON AUXILIAR
    FOR EACH ROW
EXECUTE PROCEDURE seedData();

-----------------------

CREATE TRIGGER removeDataTrigger
    INSTEAD OF DELETE
    ON AUXILIAR
    FOR EACH ROW
EXECUTE PROCEDURE removeData();


-------------------------------------------------------
--    TABLES DROPS   --
-------------------------------------------------------

DROP TABLE LOCALIDAD cascade;
DROP TABLE DEPARTAMENTO cascade;
DROP TABLE PROVINCIA cascade;
DROP TABLE PAIS cascade;

-----------------------

DROP TRIGGER seedDataTrigger ON AUXILIAR;
DROP TRIGGER removeDataTrigger ON AUXILIAR;

-----------------------

DROP FUNCTION seedData;
DROP FUNCTION removeData;

-----------------------

DROP VIEW AUXILIAR;

-------------------------------------------------------
--  DELETE EXAMPLES  --
-------------------------------------------------------

DELETE
FROM AUXILIAR
WHERE nombreLocalidad = 'Valle Verde';
DELETE
FROM AUXILIAR
WHERE nombreDepto = 'General Roca'
  and idProv = 62;
DELETE
FROM AUXILIAR
WHERE idProv = 62;
DELETE
FROM AUXILIAR
WHERE canthab = 740;
DELETE
FROM AUXILIAR
WHERE nombrePais = 'Argentina';
DELETE
FROM auxiliar
WHERE nombreLocalidad = 'Allen';
DELETE
FROM auxiliar
WHERE nombreDepto = 'General Roca'
  and nombreLocalidad != 'Allen';
