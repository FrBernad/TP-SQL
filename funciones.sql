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
    nombreDepto     TEXT   NOT NULL UNIQUE,
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

CREATE TABLE AUXILIAR
(
    nombreLocalidad TEXT,
    nombrePais      TEXT,
    idProv          INT,
    nombreDepto     TEXT,
    canthab         INT
);

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

    select id_prov into auxIdProvincia from provincia where id_prov = new.idProv;
    if (auxIdProvincia is null) THEN
        auxIdProvincia := cast(new.idProv as integer);
        insert into provincia values (auxIdProvincia, auxIdPais);
    END IF;

    SELECT id_departamento INTO auxIdDepto FROM DEPARTAMENTO WHERE nombreDepto = new.nombreDepto;
    if (auxIdDepto is null) THEN
        INSERT INTO DEPARTAMENTO(nombreDepto, provincia) VALUES (new.nombreDepto, auxIdProvincia);
        SELECT id_departamento INTO auxIdDepto FROM DEPARTAMENTO WHERE nombreDepto = new.nombreDepto;
    END IF;

    INSERT INTO LOCALIDAD(nombre, id_departamento, canthab)
    VALUES (new.nombreLocalidad, auxIdDepto, new.canthab);

    return new;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION removeData() RETURNS TRIGGER AS
$$
DECLARE
    auxIdPais      PAIS.id_pais%TYPE;
    auxIdDepto     DEPARTAMENTO.id_departamento%TYPE;
    auxIdProvincia PROVINCIA.id_prov%TYPE;

BEGIN
    SELECT id_pais INTO auxIdPais FROM PAIS WHERE nombrePais = old.nombrePais;
    select id_prov into auxIdProvincia from provincia where id_prov = old.idProv;
    SELECT id_departamento INTO auxIdDepto FROM DEPARTAMENTO WHERE nombreDepto = old.nombreDepto;

    delete from localidad where nombre = old.nombreLocalidad;

    IF ((select count(*) from localidad where id_departamento = auxIdDepto) = 0) THEN
        delete from departamento where id_departamento = auxIdDepto;
    END IF;

    IF ((select count(*) from departamento where provincia = auxIdProvincia) = 0) THEN
        delete from provincia where id_prov = auxIdProvincia;
    END IF;

     IF ((select count(*) from provincia where id_pais = auxIdPais) = 0) THEN
        delete from pais where id_pais = auxIdPais;
    END IF;

    return old;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER seedDataTrigger
    BEFORE INSERT
    ON AUXILIAR
    FOR EACH ROW
EXECUTE PROCEDURE seedData();

CREATE TRIGGER removeDataTrigger
    BEFORE DELETE
    ON AUXILIAR
    FOR EACH ROW
EXECUTE PROCEDURE removeData();

COPY AUXILIAR (nombreLocalidad, nombrePais, idProv, nombreDepto, canthab) FROM 'C:\Users\Agustin\Desktop\Facultad\Tercero\Primer Cuatrimestre\Base de datos I\TP\TP-SQL\localidades.csv' WITH (FORMAT csv,HEADER TRUE);

DROP TABLE LOCALIDAD;
DROP TABLE DEPARTAMENTO;
DROP TABLE PROVINCIA;
DROP TABLE PAIS;

DROP TRIGGER seedDataTrigger ON AUXILIAR;

DROP FUNCTION seedData;

drop table AUXILIAR;

DELETE FROM auxiliar WHERE nombrePais = 'Argentina';
DELETE FROM auxiliar WHERE nombreLocalidad = 'Allen';
DELETE FROM auxiliar WHERE nombreDepto = 'General Roca' and nombreLocalidad!='Allen';
DELETE FROM auxiliar WHERE idProv = 62;
DELETE FROM auxiliar WHERE canthab = 740;
DELETE FROM auxiliar WHERE canthab = -1;

SELECT * FROM auxiliar where nombreDepto = 'General Roca';
SELECT * FROM departamento where nombreDepto = 'General Roca';
