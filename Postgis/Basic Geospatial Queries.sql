/*Les données sont dans le dossier data du repo SQL-Journey. Je travaillerai avec les localités et les limites de commune du Bénin.
Vous pouvez ajouter ces données à une bdd en utilisant qgis, arcgis pro, fme par exemple. Il y a aussi un backup de la base que vous pouvez utiliser directement
Créez une base postgre que vous appelez postgis, ensuite vous faites un restore avec le fichier postgis.backup 
ressource utile --> https://postgis.net/docs/manual-3.6/postgis_cheatsheet-fr.html*/

/*--1-Trouver le scr des données*/
select st_srid(geom) as srid 
	from localite 
	group by srid; -- on peut utilisé limit 1 au lieu du group by, les données sont en epsg 32631


/*--2-calculer la superficie des communes en Km², garder 2 chiffres après la virgule, puis les ordonner par ordre décroissant */
-- dans l'ordre on calcule la superficie quon divise pour l'avoir en km², ensuite on la convertit en un réel ou numeric pour utiliser le round et garder les 2 chiffres après la virgule 

select nom_com, round(cast((st_area(geom)/10000) as decimal),2) as sup_km2 
	from commune
	order by sup_km2 desc
 
/*--3-Quelles sont les 5 communes avec le plus de densité de population au Km²*/
select nom_com, pop2013,
	round(cast((st_area(geom)/1000000) as decimal),2) as sup_km2,
	cast(pop2013 as numeric)/ round(cast((st_area(geom)/1000000) as decimal),2) as dens_km2
	from commune
	order by dens_km2 desc
	limit 5

/* En regardant les données on se rend compte que la colonne pop2013 est en varchar, donc on convertit avant de réaliser l'opération de division
ensuite limit 5 pour garder les 5 first "Cotonou","Porto-novo","Adjarra","Avrankou", "Akpro-Missérété"*/

/*--4-Réaliser une somme cumulative de l'effectif de la population en ordonnant par ordre alphabétique suivant le département, puis la commune*/
 --Pour calculer une somme cumulative, il faut garder en tête les deux fonctions SUM et OVER. Syntaxe : SUM(colonne) OVER (ORDER by colonne1, col2)
	
select code_dep, nom_com, pop2013, 
	sum(cast(pop2013 as integer)) over(order by code_dep, nom_com) as popcumul
	from commune

/*--5- calculer la superficie totale de chaque département  et faire une somme cumulative pour avoir la superficie totale en Km² */
/*le plus simple est de décomposer la requête en deux parties et d'utiliser une cte pour combiner les geom des communes en départements puis, faire après une somme cumulative*/

with cte_superficie as (
	select st_union(geom) as geom2, code_dep from commune group by code_dep -- fusionner les géométries des communes en fonction des départements pour en avoir une/dep
	)
select code_dep, 
	st_area(geom2)/1000000 as sup_km2, 
	sum(st_area(geom2)/1000000) over (order by code_dep) as cumul
	from cte_superficie

/*--6- selectionner les localités du departement 01 */
/* On récupère cette info via une sélection par localisation, le plus simple est de décomposer la requête en deux parties et d'utiliser une cte*/

with cte_dep01 as ( --creation de la cte
  select st_union(geom) as geom from commune where code_dep = '01' -- je fais une fusion des communes pour avoir une géométrie unique
  )
select localite.nom_loc, 
	localite.commune, 
	localite.geom -- je récupère les attributs qui m'intéressent de la couche localite
	from localite
		where st_intersects(localite.geom, (select geom from cte_dep01 /* je récupère la geom de la cte */)) -- filtrage selon l'intersection entre les deux couches

/*--7- Trouver les 10 noms de localités les plus courants */
select nom_loc, 
	count(*) as compte 
		from localite
		group by nom_loc
		order by compte desc
		limit 10

/*--8- Calculer la distance de chaque chef-lieu de commune ou de département par rapport à la capitale */

with cte_capitale as(
select nom_loc, geom from localite where statut_adm = 'CAPITALE' -- faire une cte pour récupérer la capitale
)
select nom_loc, 
	round(cast(st_distance(geom, (select cte_capitale.geom from cte_capitale))/1000 as decimal), 2)  as distance_km 
	-- utilisation de la fonction  st_distance + quelques opérations pour arrondir et avoir la distance en Km
		from localite 
		where statut_adm = 'CL_COMMUNE' or statut_adm = 'CL_DEPARTEMENT'
		order by distance_km asc 


