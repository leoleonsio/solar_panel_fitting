CREATE OR replace FUNCTION generate_grid(bound_polygon geometry, x_step numeric, y_step numeric, srid integer default 28992)
RETURNS table(id bigint, geom geometry)
LANGUAGE plpgsql
AS $function$
DECLARE
Xmin numeric;
	Xmax numeric;
	Ymax numeric;
	Ymin numeric;
	query_text text;
begin
	bound_polygon := st_scale(bound_polygon, st_makepoint(1.5, 1.5), st_centroid(bound_polygon));
	Xmin := floor(ST_XMin(bound_polygon));
	Xmax := ceil(ST_XMax(bound_polygon));
	Ymin := floor(ST_YMin(bound_polygon));
	Ymax := ceil(ST_YMax(bound_polygon));

	query_text := 'select row_number() over() id, st_makeenvelope(s1, s2, s1+$5, s2+$6, $7) geom
	from generate_series($1, $2, $5) s1, generate_series ($3, $4, $6) s2';

	-- $2 + $5, $4 + $6

RETURN QUERY EXECUTE query_text using Xmin, Xmax, Ymin, Ymax, x_step, y_step, srid;
END;
$function$
;