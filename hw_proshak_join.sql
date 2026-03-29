-- 12. Вывести количество уникальных имен клиентов
select count(distinct first_name) as unique_customer_first_names
from customer;

-- 13. Вывести 5 самых частых сумм оплаты, их даты, количество и сумму платежей одинакового номинала
--     Вариант с группировкой по сумме и дате платежа.
select
    amount,
    payment_date::date as payment_date,
    count(*) as payments_count,
    sum(amount) as total_amount
from payment
group by amount, payment_date::date
order by payments_count desc, amount desc, payment_date asc
limit 5;

-- 14. Вывести число ячеек в инвентаре каждого магазина
select
    store_id,
    count(*) as inventory_cells_count
from inventory
group by store_id
order by store_id;

-- 15. Вывести адреса всех магазинов (JOIN)
select
    s.store_id,
    a.address,
    a.district,
    c.city,
    co.country
from store s
join address a on a.address_id = s.address_id
join city c    on c.city_id = a.city_id
join country co on co.country_id = c.country_id
order by s.store_id;

-- 16. Вывести полные имена всех клиентов и сотрудников в одну колонку
select first_name || ' ' || last_name as full_name
from customer
union all
select first_name || ' ' || last_name as full_name
from staff;

-- 17. Вывести имена клиентов, которые не совпадают с именами сотрудников (EXCEPT)
select first_name
from customer
except
select first_name
from staff
order by first_name;

-- 18. Вывести кто, когда и у кого брал диски в аренду в июне 2005 года
select
    customer_id,
    rental_date::date as rental_date,
    staff_id
from rental
where rental_date >= timestamp '2005-06-01'
  and rental_date <  timestamp '2005-07-01'
order by rental_date, customer_id, staff_id;

-- 19. Вывести id клиентов, которые имеют 40+ оплат, и средний размер транзакции
select
    customer_id,
    count(*) as payments_count,
    round(avg(amount), 2) as avg_transaction_amount
from payment
group by customer_id
having count(*) >= 40
order by customer_id;

-- 20а. Вывести id, полное имя актера и посчитать, в скольких фильмах снялся
select
    a.actor_id,
    a.first_name || ' ' || a.last_name as actor_full_name,
    count(fa.film_id) as films_count
from actor a
left join film_actor fa on fa.actor_id = a.actor_id
group by a.actor_id, a.first_name, a.last_name
order by films_count desc, actor_full_name asc;

-- 20б. Какой актер снялся в бОльшем количестве фильмов
select
    a.actor_id,
    a.first_name || ' ' || a.last_name as actor_full_name,
    count(fa.film_id) as films_count
from actor a
left join film_actor fa on fa.actor_id = a.actor_id
group by a.actor_id, a.first_name, a.last_name
order by films_count desc, actor_full_name asc
limit 1;

-- 21. Посчитать выручку в каждом месяце работы проката
--     Месяц считается по rental_date, не по payment_date.
with month_bounds as (
    select
        date_trunc('month', min(rental_date))::date as min_month,
        date_trunc('month', max(rental_date))::date as max_month
    from rental
), months as (
    select generate_series(min_month, max_month, interval '1 month')::date as month_start
    from month_bounds
), monthly_revenue as (
    select
        date_trunc('month', r.rental_date)::date as month_start,
        coalesce(sum(p.amount), 0) as revenue
    from rental r
    left join payment p on p.rental_id = r.rental_id
    group by 1
)
select
    m.month_start,
    round(coalesce(mr.revenue, 0), 1) as revenue
from months m
left join monthly_revenue mr on mr.month_start = m.month_start
order by m.month_start;

-- 22. Средний платеж по каждому жанру фильма.
--     Показать жанры, к которым относится более 60 разных фильмов.
select
    c.name as genre,
    count(distinct fc.film_id) as films_count,
    round(avg(p.amount), 2) as avg_payment_amount
from category c
join film_category fc on fc.category_id = c.category_id
join inventory i      on i.film_id = fc.film_id
join rental r         on r.inventory_id = i.inventory_id
join payment p        on p.rental_id = r.rental_id
group by c.category_id, c.name
having count(distinct fc.film_id) > 60
order by avg_payment_amount desc, genre asc;

-- 23. Какие фильмы чаще всего берут напрокат по субботам
select
    f.title,
    count(*) as rentals_count
from rental r
join inventory i on i.inventory_id = r.inventory_id
join film f      on f.film_id = i.film_id
where extract(isodow from r.rental_date) = 6
group by f.film_id, f.title
order by rentals_count desc, f.title asc
limit 5;