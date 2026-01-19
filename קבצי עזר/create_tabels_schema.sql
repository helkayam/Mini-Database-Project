--
-- PostgreSQL database dump
--

-- Dumped from database version 17.7 (Debian 17.7-3.pgdg13+1)
-- Dumped by pg_dump version 17.4

-- Started on 2026-01-08 18:18:34

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 3611 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 233 (class 1259 OID 16479)
-- Name: assignment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assignment (
    assignment_id integer NOT NULL,
    shift_id integer,
    station_id integer,
    task_name character varying(30),
    employee_id integer,
    CONSTRAINT assignment_task_name_check CHECK (((task_name)::text = ANY ((ARRAY['Prep'::character varying, 'Baking'::character varying, 'Cleaning'::character varying, 'Packaging'::character varying, 'Mixing'::character varying])::text[])))
);


ALTER TABLE public.assignment OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16478)
-- Name: assignment_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assignment_assignment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.assignment_assignment_id_seq OWNER TO postgres;

--
-- TOC entry 3612 (class 0 OID 0)
-- Dependencies: 232
-- Name: assignment_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assignment_assignment_id_seq OWNED BY public.assignment.assignment_id;


--
-- TOC entry 246 (class 1259 OID 24620)
-- Name: attendance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendance (
    attendance_id integer NOT NULL,
    work_date date,
    check_in time without time zone,
    check_out time without time zone,
    hours_worked numeric(4,2),
    employee_id integer
);


ALTER TABLE public.attendance OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 24619)
-- Name: attendance_attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.attendance ALTER COLUMN attendance_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.attendance_attendance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 220 (class 1259 OID 16399)
-- Name: batch; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.batch (
    batch_id integer NOT NULL,
    ingredient_id integer,
    received_date date,
    expiry_date date,
    quantity_current numeric(12,3),
    location character varying(60),
    CONSTRAINT batch_check CHECK ((expiry_date >= received_date)),
    CONSTRAINT batch_quantity_current_check CHECK ((quantity_current >= (0)::numeric)),
    CONSTRAINT batch_received_date_check CHECK ((received_date <= CURRENT_DATE))
);


ALTER TABLE public.batch OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16398)
-- Name: batch_batch_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.batch_batch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.batch_batch_id_seq OWNER TO postgres;

--
-- TOC entry 3613 (class 0 OID 0)
-- Dependencies: 219
-- Name: batch_batch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.batch_batch_id_seq OWNED BY public.batch.batch_id;


--
-- TOC entry 238 (class 1259 OID 24578)
-- Name: departments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departments (
    department_id integer NOT NULL,
    department_name character varying(50),
    manager_id integer
);


ALTER TABLE public.departments OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 24577)
-- Name: departments_department_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.departments ALTER COLUMN department_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.departments_department_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 229 (class 1259 OID 16461)
-- Name: employee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employee (
    employee_id integer NOT NULL,
    first_name character varying(60),
    last_name character varying(60),
    role character varying(30),
    CONSTRAINT employee_role_check CHECK (((role)::text = ANY ((ARRAY['Baker'::character varying, 'Prep'::character varying, 'Manager'::character varying, 'Packaging'::character varying])::text[])))
);


ALTER TABLE public.employee OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16460)
-- Name: employee_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employee_employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_employee_id_seq OWNER TO postgres;

--
-- TOC entry 3614 (class 0 OID 0)
-- Dependencies: 228
-- Name: employee_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employee_employee_id_seq OWNED BY public.employee.employee_id;


--
-- TOC entry 252 (class 1259 OID 24708)
-- Name: employee_map; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employee_map (
    old_employee_id integer NOT NULL,
    new_employee_id integer NOT NULL
);


ALTER TABLE public.employee_map OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 24647)
-- Name: employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employees (
    employee_id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    role character varying(20),
    id_number character varying(20),
    birth_date date,
    gender character varying(10),
    phone character varying(15),
    email character varying(100),
    address character varying(100),
    hire_date date,
    job_id integer,
    department_id integer,
    status character varying(20)
);


ALTER TABLE public.employees OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 24646)
-- Name: employees_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.employees ALTER COLUMN employee_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.employees_employee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 242 (class 1259 OID 24592)
-- Name: employees_hr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employees_hr (
    employee_id integer NOT NULL,
    first_name character varying(50),
    last_name character varying(50),
    id_number character varying(20),
    birth_date date,
    gender character varying(10),
    phone character varying(15),
    email character varying(100),
    address character varying(100),
    hire_date date,
    job_id integer,
    department_id integer,
    status character varying(20)
);


