CREATE TABLE PAIS
(
    id_pais    serial not null primary key,
    nombrePais text   not null unique
);

CREATE TABLE PROVINCIA
(
    id_prov int not null primary key,
    id_pais int not null,
    foreign key (id_pais) references pais on delete restrict
);

CREATE TABLE DEPARTAMENTO
(
    id_departamento serial not null primary key,
    nombreDepto     text   not null unique,
    provincia       int    not null,
    foreign key (provincia) references provincia on delete restrict
);

CREATE TABLE LOCALIDAD
(
    id_localidad    serial not null primary key,
    nombre          text   not null,
    id_departamento int    not null,
    canthab         int,
    foreign key (id_departamento) references departamento on delete restrict
);

CREATE TABLE AUXILIAR
(
    nombreLocalidad text,
    nombrePais      text,
    idProv          int,
    nombreDepto     text,
    canthab         int
);

CREATE OR REPLACE FUNCTION validateData() RETURNS TRIGGER AS
$$
DECLARE

    idPais  pais.id_pais%TYPE;
    idDepto departamento.id_departamento%TYPE;
    idProv  provincia.id_prov%TYPE;

BEGIN
    select id_pais into idPais from pais where nombrePais = new.nombrePais;
    if (idPais is null) THEN
        insert into pais(nombrePais) values (new.nombrePais);
        select id_pais into idPais from pais where nombrePais = new.nombrePais;
    END IF;


    select provincia into idProv from provincia where id_prov = new.idProv;
    if (idProv is null) THEN
        insert into provincia values (cast(new.idProv as int), idPais);
        select provincia into idProv from provincia where id_prov = new.idProv;
    END IF;


    select id_departamento into idDepto from departamento where nombreDepto = new.nombreDepto;
    if (idDepto is null) THEN
        INSERT INTO DEPARTAMENTO(nombreDepto, provincia) VALUES (new.nombreDepto, idProv);
        select id_departamento into idDepto from departamento where nombreDepto = new.nombreDepto;
    END IF;

    INSERT INTO LOCALIDAD(nombre, id_departamento, canthab)
    VALUES (new.nombreLocalidad, idDepto, cast(new.canthab as integer));

    return NULL;
END
$$ LANGUAGE plpgsql;

COPY LOCALIDAD FROM 'C:\Users\Agustin\Desktop\Facultad\Tercero\Primer Cuatrimestre\Base de datos I\TP\TP-SQL\localidades.csv' DELIMITER ',' CSV HEADER;

CREATE TRIGGER fillData
    BEFORE INSERT
    ON AUXILIAR
    FOR EACH ROW
EXECUTE PROCEDURE validateData();

COPY AUXILIAR (nombreLocalidad, nombrePais, idProv, nombreDepto, canthab) FROM 'C:\Users\Agustin\Desktop\Facultad\Tercero\Primer Cuatrimestre\Base de datos I\TP\TP-SQL\localidades.csv' WITH (FORMAT csv,HEADER TRUE);

drop table LOCALIDAD;
drop table departamento;
drop table provincia;
drop table pais;
drop table auxiliar;

DROP TRIGGER fillData ON AUXILIAR;

DROP FUNCTION validateData;