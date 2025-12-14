
--SQL code from PGADMIN to create the tables, after updating them

-- =========================
-- 1) Employee
-- =========================
CREATE TABLE IF NOT EXISTS employee (
    employee_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(60),
    last_name     VARCHAR(60),
    role          VARCHAR(30),
    CONSTRAINT employee_role_check
        CHECK (role IN ('Baker', 'Prep', 'Manager', 'Packaging'))
);

-- =========================
-- 2) Ingredient
-- =========================
CREATE TABLE IF NOT EXISTS ingredient (
    ingredient_id     SERIAL PRIMARY KEY,
    name              VARCHAR(120) NOT NULL,
    unit              VARCHAR(20),
    allergen_flag     VARCHAR(3),
    cost_per_unit     NUMERIC(10,2),
    CONSTRAINT ingredient_unit_check
        CHECK (unit IN ('kg','g','L','mL','pcs')),
    CONSTRAINT ingredient_allergen_flag_check
        CHECK (allergen_flag IN ('YES','NO')),
    CONSTRAINT ingredient_cost_per_unit_check
        CHECK (cost_per_unit > 0)
);

-- =========================
-- 3) Product
-- =========================
CREATE TABLE IF NOT EXISTS product (
    product_id   SERIAL PRIMARY KEY,
    name         VARCHAR(120) NOT NULL,
    category     VARCHAR(30),
    price        NUMERIC(10,2),
    CONSTRAINT product_category_check
        CHECK (category IN ('Breads','Cakes','Savory')),
    CONSTRAINT product_price_check
        CHECK (price > 0)
);

-- =========================
-- 4) Station
-- =========================
CREATE TABLE IF NOT EXISTS station (
    station_id   SERIAL PRIMARY KEY,
    name         VARCHAR(120),
    type         VARCHAR(30),
    CONSTRAINT station_type_check
        CHECK (type IN ('Oven','Prep','Mixer','Packaging'))
);

-- =========================
-- 5) Shift
-- =========================
CREATE TABLE IF NOT EXISTS shift (
    shift_id     SERIAL PRIMARY KEY,
    shift_date   DATE,
    start_hour   NUMERIC(2,0),
    end_hour     NUMERIC(2,0),
    shift_type   VARCHAR(10),
    CONSTRAINT shift_start_hour_check
        CHECK (start_hour >= 0 AND start_hour <= 23),
    CONSTRAINT shift_end_hour_check
        CHECK (end_hour   >= 0 AND end_hour   <= 23),
    CONSTRAINT shift_shift_type_check
        CHECK (shift_type IN ('Morning','Evening','Night')),
    CONSTRAINT shift_shift_date_check
        CHECK (shift_date <= CURRENT_DATE)
);

-- =========================
-- 6) Recipe
-- =========================
CREATE TABLE IF NOT EXISTS recipe (
    recipe_id     SERIAL PRIMARY KEY,
    product_id    INTEGER,
    version_no    NUMERIC(6,2),
    created_date  DATE,
    notes         VARCHAR(200),
    yield_units   INTEGER,
    CONSTRAINT uq_recipe_product_version
        UNIQUE (product_id, version_no),
    CONSTRAINT recipe_product_id_fkey
        FOREIGN KEY (product_id)
        REFERENCES product (product_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT recipe_version_no_check
        CHECK (version_no > 0),
    CONSTRAINT recipe_created_date_check
        CHECK (created_date <= CURRENT_DATE),
    CONSTRAINT recipe_yield_units_check
        CHECK (yield_units > 0)
);

-- =========================
-- 7) Batch
-- =========================
CREATE TABLE IF NOT EXISTS batch (
    batch_id          SERIAL PRIMARY KEY,
    ingredient_id     INTEGER,
    received_date     DATE,
    expiry_date       DATE,
    quantity_current  NUMERIC(12,3),
    location          VARCHAR(60),
    CONSTRAINT batch_ingredient_id_fkey
        FOREIGN KEY (ingredient_id)
        REFERENCES ingredient (ingredient_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT batch_check
        CHECK (expiry_date >= received_date),
    CONSTRAINT batch_quantity_current_check
        CHECK (quantity_current >= 0),
    CONSTRAINT batch_received_date_check
        CHECK (received_date <= CURRENT_DATE)
);

-- =========================
-- 8) RecipeItem
-- =========================
CREATE TABLE IF NOT EXISTS recipeitem (
    recipe_id     INTEGER NOT NULL,
    ingredient_id INTEGER NOT NULL,
    quantity      NUMERIC(12,3),
    unit          VARCHAR(20),
    PRIMARY KEY (recipe_id, ingredient_id),
    CONSTRAINT recipeitem_recipe_id_fkey
        FOREIGN KEY (recipe_id)
        REFERENCES recipe (recipe_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT recipeitem_ingredient_id_fkey
        FOREIGN KEY (ingredient_id)
        REFERENCES ingredient (ingredient_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT recipeitem_quantity_check
        CHECK (quantity > 0),
    CONSTRAINT recipeitem_unit_check
        CHECK (unit IN ('kg','g','L','mL','pcs'))
);

-- =========================
-- 9) Production
-- =========================
CREATE TABLE IF NOT EXISTS production (
    production_id      SERIAL PRIMARY KEY,
    product_id         INTEGER,
    recipe_id          INTEGER,
    station_id         INTEGER,
    leader_employee_id INTEGER,
    bake_date          DATE,
    quantity_output    NUMERIC(12,3),
    shift_id           INTEGER,
    CONSTRAINT production_product_id_fkey
        FOREIGN KEY (product_id)
        REFERENCES product (product_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT production_recipe_id_fkey
        FOREIGN KEY (recipe_id)
        REFERENCES recipe (recipe_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT production_station_id_fkey
        FOREIGN KEY (station_id)
        REFERENCES station (station_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT production_leader_employee_id_fkey
        FOREIGN KEY (leader_employee_id)
        REFERENCES employee (employee_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_production_shift
        FOREIGN KEY (shift_id)
        REFERENCES shift (shift_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT production_bake_date_check
        CHECK (bake_date <= CURRENT_DATE),
    CONSTRAINT production_quantity_output_check
        CHECK (quantity_output >= 0)
);

-- =========================
-- 10) Assignment
-- =========================
CREATE TABLE IF NOT EXISTS assignment (
    assignment_id  SERIAL PRIMARY KEY,
    employee_id    INTEGER,
    shift_id       INTEGER,
    station_id     INTEGER,
    task_name      VARCHAR(30),
    CONSTRAINT uq_assignment_unique
        UNIQUE (employee_id, shift_id, station_id, task_name),
    CONSTRAINT assignment_employee_id_fkey
        FOREIGN KEY (employee_id)
        REFERENCES employee (employee_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT assignment_shift_id_fkey
        FOREIGN KEY (shift_id)
        REFERENCES shift (shift_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT assignment_station_id_fkey
        FOREIGN KEY (station_id)
        REFERENCES station (station_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT assignment_task_name_check
        CHECK (task_name IN ('Prep','Baking','Cleaning','Packaging','Mixing'))
);