ALTER TABLE public.employees_hr OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 24591)
-- Name: employees_hr_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.employees_hr ALTER COLUMN employee_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.employees_hr_employee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 251 (class 1259 OID 24681)
-- Name: hr_employee_map; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hr_employee_map (
    old_employee_id integer NOT NULL,
    new_employee_id integer NOT NULL
);


ALTER TABLE public.hr_employee_map OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16390)
-- Name: ingredient; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ingredient (
    ingredient_id integer NOT NULL,
    name character varying(120) NOT NULL,
    unit character varying(20),
    allergen_flag character varying(3),
    cost_per_unit numeric(10,2),
    CONSTRAINT ingredient_allergen_flag_check CHECK (((allergen_flag)::text = ANY ((ARRAY['YES'::character varying, 'NO'::character varying])::text[]))),
    CONSTRAINT ingredient_cost_per_unit_check CHECK ((cost_per_unit > (0)::numeric)),
    CONSTRAINT ingredient_unit_check CHECK (((unit)::text = ANY ((ARRAY['kg'::character varying, 'g'::character varying, 'L'::character varying, 'mL'::character varying, 'pcs'::character varying])::text[])))
);


ALTER TABLE public.ingredient OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16389)
-- Name: ingredient_ingredient_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ingredient_ingredient_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ingredient_ingredient_id_seq OWNER TO postgres;

--
-- TOC entry 3615 (class 0 OID 0)
-- Dependencies: 217
-- Name: ingredient_ingredient_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ingredient_ingredient_id_seq OWNED BY public.ingredient.ingredient_id;


--
-- TOC entry 240 (class 1259 OID 24584)
-- Name: jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jobs (
    job_id integer NOT NULL,
    job_title character varying(50),
    base_salary numeric(10,2),
    description text
);


ALTER TABLE public.jobs OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 24583)
-- Name: jobs_job_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.jobs ALTER COLUMN job_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.jobs_job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 224 (class 1259 OID 16422)
-- Name: recipe; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recipe (
    recipe_id integer NOT NULL,
    product_id integer,
    version_no numeric(6,2),
    created_date date,
    notes character varying(200),
    yield_units integer,
    CONSTRAINT recipe_created_date_check CHECK ((created_date <= CURRENT_DATE)),
    CONSTRAINT recipe_version_no_check CHECK ((version_no > (0)::numeric)),
    CONSTRAINT recipe_yield_units_check CHECK ((yield_units > 0))
);


ALTER TABLE public.recipe OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16568)
-- Name: lastversionrecipeproduct; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.lastversionrecipeproduct AS
 SELECT DISTINCT ON (product_id) product_id,
    recipe_id,
    version_no,
    yield_units
   FROM public.recipe
  ORDER BY product_id, version_no DESC;


ALTER VIEW public.lastversionrecipeproduct OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 24631)
-- Name: leaves; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.leaves (
    leave_id integer NOT NULL,
    start_date date,
    end_date date,
    leave_type character varying(50),
    status character varying(20),
    employee_id integer
);


ALTER TABLE public.leaves OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 24630)
-- Name: leaves_leave_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.leaves ALTER COLUMN leave_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.leaves_leave_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 222 (class 1259 OID 16414)
-- Name: product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product (
    product_id integer NOT NULL,
    name character varying(120) NOT NULL,
    category character varying(30),
    price numeric(10,2),
    CONSTRAINT product_category_check CHECK (((category)::text = ANY ((ARRAY['Breads'::character varying, 'Cakes'::character varying, 'Savory'::character varying])::text[]))),
    CONSTRAINT product_price_check CHECK ((price > (0)::numeric))
);


ALTER TABLE public.product OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16413)
-- Name: product_product_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_product_id_seq OWNER TO postgres;

--
-- TOC entry 3616 (class 0 OID 0)
-- Dependencies: 221
-- Name: product_product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_product_id_seq OWNED BY public.product.product_id;


