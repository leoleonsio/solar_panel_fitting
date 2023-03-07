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

-- full function for panel simulation
-- it works on a single roof_surface geometry
CREATE OR replace FUNCTION panel_simulation(roof_surface geometry)
 RETURNS geometry
 LANGUAGE plpgsql
AS $function$
DECLARE
	dx float;
	dy float;
	x_size numeric;
	y_size numeric;
	interval float;
	roof_geom geometry;
	iter int;
	cur_max int;
	cur_val int;
	x_min numeric;
	y_min numeric;
	best_geom geometry;
	cur_geom geometry;
	angle float;
	angle_step float;
begin
    x_size := 1.0;
    y_size := 1.5;
    interval := 0.15;
    iter := 1;
    dx := 0.0;
    dy := 0.0;
    cur_max := 0;
    cur_val := 0;
    angle := 0;
    angle_step := 0.07;

    drop table if exists temp_grid;
    create temp table temp_grid as
    select * from generate_grid(roof_surface, x_size, y_size);

    WHILE dy < y_size LOOP

        WHILE dx < x_size LOOP

            while angle < pi() loop

                IF iter > 100000 THEN
                    return best_geom;
                END IF;

                IF iter=1 then
                    select count(*), st_collect(g.geom)
                    into cur_max, best_geom
                    from temp_grid g
                    where st_contains(roof_surface, g.geom);


                else

                    with t1 as
                    (SELECT ST_Translate(g.geom, dx, dy) geom
                    FROM temp_grid g),
                    t as
                    (
                    select st_rotate(t1.geom, angle, (select st_centroid(st_collect(t1.geom)) from t1)) geom from t1
                    )
                    SELECT count(*) , st_collect(t.geom) geom
                    into cur_val, cur_geom
                    from t
                    where ST_Contains(roof_surface, t.geom);

                    IF cur_val > cur_max then
                        cur_max := cur_val;
                        best_geom := cur_geom;
                    END IF;
                END IF;

                iter := iter + 1;
                angle := angle + angle_step;
            end loop;

            angle := 0;
            dx := dx + interval;
        END LOOP;

     dx := 0;
     dy := dy + interval;
END LOOP;

return best_geom;
END;
$function$
;


drop table if exists solution_sample;
create table solution_sample
(id serial primary key,
roof_id int,
geom geometry
);


-- small sample test
insert into solution_sample (roof_id, geom)
select id, panel_simulation(geometry)
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