/*--9- Créer des contours de département à partir des communes qui sont dans le même département, ensuite affecter les bons noms de départements aux entités créées */

select code_dep, 
	case when code_dep = '01' then  'Alibori' --utiliser case pour affecter les valeurs conditionnelles
	 when code_dep = '02' then  'Atacora'
	 when code_dep = '03' then  'Atlantique'
	 when code_dep = '04' then  'Borgou'
	 when code_dep = '05' then  'Couffo'
	 when code_dep = '06' then  'Collines'
	 when code_dep = '07' then  'Donga'
	 when code_dep = '08' then  'Littoral'
	 when code_dep = '09' then  'Mono'
	 when code_dep = '10' then  'Ouémé'
	 when code_dep = '11' then  'Plateau'
	 when code_dep = '12' then  'Zou'
	end as nom_dep, -- mettre l'alias après le end
	st_union(geom) -- l'union des géométries
		from commune 
		group by code_dep --regrouper  par code dep pour avoir une entité (attributs et géométries) par département 
		order by code_dep asc

/*--10- Puisqu'il y a des trous dans les polygones, on va compter le nombre de trous dans chaque polygone.*/

	with cte_dep as --je reprends la requête précédente que je mets dans une cte pour commencer
	(select code_dep, 
	    case when code_dep = '01' then  'Alibori'
		 when code_dep = '02' then  'Atacora'
		 when code_dep = '03' then  'Atlantique'
		 when code_dep = '04' then  'Borgou'
		 when code_dep = '05' then  'Couffo'
		 when code_dep = '06' then  'Collines'
		 when code_dep = '07' then  'Donga'
		 when code_dep = '08' then  'Littoral'
		 when code_dep = '09' then  'Mono'
		 when code_dep = '10' then  'Ouémé'
		 when code_dep = '11' then  'Plateau'
		 when code_dep = '12' then  'Zou'
		end as nom_dep, 	
		st_union(geom) as geom2
		from commune group by code_dep
	)
	select code_dep, 
	nom_dep, 	
	geom2, 
	st_numinteriorring(geom2) as nb_trous -- ici j'utilise la fonction qui fais ressortir le nombre de trous  l'intérieur d'un polygone
	from cte_dep
		
/*--11- On va maintenant supprimer les trous dans les polygones et garder uniquement le polygone avec son enveloppe externe. On veut le résultat sous la forme d'un polygone*/
	/*
	Avant de continuer, je fais une note sur les types de données composites : ils permettent de regrouper plusieurs champs de différents types en une seule colonne. 
	Par exemple un type composite que j'appelle "adresse" où dans la colonne adresse j'ai 4 infos différentes mais en un seul enregistrement : adresse (rue TEXT, ville TEXT, code_postal INT, geom geometry)
	La fonction st_dumprings(https://postgis.net/docs/st_DumpRings.html) est très utile ici car non seulement elle extrait tous les anneaux d'un polygone mais elle stocke cette information sous la forme 
	d'un type de données composite au format (path, geometry) où : 
		- path : tableau d'entiers de longueur 1 contenant l'indice de l'anneau du polygone. Anneau extérieur --> 0. Trous --> indices 1 et plus.
		- geometry : géométrie de l'anneau sous forme de polygone. 
	*/

with cte_dep as ( -- je reprends la requête précédente
    select 
        code_dep, 
	case 
		when code_dep = '01' then  'Alibori'
		 when code_dep = '02' then  'Atacora'
		 when code_dep = '03' then  'Atlantique'
		 when code_dep = '04' then  'Borgou'
		 when code_dep = '05' then  'Couffo'
		 when code_dep = '06' then  'Collines'
		 when code_dep = '07' then  'Donga'
		 when code_dep = '08' then  'Littoral'
		 when code_dep = '09' then  'Mono'
		 when code_dep = '10' then  'Ouémé'
		 when code_dep = '11' then  'Plateau'
		 when code_dep = '12' then  'Zou'
	end as nom_dep, 
        st_Union(geom) as geom2
		    from commune 
		    group by code_dep
),
cte_trous as ( --ici je fais une seconde cte qui va me servir pour récupérer les géométries des trous et les valeurs du type composite généré par la fonction st_DumpRings
    select 
        code_dep, 
        nom_dep, 
        st_NumInteriorRings(geom2) as nb_trous, -- je récupère le nombre de trous dans la géométrie issue de la cte précédente
        (st_DumpRings(geom2)).geom as trous_geom, -- je prends l'attribut géométrie des trous en me basant sur la géométrie issue de la cte précédente
        (st_DumpRings(geom2)).path as path -- je prends l'attribut indice des trous
    		from cte_dep
)
select -- requête finale
    code_dep, 
    nom_dep, 
    nb_trous, 
    path,
    trous_geom