--
-- TOC entry 235 (class 1259 OID 16502)
-- Name: production; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.production (
    production_id integer NOT NULL,
    product_id integer,
    recipe_id integer,
    station_id integer,
    bake_date date,
    quantity_output numeric(12,3),
    shift_id integer,
    leader_employee_id integer,
    CONSTRAINT production_bake_date_check CHECK ((bake_date <= CURRENT_DATE)),
    CONSTRAINT production_quantity_output_check CHECK ((quantity_output >= (0)::numeric))
);


ALTER TABLE public.production OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16501)
-- Name: production_production_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.production_production_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.production_production_id_seq OWNER TO postgres;

--
-- TOC entry 3617 (class 0 OID 0)
-- Dependencies: 234
-- Name: production_production_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.production_production_id_seq OWNED BY public.production.production_id;


--
-- TOC entry 223 (class 1259 OID 16421)
-- Name: recipe_recipe_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.recipe_recipe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.recipe_recipe_id_seq OWNER TO postgres;

--
-- TOC entry 3618 (class 0 OID 0)
-- Dependencies: 223
-- Name: recipe_recipe_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.recipe_recipe_id_seq OWNED BY public.recipe.recipe_id;


--
-- TOC entry 225 (class 1259 OID 16435)
-- Name: recipeitem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recipeitem (
    recipe_id integer NOT NULL,
    ingredient_id integer NOT NULL,
    quantity numeric(12,3),
    unit character varying(20),
    CONSTRAINT recipeitem_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT recipeitem_unit_check CHECK (((unit)::text = ANY ((ARRAY['kg'::character varying, 'g'::character varying, 'L'::character varying, 'mL'::character varying, 'pcs'::character varying])::text[])))
);


ALTER TABLE public.recipeitem OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 24608)
-- Name: salaries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.salaries (
    salary_id integer NOT NULL,
    base_salary numeric(10,2),
    bonus numeric(10,2) DEFAULT 0.00,
    pay_date date,
    total_salary numeric(10,2),
    employee_id integer
);


ALTER TABLE public.salaries OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 24607)
-- Name: salaries_salary_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.salaries ALTER COLUMN salary_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.salaries_salary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 231 (class 1259 OID 16469)
-- Name: shift; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shift (
    shift_id integer NOT NULL,
    shift_date date,
    start_hour numeric(2,0),
    end_hour numeric(2,0),
    shift_type character varying(10),
    CONSTRAINT shift_end_hour_check CHECK (((end_hour >= (0)::numeric) AND (end_hour <= (23)::numeric))),
    CONSTRAINT shift_shift_date_check CHECK ((shift_date <= CURRENT_DATE)),
    CONSTRAINT shift_shift_type_check CHECK (((shift_type)::text = ANY ((ARRAY['Morning'::character varying, 'Evening'::character varying, 'Night'::character varying])::text[]))),
    CONSTRAINT shift_start_hour_check CHECK (((start_hour >= (0)::numeric) AND (start_hour <= (23)::numeric)))
);


ALTER TABLE public.shift OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16468)
-- Name: shift_shift_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shift_shift_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.shift_shift_id_seq OWNER TO postgres;

--
-- TOC entry 3619 (class 0 OID 0)
-- Dependencies: 230
-- Name: shift_shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shift_shift_id_seq OWNED BY public.shift.shift_id;


--
-- TOC entry 227 (class 1259 OID 16453)
-- Name: station; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.station (
    station_id integer NOT NULL,
    name character varying(120),
    type character varying(30),
    CONSTRAINT station_type_check CHECK (((type)::text = ANY ((ARRAY['Oven'::character varying, 'Prep'::character varying, 'Mixer'::character varying, 'Packaging'::character varying])::text[])))
);


ALTER TABLE public.station OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16452)
-- Name: station_station_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.station_station_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.station_station_id_seq OWNER TO postgres;

--
-- TOC entry 3620 (class 0 OID 0)
-- Dependencies: 226
-- Name: station_station_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.station_station_id_seq OWNED BY public.station.station_id;


--
-- TOC entry 3372 (class 2604 OID 16482)
-- Name: assignment assignment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment ALTER COLUMN assignment_id SET DEFAULT nextval('public.assignment_assignment_id_seq'::regclass);


--
-- TOC entry 3366 (class 2604 OID 16402)
-- Name: batch batch_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.batch ALTER COLUMN batch_id SET DEFAULT nextval('public.batch_batch_id_seq'::regclass);


--
-- TOC entry 3370 (class 2604 OID 16464)
-- Name: employee employee_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee ALTER COLUMN employee_id SET DEFAULT nextval('public.employee_employee_id_seq'::regclass);


