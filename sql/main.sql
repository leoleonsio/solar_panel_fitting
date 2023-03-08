-- before running, first define the functions given in the other .sql files

drop table if exists roofs;

create table roofs(
id int primary key,
bid text,
orientation text,
geometry geometry
);


COPY roofs FROM 'data/roofs.csv' delimiter ';' CSV header;

drop table if exists roofs_2d;
create table roofs_2d as 
select id, bid, orientation, st_force2d(geometry) as geometry
from roofs;

-- set correct srid
update roofs set geometry = st_setsrid(geometry, 28992);

-- example generating of a grid for a selected roof surface
-- select * from generate_grid((select geometry from roofs_2d where id = 177), 1.8, 1.2);


drop table if exists solution_sample;
create table solution_sample
(id serial primary key,
roof_id int,
geom geometry
);


-- small sample test
insert into solution_sample (roof_id, geom)
select id, panel_simulation(geometry, 1.0, 1.5, 0.3)
from roofs_2d
where id in (177, 1562);


drop table if exists solution3d_sample;
create table solution3d_sample as
select s.id, s.roof_id, to3d(s.geom, r.geometry) geom
from solution_sample s
inner join roofs r on r.id = s.roof_id;


-- full run for all the rooftops - takes 5 minutes on my pc
-- drop table if exists solution3d;
-- create table solution3d as
-- with sol as
--          (
--              select row_number() over() id, id roof_id, bid, panel_simulation(geometry, 1.0, 1.5, 0.3) geom
--              from roofs_2d
--              where orientation in ('SW', 'SE')
--          )
-- select s.id, s.roof_id, to3d(s.geom, r.geometry) geom
-- from sol s
--          inner join roofs r on r.id = s.roof_id;





