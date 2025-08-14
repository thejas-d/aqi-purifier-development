#TOP 5 HIGHEST AQI (Worst Air Quality):

select state, area,round(avg(aqi_value),2) as avg_aqi from aqi_data
WHERE date - interval 6 month
group by area ,state
order by avg_aqi desc
limit 5;

select state, area,round(avg(aqi_value),2) as avg_aqi from aqi_data
WHERE date between '2024-11-01' and '2025-04-30'
group by area ,state
order by avg_aqi desc
limit 5;

#BOTTOM 5 LOWEST AQI (Best Air Quality):

select state, area,round(avg(aqi_value),2) as avg_aqi from aqi_data
WHERE date - interval 6 month
group by area ,state
order by avg_aqi asc
limit 5;

select state, area,round(avg(aqi_value),2) as avg_aqi from aqi_data
WHERE date BETWEEN '2024-11-01' AND '2025-04-30'
group by area ,state
order by avg_aqi asc
limit 5;

#Top 2 prominent pollutants from southern state after 2022:

with cte as (select state, avg(aqi_value) as avg_aqi ,prominent_pollutants ,count(*) as freq from aqi_data 
where state in ('Karnataka','Tamil Nadu', 'Andhra Pradesh','Puducherry','Kerala','Telangana')
and date >='2022-01-01'
group by state,prominent_pollutants),
 freq_rank as (select *, rank() over (partition by state order by freq desc ) as rn from cte)
 select state , prominent_pollutants,freq from freq_rank where rn<=2 ORDER BY state, rn, freq DESC;

#Bottom 2 prominent pollutants from southern state after 2022:

with cte as (select state, avg(aqi_value) as avg_aqi ,prominent_pollutants ,count(*) as freq from aqi_data 
where state in ('Karnataka','Tamil Nadu', 'Andhra Pradesh','Puducherry','Kerala','Telangana')
and date >='2022-01-01'
group by state,prominent_pollutants),
 freq_rank as (select *, rank() over (partition by state order by freq asc) as rn from cte)
 select state , prominent_pollutants,freq from freq_rank where rn<=2 ORDER BY state,freq asc;


#Does AQI improve on weekends vs weekdays in Indian metro cities (Delhi, Mumbai, Chennai, Kolkata, Bengaluru, Hyderabad, Ahmedabad, Pune)?
# (Consider data from last 1 year)

with cte as (select area,dayofweek(date) as day_num,aqi_value from aqi_data 
where area in ('Delhi', 'Mumbai', 'Chennai', 'Kolkata', 'Bengaluru', 'Hyderabad', 'Ahmedabad', 'Pune')
and curdate()-interval 1 year
group by area,day_num,aqi_value),
day_numbering as (select area, aqi_value, case when day_num in (1,7) then 'Weekend' else 'Weekday' end as day_type from cte )
select area,day_type, avg(aqi_value) as avg_aqi from day_numbering 
group by area,day_type
order by area,day_type

#Which months consistently show the worst air quality across Indian states
#(Consider top 10 states with high distinct areas)

with distinct_areas as (select state , count(distinct area) as distinct_area , avg(aqi_value)as avg_aqi from aqi_data 
group by state order by distinct_area desc limit 10),

month_rate as (select s.state ,s.distinct_area,avg(a.aqi_value) as aqi, month(a.date)as month_number , 
case month(a.date) when 1 then 'January' when 2 then 'February'
 when 3 then 'March' when 4 then 'April' when 5 then 'May' when 6 then 'June' when 7 then 'July' when 8 then 'August' when 9 then 
'September' when 10 then 'October' when 11 then 'November' when 12 then 'December' end as month_name
from distinct_areas s join aqi_data a on s.state=a.state where a.date>='2022-01-01'
group by s.state,s.distinct_area,month(a.date),month_name)

select month_name,round(avg(aqi),2) as high_aqi,
row_number() over(order by avg(aqi) desc) as rank_order from month_rate
group by month_name ;

#For the city of Bengaluru, how many days fell under each air quality category
# (e.g., Good, Moderate, Poor, etc.) between March and May 2025?

select  air_quality_status,
 avg(aqi_value)as avg_aqi ,count(* ) as day_count from aqi_data 
 where state = 'Karnataka' and area='Bengaluru' and date between '2025-03-01' and '2025-05-01' 
 group by air_quality_status ;
 
 
 #List the top two most reported disease illnesses in each state over the past three years,
 #along with the corresponding average Air Quality Index (AQI) for that period.
 
 with cte as ( select state, disease_illness_name,sum(cases) as total_cases from isdp where year >=2023 and year<=2024
 group by state,disease_illness_name),
