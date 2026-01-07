--complex level queries


-- 1) Returns the list of employees involved in producing above-average quantities
SELECT DISTINCT e.first_name,e.last_name,e.role
FROM (SELECT *
             FROM production p
             where p.quantity_output>(SELECT avg(quantity_output)
                                                      FROM Production) ) Tproduction
JOIN Assignment a
ON a.shift_id=Tproduction.shift_id AND a.station_id=Tproduction.station_id
JOIN Employee e
ON e.employee_id=a.employee_id

--Post-integration optimized query
--1)
WITH above_prod AS (
  SELECT shift_id, station_id
  FROM public.production
  WHERE quantity_output > (SELECT AVG(quantity_output) FROM public.production)
)
SELECT DISTINCT e.first_name, e.last_name, e.role
FROM above_prod p
JOIN public.assignment a
  ON a.shift_id = p.shift_id
 AND a.station_id = p.station_id
JOIN public.employees e
  ON e.employee_id = a.employee_id;


-- 2) Inventory usage report
SELECT 
    IU.ingredient_id,
    IU.ingredient_name,
    IU.used_amount,
    ISK.total_quantity,
    (ISK.total_quantity - IU.used_amount) AS remaining_quantity
FROM (
    -- שימוש אמיתי בחומרי גלם לפי כל ההפקות
    SELECT 
        ri.ingredient_id,
        i.name AS ingredient_name,
        SUM(ri.quantity * p.quantity_output) AS used_amount
    FROM Production p
    JOIN RecipeItem ri
      ON p.recipe_id = ri.recipe_id
    JOIN Ingredient i
      ON ri.ingredient_id = i.ingredient_id
    GROUP BY ri.ingredient_id, i.name
) AS IU
LEFT JOIN (
    -- כמה יש במלאי מתוך באצ'ים
    SELECT 
        ingredient_id,
        SUM(quantity_current) AS total_quantity
    FROM Batch
    GROUP BY ingredient_id
) AS ISK
  ON IU.ingredient_id = ISK.ingredient_id
ORDER BY IU.used_amount DESC;


-- 3) Station revenue report
SELECT 
    s.station_id,s.name AS station_name,
    COALESCE(SUM(pr.quantity_output * p.price), 0) AS total_revenue
FROM Station s
LEFT JOIN Production pr
  ON pr.station_id = s.station_id
LEFT JOIN Product p
  ON pr.product_id = p.product_id
GROUP BY s.station_id, s.name
ORDER BY total_revenue DESC;


--4)profit report per product
SELECT 
    p.product_id,
    p.name AS product_name,
    p.price AS sell_price,
    SUM(ri.quantity * i.cost_per_unit) / r.yield_units AS cost_per_unit,
    (p.price - SUM(ri.quantity * i.cost_per_unit) / r.yield_units) AS profit_per_unit,
    ROUND(((p.price - SUM(ri.quantity * i.cost_per_unit) / r.yield_units) / p.price) * 100,2)
    AS profit_margin_percent

FROM Product p
JOIN Recipe r 
    ON r.product_id = p.product_id
JOIN RecipeItem ri 
    ON ri.recipe_id = r.recipe_id
JOIN Ingredient i
    ON i.ingredient_id = ri.ingredient_id

GROUP BY p.product_id, p.name, p.price
ORDER BY profit_per_unit DESC;


--Post-integration optimized query
--4)
SELECT 
    p.product_id,
    p.name AS product_name,
    p.price AS sell_price,
    ROUND(SUM(ri.quantity * i.cost_per_unit) / r.yield_units,2) AS cost_per_unit,
    ROUND(p.price - SUM(ri.quantity * i.cost_per_unit) / r.yield_units,2) AS profit_per_unit,
    ROUND(((p.price - SUM(ri.quantity * i.cost_per_unit) / r.yield_units) / p.price) * 100, 2)
      AS profit_margin_percent
FROM public.product p
JOIN public.recipe r 
  ON r.product_id = p.product_id
JOIN public.recipeitem ri 
  ON ri.recipe_id = r.recipe_id
JOIN public.ingredient i
  ON i.ingredient_id = ri.ingredient_id
GROUP BY p.product_id, p.name, p.price, r.yield_units
ORDER BY profit_per_unit DESC;



--5) Products that can be made from ingredients nearing expiration in the next 30 days

CREATE VIEW lastVersionRecipeProduct AS
SELECT DISTINCT ON (product_id)
	product_id, recipe_id, version_no,yield_units
FROM Recipe
ORDER BY product_id,version_no DESC;

SELECT p.product_id as product_id,
       p.name as product_name,
	   ing.name as integredient_name,
	   MIN(b.expiry_date) AS earliest_expiry,
	   MIN(b.expiry_date) - CURRENT_DATE AS soonest_expiration_days,
	   FLOOR(SUM(ROUND(b.quantity_current / ri.quantity)*r.yield_units)) AS estimated_product_units_to_save
FROM Batch b
JOIN Ingredient ing
ON b.ingredient_id=ing.ingredient_id
JOIN RecipeItem ri
ON ri.ingredient_id=ing.ingredient_id
JOIN lastVersionRecipeProduct r
ON r.recipe_id=ri.recipe_id
JOIN Product p
ON r.product_id=p.product_id
WHERE b.expiry_date<=CURRENT_DATE+30 and b.expiry_date>CURRENT_DATE and b.quantity_current>0
GROUP BY p.product_id,p.name,ing.name
ORDER BY
    soonest_expiration_days ASC,
    estimated_product_units_to_save DESC;



-- Intermediate level queries

-- 1) Top 10 busy stations
SELECT  
    s.station_id,
    s.name,
    SUM(p.quantity_output) AS total_amount_produced
FROM Station s
JOIN Production p
  ON s.station_id = p.station_id
GROUP BY s.station_id, s.name
ORDER BY total_amount_produced DESC
Limit 10;


--2)The average hourly output for each station id in each shift id
SELECT 
    st.station_id,
    s.shift_id,
    SUM(p.quantity_output) 
      / ABS(s.end_hour - s.start_hour) AS avg_output_per_hour
FROM public.production p
JOIN public.shift s
  ON p.shift_id = s.shift_id
JOIN public.station st
  ON p.station_id = st.station_id
GROUP BY 
    st.station_id,
    s.shift_id,
    s.start_hour,
    s.end_hour
ORDER BY st.station_id, s.shift_id;



-- 3) The total amount of output produced at each station,
-- broken down by the role of the worker who led the production batch.
SELECT
    s.name AS station_name,
    e.role AS leader_role,
    ROUND(SUM(p.quantity_output)) AS total_output_units
FROM 
    production p
JOIN 
    station s ON p.station_id = s.station_id
JOIN 
    employee e ON p.leader_employee_id = e.employee_id
GROUP BY
    s.name,
    e.role
ORDER BY
    s.name,
    total_output_units DESC;




             
