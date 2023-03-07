CREATE OR replace FUNCTION panel_simulation(roof_surface geometry, x_size numeric, y_size numeric, margin float)
 RETURNS geometry
 LANGUAGE plpgsql
AS $function$
DECLARE
	dx float;
	dy float;
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
	buffered geometry;
begin
interval := (x_size + y_size) * 0.2;
iter := 1;
dx := 0.0;
dy := 0.0;
cur_max := 0;
cur_val := 0;
angle := 0;
angle_step := 0.04;

drop table if exists temp_grid;
create temp table temp_grid as
select * from generate_grid(roof_surface, x_size, y_size);

-- point on plane 
buffered := st_buffer(roof_surface, -margin);

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
				where st_contains(buffered, g.geom);
			
			
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
				where ST_Contains(buffered, t.geom);
				
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
