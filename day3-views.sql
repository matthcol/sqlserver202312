-- VIEWS (LOGICAL)
drop view v_actor;
drop view v_director;
create view v_actor(id, name, birthdate) as (
	select a.id, a.name, a.birthdate
	from person a
	where exists (select * from play pl where pl.actor_id = a.id)
) with check option;
create view v_director(id, name, birthdate) as (
	select d.id, d.name, d.birthdate
	from person d
	where exists (select * from movie m where m.director_id = d.id)
) with check option;

-- sequence possible sans check option:
insert into v_actor(name) values ('Louis de Funes');
select * from person where name = 'Louis de Funes';
select * from v_actor where name = 'Louis de Funes';
-- erreur si on ajoute with check option

drop view v_movie90;
create view v_movie90 as (
	select * from movie
	where year between 1990 and 1999
) with check option;
insert into v_movie90 (title, year) values ('Barbie', 2023);
insert into v_movie90 (title, year) values ('Oppenheimer', 2023);

-- operateur ensembliste: UNION, INTERSECT, EXCEPT (avec ou sans ALL)
-- Q1: acteurs et réalisateurs (l'un ou l'autre ou les 2)
-- 47832
select * from v_actor
UNION
select * from v_director
ORDER BY name; -- commun (apres union)
-- Q2: à la fois acteurs et réalisteurs (les 2)
-- 152
select * from v_actor
INTERSECT
select * from v_director
ORDER BY name;
-- Q3: acteurs non réalisateurs
-- 47289
select * from v_actor
EXCEPT
select * from v_director
ORDER BY name;
-- Q4: réalisateurs non acteurs
-- 391
select * from v_director
EXCEPT
select * from v_actor
ORDER BY name;
-- Q5: personnes ni actor ni réalisateur
-- 1818
select id, name, birthdate from person
EXCEPT
select * from v_director
EXCEPT
select * from v_actor
ORDER BY name;