--
-- TOC entry 3365 (class 2604 OID 16393)
-- Name: ingredient ingredient_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ingredient ALTER COLUMN ingredient_id SET DEFAULT nextval('public.ingredient_ingredient_id_seq'::regclass);


--
-- TOC entry 3367 (class 2604 OID 16417)
-- Name: product product_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product ALTER COLUMN product_id SET DEFAULT nextval('public.product_product_id_seq'::regclass);


--
-- TOC entry 3373 (class 2604 OID 16505)
-- Name: production production_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production ALTER COLUMN production_id SET DEFAULT nextval('public.production_production_id_seq'::regclass);


--
-- TOC entry 3368 (class 2604 OID 16425)
-- Name: recipe recipe_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recipe ALTER COLUMN recipe_id SET DEFAULT nextval('public.recipe_recipe_id_seq'::regclass);


--
-- TOC entry 3371 (class 2604 OID 16472)
-- Name: shift shift_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shift ALTER COLUMN shift_id SET DEFAULT nextval('public.shift_shift_id_seq'::regclass);


--
-- TOC entry 3369 (class 2604 OID 16456)
-- Name: station station_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.station ALTER COLUMN station_id SET DEFAULT nextval('public.station_station_id_seq'::regclass);


--
-- TOC entry 3416 (class 2606 OID 16485)
-- Name: assignment assignment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_pkey PRIMARY KEY (assignment_id);


--
-- TOC entry 3428 (class 2606 OID 24624)
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (attendance_id);


--
-- TOC entry 3400 (class 2606 OID 16407)
-- Name: batch batch_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.batch
    ADD CONSTRAINT batch_pkey PRIMARY KEY (batch_id);


--
-- TOC entry 3420 (class 2606 OID 24582)
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);


--
-- TOC entry 3438 (class 2606 OID 24712)
-- Name: employee_map employee_map_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee_map
    ADD CONSTRAINT employee_map_pkey PRIMARY KEY (old_employee_id);


--
-- TOC entry 3412 (class 2606 OID 16467)
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (employee_id);


--
-- TOC entry 3424 (class 2606 OID 24596)
-- Name: employees_hr employees_hr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees_hr
    ADD CONSTRAINT employees_hr_pkey PRIMARY KEY (employee_id);


--
-- TOC entry 3432 (class 2606 OID 24651)
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (employee_id);


--
-- TOC entry 3434 (class 2606 OID 24687)
-- Name: hr_employee_map hr_employee_map_new_employee_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hr_employee_map
    ADD CONSTRAINT hr_employee_map_new_employee_id_key UNIQUE (new_employee_id);


--
-- TOC entry 3436 (class 2606 OID 24685)
-- Name: hr_employee_map hr_employee_map_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hr_employee_map
    ADD CONSTRAINT hr_employee_map_pkey PRIMARY KEY (old_employee_id);


--
-- TOC entry 3398 (class 2606 OID 16397)
-- Name: ingredient ingredient_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ingredient
    ADD CONSTRAINT ingredient_pkey PRIMARY KEY (ingredient_id);


--
-- TOC entry 3422 (class 2606 OID 24590)
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (job_id);


--
-- TOC entry 3430 (class 2606 OID 24635)
-- Name: leaves leaves_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leaves
    ADD CONSTRAINT leaves_pkey PRIMARY KEY (leave_id);


--
-- TOC entry 3402 (class 2606 OID 16420)
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (product_id);


--
-- TOC entry 3418 (class 2606 OID 16509)
-- Name: production production_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production
    ADD CONSTRAINT production_pkey PRIMARY KEY (production_id);


--
-- TOC entry 3404 (class 2606 OID 16429)
-- Name: recipe recipe_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recipe
    ADD CONSTRAINT recipe_pkey PRIMARY KEY (recipe_id);


--
-- TOC entry 3408 (class 2606 OID 16441)
-- Name: recipeitem recipeitem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recipeitem
    ADD CONSTRAINT recipeitem_pkey PRIMARY KEY (recipe_id, ingredient_id);


--
-- TOC entry 3426 (class 2606 OID 24613)
-- Name: salaries salaries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salaries
    ADD CONSTRAINT salaries_pkey PRIMARY KEY (salary_id);


