/*Les données sont dans le dossier data du repo SQL-Journey. Je travaillerai avec les localités et les limites de commune du Bénin.*/

// 1- Trouver le scr des données
select st_srid(geom) as srid 
from localite 
group by srid; //-- on peut utilisé limit 1 au lieu du group by, les données sont en epsg 32631

//2- calculer la superficie des communes en Km², garder 2 chiffres après la virgule, puis les ordonner par ordre décroissant
select nom_com, round(cast((st_area(geom)/10000) as decimal),2) as sup_km2 
from commune
order by sup_km2 desc
/* dans l'ordre on calcule la superficie quon divise pour l'avoir en km², ensuite on la converti en un réel ou numeric pour utiliser le round 
  et garder les 2 chiffres après la virgule*/ 
  
//3- Quelles sont les 5 communes avec le plus de densité de population au Km²
select nom_com, pop2013,
round(cast((st_area(geom)/10000) as decimal),2) as sup_km2,
cast(pop2013 as numeric)/ round(cast((st_area(geom)/10000) as decimal),2) as dens_km2
from commune
order by dens_km2 desc
limit 5

/* En regardant les données on se rend compte que la colonne pop2013 est en varchar, donc on convertit avant de réaliser l'opération de division
ensuite limit 5 pou garder les 5 first "Cotonou","Porto-novo","Adjarra","Avrankou", "Akpro-Missérété"/







