-- 24. Вывести сумму, дату и день недели для каждой оплаты
select
    payment_id,
    amount,
    payment_date::date as payment_date,
    case extract(isodow from payment_date)
        when 1 then 'Понедельник'
        when 2 then 'Вторник'
        when 3 then 'Среда'
        when 4 then 'Четверг'
        when 5 then 'Пятница'
        when 6 then 'Суббота'
        when 7 then 'Воскресенье'
    end as day_of_week
from payment
order by payment_id;

-- 25. Категории фильмов по длительности.
--     Считать только фильмы, у которых были прокаты.
with rented_films as (
    select
        f.film_id,
        r.rental_id,
        case
            when f.length < 70 then 'Короткие'
            when f.length >= 70 and f.length < 130 then 'Средние'
            else 'Длинные'
        end as duration_category
    from film f
    join inventory i on i.film_id = f.film_id
    join rental r    on r.inventory_id = i.inventory_id
)
select
    duration_category,
    count(rental_id) as rentals_count,
    count(distinct film_id) as films_count
from rented_films
group by duration_category
order by case duration_category
    when 'Короткие' then 1
    when 'Средние'  then 2
    when 'Длинные'  then 3
end;

-- Подготовка таблицы weekly_revenue для следующих запросов
drop table if exists weekly_revenue;

create table weekly_revenue as
select
    extract(year from r.rental_date)::int as r_year,
    extract(week from r.rental_date)::int as r_week,
    coalesce(sum(p.amount), 0) as revenue
from rental r
left join payment p on p.rental_id = r.rental_id
group by 1, 2
order by 1, 2;

select *
from weekly_revenue
order by r_year, r_week;

-- 26. Накопленная сумма недельной выручки бизнеса
select
    r_year,
    r_week,
    revenue,
    round(
        sum(revenue) over (
            order by r_year, r_week
            rows between unbounded preceding and current row
        ),
        0
    ) as cumulative_revenue
from weekly_revenue
order by r_year, r_week;

-- 27. Скользящая средняя недельной выручки
select
    r_year,
    r_week,
    revenue,
    round(
        sum(revenue) over (
            order by r_year, r_week
            rows between unbounded preceding and current row
        ),
        0
    ) as cumulative_revenue,
    round(
        avg(revenue) over (
            order by r_year, r_week
            rows between 1 preceding and 1 following
        ),
        0
    ) as moving_avg_revenue
from weekly_revenue
order by r_year, r_week;

-- 28. Прирост недельной выручки бизнеса в %
with revenue_calc as (
    select
        r_year,
        r_week,
        revenue,
        sum(revenue) over (
            order by r_year, r_week
            rows between unbounded preceding and current row
        ) as cumulative_revenue,
        avg(revenue) over (
            order by r_year, r_week
            rows between 1 preceding and 1 following
        ) as moving_avg_revenue,
        lag(revenue) over (order by r_year, r_week) as prev_revenue
    from weekly_revenue
)
select
    r_year,
    r_week,
    revenue,
    round(cumulative_revenue, 0) as cumulative_revenue,
    round(moving_avg_revenue, 0) as moving_avg_revenue,
    round(
        ((revenue - prev_revenue) / nullif(prev_revenue, 0)) * 100,
        2
    ) as revenue_growth_pct
from revenue_calc
order by r_year, r_week;
