
--Creating consensus tables before changing them after writing queries

-- ==============================================
-- Kitchen Schema (simple version for ERD generator)
-- ==============================================

-- 1) Ingredient
CREATE TABLE Ingredient
(
  ingredient_id SERIAL,
  name VARCHAR(120) NOT NULL,
  unit VARCHAR(20) CHECK (unit IN ('kg','g','L','mL','pcs')),
  allergen_flag VARCHAR(3) CHECK (allergen_flag IN ('YES','NO')),
  PRIMARY KEY (ingredient_id)
);

ALTER TABLE Ingredient
ADD COLUMN cost_per_unit NUMERIC(10,2) CHECK (cost_per_unit > 0);


-- 2) Batch (Inventory lot of Ingredient)
CREATE TABLE Batch
(
  batch_id SERIAL,
  ingredient_id INT,
  received_date DATE CHECK (received_date <= CURRENT_DATE),
  expiry_date DATE CHECK (expiry_date >= received_date),
  quantity_current NUMERIC(12,3) CHECK (quantity_current >= 0),
  location VARCHAR(60),
  PRIMARY KEY (batch_id),
  FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id)
);

-- 3) Product
CREATE TABLE Product
(
  product_id SERIAL,
  name VARCHAR(120) NOT NULL,
  category VARCHAR(30) CHECK (category IN ('Breads','Cakes','Savory')),
  PRIMARY KEY (product_id)
);

-- 4) Recipe (versioned per product)
CREATE TABLE Recipe
(
  recipe_id SERIAL,
  product_id INT,
  version_no NUMERIC(6,2) CHECK (version_no > 0),
  created_date DATE CHECK (created_date <= CURRENT_DATE),
  notes VARCHAR(200),
  PRIMARY KEY (recipe_id),
  FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- 5) RecipeItem (junction: Recipe ↔ Ingredient)
CREATE TABLE RecipeItem
(
  recipe_id INT,
  ingredient_id INT,
  quantity NUMERIC(12,3) CHECK (quantity > 0),
  unit VARCHAR(20) CHECK (unit IN ('kg','g','L','mL','pcs')),
  PRIMARY KEY (recipe_id, ingredient_id),
  FOREIGN KEY (recipe_id) REFERENCES Recipe(recipe_id),
  FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id)
);

-- 6) Station
CREATE TABLE Station
(
  station_id SERIAL,
  name VARCHAR(120),
  type VARCHAR(30) CHECK (type IN ('Oven','Prep','Mixer','Packaging')),
  PRIMARY KEY (station_id)
);

-- 7) Employee
CREATE TABLE Employee
(
  employee_id SERIAL,
  first_name VARCHAR(60),
  last_name VARCHAR(60),
  role VARCHAR(30) CHECK (role IN ('Baker','Prep','Manager','Packaging')),
  PRIMARY KEY (employee_id)
);

-- 8) Shift
CREATE TABLE Shift
(
  shift_id SERIAL,
  shift_date DATE CHECK (shift_date <= CURRENT_DATE),
  start_hour NUMERIC(2,0) CHECK (start_hour BETWEEN 0 AND 23),
  end_hour NUMERIC(2,0) CHECK (end_hour BETWEEN 0 AND 23),
  PRIMARY KEY (shift_id)
);

-- 9) Assignment (Employee ↔ Shift ↔ Station)
CREATE TABLE Assignment
(
  assignment_id SERIAL,
  employee_id INT,
  shift_id INT,
  station_id INT,
  task_name VARCHAR(30) CHECK (task_name IN ('Prep','Baking','Cleaning','Packaging','Mixing')),
  PRIMARY KEY (assignment_id),
  FOREIGN KEY (employee_id) REFERENCES Employee(employee_id),
  FOREIGN KEY (shift_id) REFERENCES Shift(shift_id),
  FOREIGN KEY (station_id) REFERENCES Station(station_id)
);

-- 10) Production (actual production run)
CREATE TABLE Production
(
  production_id SERIAL,
  product_id INT,
  recipe_id INT,
  station_id INT,
  leader_employee_id INT,
  bake_date DATE CHECK (bake_date <= CURRENT_DATE),
  quantity_output NUMERIC(12,3) CHECK (quantity_output >= 0),
  PRIMARY KEY (production_id),
  FOREIGN KEY (product_id) REFERENCES Product(product_id),
  FOREIGN KEY (recipe_id) REFERENCES Recipe(recipe_id),
  FOREIGN KEY (station_id) REFERENCES Station(station_id),
  FOREIGN KEY (leader_employee_id) REFERENCES Employee(employee_id)
);

ALTER TABLE Production
ADD COLUMN shift_id INT;


ALTER TABLE Recipe
ADD CONSTRAINT uq_recipe_product_version UNIQUE (product_id, version_no);

ALTER TABLE Assignment
ADD CONSTRAINT uq_assignment_unique
UNIQUE (employee_id, shift_id, station_id, task_name);