--
-- TOC entry 3414 (class 2606 OID 16477)
-- Name: shift shift_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shift
    ADD CONSTRAINT shift_pkey PRIMARY KEY (shift_id);


--
-- TOC entry 3410 (class 2606 OID 16459)
-- Name: station station_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.station
    ADD CONSTRAINT station_pkey PRIMARY KEY (station_id);


--
-- TOC entry 3406 (class 2606 OID 16531)
-- Name: recipe uq_recipe_product_version; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recipe
    ADD CONSTRAINT uq_recipe_product_version UNIQUE (product_id, version_no);


--
-- TOC entry 3443 (class 2606 OID 24733)
-- Name: assignment assignment_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id);


--
-- TOC entry 3444 (class 2606 OID 16491)
-- Name: assignment assignment_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.shift(shift_id);


--
-- TOC entry 3445 (class 2606 OID 16496)
-- Name: assignment assignment_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignment
    ADD CONSTRAINT assignment_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.station(station_id);


--
-- TOC entry 3439 (class 2606 OID 16408)
-- Name: batch batch_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.batch
    ADD CONSTRAINT batch_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(ingredient_id);


--
-- TOC entry 3459 (class 2606 OID 24713)
-- Name: employee_map employee_map_new_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee_map
    ADD CONSTRAINT employee_map_new_employee_id_fkey FOREIGN KEY (new_employee_id) REFERENCES public.employees(employee_id);


--
-- TOC entry 3455 (class 2606 OID 24778)
-- Name: attendance fk_att_emp; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT fk_att_emp FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id);


--
-- TOC entry 3451 (class 2606 OID 24798)
-- Name: departments fk_department_manager; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT fk_department_manager FOREIGN KEY (manager_id) REFERENCES public.employees(employee_id);


--
-- TOC entry 3452 (class 2606 OID 24602)
-- Name: employees_hr fk_emp_dept; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees_hr
    ADD CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- TOC entry 3457 (class 2606 OID 24657)
-- Name: employees fk_emp_dept; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- TOC entry 3453 (class 2606 OID 24597)
-- Name: employees_hr fk_emp_job; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees_hr
    ADD CONSTRAINT fk_emp_job FOREIGN KEY (job_id) REFERENCES public.jobs(job_id);


--
-- TOC entry 3458 (class 2606 OID 24652)
-- Name: employees fk_emp_job; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_emp_job FOREIGN KEY (job_id) REFERENCES public.jobs(job_id);


--
-- TOC entry 3456 (class 2606 OID 24788)
-- Name: leaves fk_leave_emp; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leaves
    ADD CONSTRAINT fk_leave_emp FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id);


--
-- TOC entry 3446 (class 2606 OID 16536)
-- Name: production fk_production_shift; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production
    ADD CONSTRAINT fk_production_shift FOREIGN KEY (shift_id) REFERENCES public.shift(shift_id);


--
-- TOC entry 3454 (class 2606 OID 24808)
-- Name: salaries fk_sal_emp; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salaries
    ADD CONSTRAINT fk_sal_emp FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id);


--
-- TOC entry 3447 (class 2606 OID 24743)
-- Name: production production_leader_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production
    ADD CONSTRAINT production_leader_employee_id_fkey FOREIGN KEY (leader_employee_id) REFERENCES public.employees(employee_id);


--
-- TOC entry 3448 (class 2606 OID 16510)
-- Name: production production_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production
    ADD CONSTRAINT production_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id);


--
-- TOC entry 3449 (class 2606 OID 16515)
-- Name: production production_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production
    ADD CONSTRAINT production_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(recipe_id);


--
-- TOC entry 3450 (class 2606 OID 16520)
-- Name: production production_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.production
    ADD CONSTRAINT production_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.station(station_id);


--
-- TOC entry 3440 (class 2606 OID 16430)
-- Name: recipe recipe_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recipe
    ADD CONSTRAINT recipe_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id);


--
-- TOC entry 3441 (class 2606 OID 16447)
-- Name: recipeitem recipeitem_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recipeitem
    ADD CONSTRAINT recipeitem_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(ingredient_id);


--
-- TOC entry 3442 (class 2606 OID 16442)
-- Name: recipeitem recipeitem_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recipeitem
    ADD CONSTRAINT recipeitem_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(recipe_id);


-- Completed on 2026-01-08 18:18:55

--
-- PostgreSQL database dump complete
--

