/*Les données sont dans le dossier data du repo SQL-Journey
Je travaillerai avec les localités et les limites de commune du Bénin.*/

/* 1- Trouver le scr des données*/
select st_srid(geom) as srid from localite group by srid; //-- on peut utilisé limit 1 au lieu du group by, les données sont en epsg 32631

/*2- calculer la superficie des communes et les ordonner par order décroissant*/






