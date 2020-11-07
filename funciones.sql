CREATE TABLE PAIS
(
    id_pais    serial not null primary key,
    nombrePais text   not null unique
);

CREATE TABLE PROVINCIA
(
    id_prov int not null primary key,
    id_pais int not null,
    foreign key (id_pais) references PAIS on delete restrict
);

CREATE TABLE DEPARTAMENTO
(
    id_departamento serial not null primary key,
    nombreDepto     text   not null unique,
    provincia       int    not null,
    foreign key (provincia) references PROVINCIA on delete restrict
);

CREATE TABLE LOCALIDAD
(
    id_localidad    serial not null primary key,
    nombre          text   not null,
    id_departamento int    not null,
    canthab         int,
    foreign key (id_departamento) references DEPARTAMENTO on delete restrict
);

CREATE TABLE AUXILIAR
(
    nombreLocalidad text,
    nombrePais      text,
    idProv          int,
    nombreDepto     text,
    canthab         int
);

CREATE OR REPLACE FUNCTION seedData() RETURNS TRIGGER AS
$$
DECLARE
    auxIdPais      PAIS.id_pais%TYPE;
    auxIdDepto     DEPARTAMENTO.id_departamento%TYPE;
    auxIdProvincia PROVINCIA.id_prov%TYPE;

BEGIN

    select id_pais into auxIdPais from pais where nombrePais = new.nombrePais;
    if (auxIdPais is null) THEN
        insert into pais(nombrePais) values (new.nombrePais);
        select id_pais into auxIdPais from pais where nombrePais = new.nombrePais;
    END IF;

    select id_prov into auxIdProvincia from provincia where id_prov = new.idProv;
    if (auxIdProvincia is null) THEN
        auxIdProvincia := cast(new.idProv as integer);
        insert into provincia values (auxIdProvincia, auxIdPais);
    END IF;

    select id_departamento into auxIdDepto from departamento where nombreDepto = new.nombreDepto;
    if (auxIdDepto is null) THEN
        INSERT INTO DEPARTAMENTO(nombreDepto, provincia) VALUES (new.nombreDepto, auxIdProvincia);
        select id_departamento into auxIdDepto from departamento where nombreDepto = new.nombreDepto;
    END IF;

    INSERT INTO LOCALIDAD(nombre, id_departamento, canthab)
    VALUES (new.nombreLocalidad, auxIdDepto, cast(coalesce(new.canthab, 0) as integer));

    return new;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION removeData() RETURNS TRIGGER AS
$$
BEGIN

    return NULL;
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

drop table LOCALIDAD;
drop table DEPARTAMENTO;
drop table PROVINCIA;
drop table PAIS;

DROP TRIGGER seedDataTrigger ON AUXILIAR;

DROP FUNCTION seedData;

drop table AUXILIAR;



