-- CREACION DE TABLAS

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

CREATE TRIGGER fillData
    BEFORE INSERT
    ON LOCALIDAD
    FOR EACH ROW
EXECUTE PROCEDURE validateData();


CREATE OR REPLACE FUNCTION validateData() RETURNS TRIGGER AS
$$

DECLARE

    idPais  pais.id_pais%TYPE;
    idDepto departamento.id_departamento%TYPE;
    idProv  provincia.id_prov%TYPE;

BEGIN
    select id_pais into idPais from pais where nombrePais = new.pais;
    if (idPais is null) THEN
        insert into pais(nombrePais) values (new.pais);
    END IF;

    select provincia into idProv from provincia where id_prov = new.provincia;
    if (idProv is null) THEN
        insert into provincia values (new.provincia, id_pais);
    END IF;

    select id_departamento into idDepto from departamento where nombreDepto = new.departamento;
    if (idDepto is null) THEN
        INSERT INTO DEPARTAMENTO(nombreDepto, provincia) VALUES (new.departamento, idProv);
    END IF;

    INSERT INTO LOCALIDAD(nombre, id_departamento, canthab) VALUES (new.nombre, idDepto, new.canthab);

    return NULL;
END;
$$ LANGUAGE plpgsql;

COPY LOCALIDAD FROM 'C:\Users\Agustin\Desktop\Facultad\Tercero\Primer Cuatrimestre\Base de datos I\TP\TP-SQL\localidades.csv' DELIMITER ',' CSV HEADER;

drop table LOCALIDAD;
drop table departamento;
drop table provincia;
drop table pais;


