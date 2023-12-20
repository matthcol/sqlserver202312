-- where / groupby / having (PAR, POUR CHAQUE)
-- Q1: acteurs, nb films, période 90-99, ayant joué plus de x films
select 
	a.id, a.name,
	count(m.id) as nb_movie,
	min(m.year) as first_year,
	max(m.year) as max_year,
	string_agg(m.title,'/') within group (order by m.year)
from 
	person a
	join play p on a.id = p.actor_id
	join movie m on m.id = p.movie_id
where m.year between 1990 and 1999
group by a.id, a.name
having count(m.id) >= 5 -- where si sous-requete
order by nb_movie desc, name;

-- autre version
with cteFilmsAnnee90 as (

	select *

	from movie m

	where m.year between 1990 and 2000

), cteActorsPlusDe as (

	select count(*) as nb_movies

		, actor_id

	from cteFilmsAnnee90

	inner join play pl

	on pl.movie_id = cteFilmsAnnee90.id
 
	group by pl.actor_id

	having count(*) > 5

)

select 

	p.name

	, cteActorsPlusDe.nb_movies

from cteActorsPlusDe
 
inner join person p

on p.id = cteActorsPlusDe.actor_id
 
order by cteActorsPlusDe.nb_movies desc;

-- le plus, superieur à la moyenne
-- Q2: films de duree max (à 5% près)
-- sans marge
select *
from movie
where duration = (
	select max(duration) as duration_max from movie
);
-- avec marge de 5%
with movie_not_too_long as (
	select * from movie
	where id not in (185906,374463,108941,2305700)
)
select *
from movie_not_too_long
where duration >= (
	select max(duration)*0.95 as duration_max from movie_not_too_long
);

select * 
from movie
where cast(duration as decimal)/(select max(duration)
				from movie
				where movie.id not in (185906,374463,108941,2305700,118460))*100 >= 95
order by duration desc
-- Q3: realisateur ayant fait le plus de film
-- step 1: count
select 
	director_id,
	count(id) as nb_movie
from movie
group by director_id
order by nb_movie desc;
-- step 2
-- nb: max(count(id)) => Cannot perform an aggregate function on an expression containing an aggregate or a subquery.
-- step 3: ajouter le réalisateur
with director_count as (
	select 
		director_id,
		count(id) as nb_movie
	from movie
	group by director_id
)
select 
	d.name, dc.nb_movie
from 
	director_count dc
	join person d on dc.director_id = d.id
where dc.nb_movie = (
	select 
		max(nb_movie)
	from director_count
);



-- problème de la division relationnelle (TOUS)
-- Q4:  famous_directors: Steven Spielberg, Clint Eastwood, Quentin Tarantino, Martin Scorsese
-- trouver les acteurs ayant joué avec TOUS ces réalisateurs
-- IDEA: 'play' % famous_director => acteurs
with famous_director as (
	select * from person
	where name in (
		'Steven Spielberg', 'Clint Eastwood', 'Quentin Tarantino', 'Martin Scorsese'
	)
);
-- stratégie 1: compter (attention aux doublons)
-- stratégie 2: double not exists

with cteDirectors as (
	select p.id
	from person p
	where p.name in (
		'Steven Spielberg'
		,'Clint Eastwood'
		,'Quentin Tarantino'
		,'Martin Scorsese'
	)
), cteActorDirector as (
	select
		cteDirectors.id
		, pl.actor_id
	from 
		play pl
 		inner join movie m
			on m.id = pl.movie_id
 		inner join cteDirectors
			on cteDirectors.id = m.director_id
 	where pl.actor_id <> cteDirectors.id
 	group by pl.actor_id, cteDirectors.id -- eliminate doubles
)
select 
	cteActorDirector.actor_id
	, p.name,
	count(*) as nb_director
from 
	cteActorDirector  
	inner join person p
		on p.id = cteActorDirector.actor_id
group by cteActorDirector.actor_id, p.name
having count(*) = (SELECT count(*) from cteDirectors)
-- having count(*) >= (SELECT count(*) from cteDirectors) - 1  -- pour avoir 3 et 4/4
;

-- J:
with famousProducers as (
	select *
	from person
	where person.name in ('Steven Spielberg', 'Clint Eastwood', 'Quentin Tarantino', 'Martin Scorsese')
)
, actorsPlayedForProducers as (
	select play.actor_id, movie.director_id
		from play
		inner join movie
			on play.movie_id = movie.id
		-- inner join famousProducers
		--	on famousProducers.id = movie.director_id
		where movie.director_id in (select famousProducers.id
									from famousProducers)
		group by play.actor_id, movie.director_id
)
select actor_id, p.name
from actorsPlayedForProducers
inner join person as p
on p.id = actor_id
group by actor_id, p.name
having count(actor_id) >= 4;


-- 
with director as (
	select *
	from person 
	where name in (
		'Steven Spielberg'
		,'Clint Eastwood'
		,'Quentin Tarantino'
		,'Martin Scorsese'
	)
)
select *
from person actor
where not exists (
	select * from director
	where not exists (
		select *
		from play p join movie m on p.movie_id = m.id
		where p.actor_id = actor.id
			and m.director_id = director.id
	)
)
;

