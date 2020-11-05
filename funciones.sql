CREATE TABLE PAIS
(
    id_pais SERIAL NOT NULL PRIMARY KEY,
    nombrePais TEXT NOT NULL UNIQUE
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
    nombreDepto TEXT NOT NULL UNIQUE,
    provincia INT NOT NULL,
    FOREIGN KEY (provincia) REFERENCES PROVINCIA ON DELETE RESTRICT
);

CREATE TABLE LOCALIDAD
(
    id_localidad SERIAL NOT NULL PRIMARY KEY,
    nombre TEXT NOT NULL,
    id_departamento INT NOT NULL,
    canthab INT,
    FOREIGN KEY (id_departamento) REFERENCES DEPARTAMENTO ON DELETE RESTRICT
);

CREATE TABLE AUXILIAR
(
    nombreLocalidad TEXT,
    nombrePais TEXT,
    idProv INT,
    nombreDepto TEXT,
    canthab INT
);


CREATE OR REPLACE FUNCTION validateData() RETURNS TRIGGER AS
$$
DECLARE
    auxIdPais PAIS.id_pais%TYPE;
    auxIdDepto DEPARTAMENTO.id_departamento%TYPE;
    auxIdProvincia PROVINCIA.id_prov%TYPE;

BEGIN

    SELECT id_pais INTO auxIdPais FROM PAIS WHERE nombrePais = new.nombrePais;
    IF (auxIdPais IS NULL) THEN
        INSERT INTO PAIS(nombrePais) VALUES (new.nombrePais);
        SELECT id_pais INTO auxIdPais FROM PAIS WHERE nombrePais = new.nombrePais;
    END IF;

    SELECT id_prov INTO auxIdProvincia FROM PROVINCIA WHERE id_prov = new.idProv;
    IF (auxIdProvincia IS NULL) THEN
        auxIdProvincia = CAST(new.idProv AS INTEGER);
       INSERT INTO PROVINCIA VALUES (auxIdProvincia, auxIdPais);
    END IF;

    SELECT id_departamento INTO auxIdDepto FROM DEPARTAMENTO WHERE nombreDepto = new.nombreDepto;
    if (auxIdDepto is null) THEN
        INSERT INTO DEPARTAMENTO(nombreDepto, provincia) VALUES (new.nombreDepto, auxIdProvincia);
        SELECT id_departamento INTO auxIdDepto FROM DEPARTAMENTO WHERE nombreDepto = new.nombreDepto;
    END IF;

    INSERT INTO LOCALIDAD(nombre, id_departamento, canthab)
    VALUES (new.nombreLocalidad, auxIdDepto, cast(coalesce(new.canthab,0) as integer));

    return NULL;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER fillData
    BEFORE INSERT
    ON AUXILIAR
    FOR EACH ROW
EXECUTE PROCEDURE validateData();

COPY AUXILIAR (nombreLocalidad, nombrePais, idProv, nombreDepto, canthab) FROM 'C:\Users\Agustin\Desktop\Facultad\Tercero\Primer Cuatrimestre\Base de datos I\TP\TP-SQL\localidades.csv' WITH (FORMAT csv,HEADER TRUE);

drop table LOCALIDAD;
drop table DEPARTAMENTO;
drop table PROVINCIA;
drop table PAIS;
drop table AUXILIAR;

DROP FUNCTION validateData;

DROP TRIGGER fillData ON AUXILIAR;