from cte_trous
where path[1] = 0;  -- Filtrage du premier attribut du type composite pour ne garder que l'enveloppe externe, voir plus haut externe. fonctionne un peu comme le json

/*-- 12- Si à la question 11 on voulait juste le résultat sous la forme d'une ligne, c'est à dire le contour externe
 on utiliserait juste la fonction st_ExteriorRing() qui renvoie une ligne représentant l'anneau extérieur d'un polygone.*/

with cte_dep as (
    select 
        code_dep, 
        case 
            when code_dep = '01' then 'Alibori'
            when code_dep = '02' then 'Atacora'
            when code_dep = '03' then 'Atlantique'
            when code_dep = '04' then 'Borgou'
            when code_dep = '05' then 'Couffo'
            when code_dep = '06' then 'Collines'
            when code_dep = '07' then 'Donga'
            when code_dep = '08' then 'Littoral'
            when code_dep = '09' then 'Mono'
            when code_dep = '10' then 'Ouémé'
            when code_dep = '11' then 'Plateau'
            when code_dep = '12' then 'Zou'
        end as nom_dep, 	
        st_Union(geom) as geom2
    from commune 
    group by code_dep
)
select 
    code_dep, 
    nom_dep, 	
    st_exteriorring(geom2) as contours_externes ---> la fonction pour obtenir les contours externes
from cte_dep;

/*--13- la réponse la plus simple à la question 11 serait dans un premier temps de récupérer le contour externe sous la forme d'une ligne puis de le convertir en polygone*/

with cte_dep as (
    select 
        code_dep, 
        case 
            when code_dep = '01' then 'Alibori'
            when code_dep = '02' then 'Atacora'
            when code_dep = '03' then 'Atlantique'
            when code_dep = '04' then 'Borgou'
            when code_dep = '05' then 'Couffo'
            when code_dep = '06' then 'Collines'
            when code_dep = '07' then 'Donga'
            when code_dep = '08' then 'Littoral'
            when code_dep = '09' then 'Mono'
            when code_dep = '10' then 'Ouémé'
            when code_dep = '11' then 'Plateau'
            when code_dep = '12' then 'Zou'
        end as nom_dep, 	
        st_Union(geom) as geom2
    from commune 
    group by code_dep
)
select 
    code_dep, 
    nom_dep, 	
    st_NumInteriorRings(geom2) as nb_trous, 
    st_makepolygon(st_exteriorring(geom2)) as contours_polygone -- récupérer le contours et le convertir en polygone
from cte_dep 

/*--14- Créons une vue qui va stocker cette table qu'on vient de créer*/
create or replace view v_depar as -- syntaxe de création d'une vue
--- je réutilise ma requete du 13, il est nécessaire de mettre l'alias de la géométrie en geom pour la vue, je ne sais pas pourquoi. 
-- j'ai essayé avec l'alias contours_polygone mais ça ne marchait pas, c'est à croire qu'il y a des contraintes dans postgis qui imposent geom comme nom de colonne pour les vues
with cte_dep as (
    select 
        code_dep, 
        case 
            when code_dep = '01' then 'Alibori'
            when code_dep = '02' then 'Atacora'
            when code_dep = '03' then 'Atlantique'
            when code_dep = '04' then 'Borgou'
            when code_dep = '05' then 'Couffo'
            when code_dep = '06' then 'Collines'
            when code_dep = '07' then 'Donga'
            when code_dep = '08' then 'Littoral'
            when code_dep = '09' then 'Mono'
            when code_dep = '10' then 'Ouémé'
            when code_dep = '11' then 'Plateau'
            when code_dep = '12' then 'Zou'
        end as nom_dep, 	
        st_Union(geom) as geom2
		    from commune 
		    group by code_dep
)
select 
    code_dep, 
    nom_dep, 	
    st_NumInteriorRings(geom2) as nb_trous, 
    st_makepolygon(st_exteriorring(geom2)) as geom -- récupérer le contours et le convertir en polygone en gardant geom comme alias
from cte_dep ;


/*--15- Compter le nombre de communes dans chaque département, le nombre d'arronndissement, et le nombre de localités en utilisant les tables localite et commune et la vue v_depar*/