aqi_rec as ( select state, avg(aqi_value) as avg_aqi from aqi_data where date>='2023-01-01' and date <='2024-12-31' group by state),
 
 record as (select cte.state,cte.disease_illness_name, cte.total_cases,aqi_rec.avg_aqi from cte 
 join aqi_rec on cte.state=aqi_rec.state order by cte.total_cases desc),
 
 rn_rank as (select *, rank() over(partition by state order by total_cases desc ) as rn from record)
 
 select state, disease_illness_name ,total_cases,avg_aqi from rn_rank where rn<=2 order by state asc
 
 
 
 #List the top 5 states with high EV adoption and analyse if their average AQI is
 # significantly better compared to states with lower EV adoption
 
 with adp as (select state , count(*) as total_ev,round(sum(case when fuel in ('ELECTRIC(BOV)','PURE EV','STRONG HYBRID EV','PLUG-IN HYBRID EV') 
 then value else 0 end)*100/nullif(sum(value),0),2) as ev_adoption
 from vahan  WHERE year >= 2022 group by state order by  total_ev desc),
 adp_class as (select *,
case  when ev_adoption>=9.0 then 'High ev Adoption' when ev_adoption<=2.0 then 'low ev adoption' else 'Medium ev adoption' end as adoption
from adp  order by ev_adoption desc),
aqi as (select state, avg(aqi_value)as avg_aqi from aqi_data where date>='2022-01-01' group by state)
select ad.adoption ,count(*) as total,  round(avg(a.avg_aqi),2) as total_avg from adp_class ad
 inner join aqi a on a.state=ad.state where adoption in ('High ev adoption','low ev adoption') 
 group by adoption 


#Which age group is most affected by air pollution-related health outcomes — and how does this vary by city?
 
with aqi_stat as (select state, area,avg(aqi_value) as avg_aqi from aqi_data 
where date>='2022-01-01'  group by state,area),

city_wise as (select id.state,id.district ,id.disease_illness_name,
case when disease_illness_name in ('Influenza A','Dengue','Cholera','Measles', 'Meningitis','Jaundice','Fever with Rash','ARI Influenza Like Illness(ILI)') then 'Children(<5)'
when disease_illness_name in ('Mumps','Food Poisoning','Chickenpox','Hepatitis A','Dengue','Scrub Typhus','Typhoid','Rubella','Gastroenteritis','Paratyphoid') then 'Young Adult(5-15)' 
when disease_illness_name in ('Hepatitis E','Leptospirosis','Chikungunya','Dengue','Jaundice','Mpox') then 'Adult(15-40)'
when disease_illness_name in ('Meningitis','Hepatitis','Dysentery','Acute Flaccid Paralysis','Chikungunya')
 then 'Elderly(40+)' when disease_illness_name in ('Hepatitis B and C','Pneumonia','ARI Influenza Like Illness(ILI)', 
  'Influenza','Influenza A','Diarrheal','Monkeypox', 'Leptospirosis','Dengue','Malaria','Typhoid','Jaundice' ,'Acute Diarrheal Disease') then 'Children(<5) & Elderly(40+)' else 'All ages' end as disease_age_group ,
sum(id.cases) as total_cases,sum(id.deaths) as total_deaths,a.avg_aqi
 from isdp id join aqi_stat a on id.state=a.state where year>='2022' and a.avg_aqi>150 
 group by id.disease_illness_name, disease_age_group,id.state,id.district,a.avg_aqi
 order by total_cases  desc)
select state,district,disease_illness_name,disease_age_group,total_cases,total_deaths,avg_aqi from city_wise where total_cases>=50
order by avg_aqi desc



#What is the relationship between a city’s population size and its average AQI 
#— do larger cities always suffer from worse air quality? (Consider 2024 population and AQI data for this)


select  area,case when area = 'Delhi' then '33.8 million' when area='Mumbai' then '21.7 million'
when area='Bengaluru' then '14.0 million' when area='Kolkata' then '15.6 million' when area= 'Hyderabad' then '11.1 million'
when area='Chennai' then '12.1 million' when area='Ahmedabad' then '8.9 million' when area =  'Pune' then '7.3 million' end as Population,
avg(aqi_value) as avg_aqi ,case when avg(aqi_value)>200 then 'Worst aqi' when avg(aqi_value)<100 then 'Good aqi' else 'Average aqi' end as Indication
from aqi_data 
where area in ('Delhi','Mumbai','Bengaluru','Kolkata','Chennai','Hyderabad','Ahmedabad','Pune')
 group by area order by avg_aqi desc

