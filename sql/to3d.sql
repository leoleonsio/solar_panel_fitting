create or replace function to3d(panels geometry, roof_surface geometry)
 RETURNS geometry
 LANGUAGE plpgsql
AS $function$
declare
	v_geom geometry;
begin 
	with polygons as
	(
		select st_dump(panels) d
	),
	points as
	(
		select (d).path, st_force3d((st_dumppoints((d).geom)).geom) geom
		from polygons
	),
	points3 as
	(
		select p.path,
		st_3dclosestpoint(
					roof_surface, 
					st_makeline(st_translate(p.geom, 0, 0, -50), st_translate(p.geom, 0, 0, 50)))  geom
		from points p
	),
	panels_projected as
	(
		select path[1] id, st_makepolygon(st_addpoint(st_makeline(geom), st_startpoint(st_makeline(geom)))) geom
		from points3
		group by path
	)
	
	select st_collect(st_removerepeatedpoints(geom)) 
	into v_geom
	from panels_projected;

return v_geom;
end;
$function$;
