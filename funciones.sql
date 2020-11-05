CREATE TABLE pais
(
id_pais serial not null primary key,
nombre text not null unique
);

CREATE TABLE provincia
(
provincia int not null primary key,
id_pais int not null,
foreign key (id_pais) references pais on delete restrict
);

CREATE TABLE departamento
(
id_departamento serial not null primary key,
departamento text not null unique,
provincia int not null,
foreign key (provincia) references provincia on delete restrict
);

CREATE TABLE  LOCALIDAD
(
    id_localidad serial not null primary key,
    nombre text not null,
    id_departamento int not null,
    canthab int,
    foreign key (id_departamento) references departamento on delete restrict
);

CREATE TRIGGER fillData
    BEFORE INSERT ON LOCALIDAD
    FOR EACH ROW
    EXECUTE PROCEDURE validateData();


CREATE OR REPLACE FUNCTION validateData() RETURNS TRIGGER AS $$

    DECLARE

        idPais pais.id_pais%TYPE;
        idDepto departamento.id_departamento%TYPE;
        idProv provincia.provincia%TYPE;

        BEGIN
            select id_pais into idPais from pais where pais = new.pais;
            if(idPais is null ) THEN
                insert into pais(pais.pais) values(new.pais);
            END IF;

            select provincia into idProv from provincia where provincia = new.provincia;
            if(idProv is null ) THEN
                insert into provincia values(new.provincia,id_pais);
            END IF;

            select id_departamento into idDepto from departamento where departamento.departamento = new.departamento;
            if(idDepto is null ) THEN
                INSERT INTO DEPARTAMENTO(departamento.departamento, provincia) VALUES(new.departamento,idProv);
            END IF;

            INSERT INTO LOCALIDAD(nombre, id_departamento, canthab) VALUES (new.nombre,idDepto,new.canthab);

        END;
$$ LANGUAGE plpgsql;


