--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3 (Debian 15.3-1.pgdg120+1)
-- Dumped by pg_dump version 15.3 (Debian 15.3-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;
set timezone TO 'EST';

--
-- Name: interval_to_seconds(interval); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.interval_to_seconds(interval) RETURNS double precision
    LANGUAGE sql
    AS $_$
SELECT (extract(days from $1) * 86400)
        + (extract(hours from $1) * 3600)
        + (extract(minutes from $1) * 60)
        + extract(seconds from $1);
$_$;


ALTER FUNCTION public.interval_to_seconds(interval) OWNER TO postgres;

--
-- Name: ts_round(timestamp with time zone, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ts_round(timestamp with time zone, integer) RETURNS timestamp with time zone
    LANGUAGE sql
    AS $_$
SELECT 'epoch'::timestamptz + '1 second'::INTERVAL * ( $2 * ( extract( epoch FROM $1 )::INT4 / $2 ) );
$_$;


ALTER FUNCTION public.ts_round(timestamp with time zone, integer) OWNER TO postgres;

--
-- Name: weighted_stddev_combiner(numeric[], numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.weighted_stddev_combiner(state numeric[], numeric, numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
BEGIN
        RETURN sqrt((state[3]-(state[2]^2)/state[1])/(state[1]-1));
END;
$$;


ALTER FUNCTION public.weighted_stddev_combiner(state numeric[], numeric, numeric) OWNER TO postgres;

--
-- Name: weighted_stddev_state(numeric[], numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.weighted_stddev_state(state numeric[], val numeric, weight numeric) RETURNS numeric[]
    LANGUAGE plpgsql
    AS $$
BEGIN
        IF weight IS NULL OR val IS NULL
        THEN RETURN state;
        ELSE RETURN ARRAY[state[1]+weight, state[2]+val*weight, state[3]+val^2*weight];
        END IF;
END;
$$;


ALTER FUNCTION public.weighted_stddev_state(state numeric[], val numeric, weight numeric) OWNER TO postgres;

--
-- Name: weighted_stddev(numeric, numeric); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE public.weighted_stddev(var numeric, weight numeric) (
    SFUNC = public.weighted_stddev_state,
    STYPE = numeric[],
    INITCOND = '{0,0,0}',
    FINALFUNC = public.weighted_stddev_combiner,
    FINALFUNC_EXTRA
);


ALTER AGGREGATE public.weighted_stddev(var numeric, weight numeric) OWNER TO postgres;

--
-- Name: AGGREGATE weighted_stddev(var numeric, weight numeric); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON AGGREGATE public.weighted_stddev(var numeric, weight numeric) IS 'Usage: select weighted_stddev(var::numeric, weight::numeric) from X;';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: api_request; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_request (
    id bigint NOT NULL,
    api_key character varying(255) NOT NULL,
    date timestamp without time zone NOT NULL,
    endpoint character varying(255),
    originating_ip_address character varying(255),
    params jsonb
);


ALTER TABLE public.api_request OWNER TO postgres;

--
-- Name: api_request_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.api_request_id_seq OWNER TO postgres;

--
-- Name: api_request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_request_id_seq OWNED BY public.api_request.id;


--
-- Name: api_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_user (
    api_key character varying(255) NOT NULL,
    activation_date timestamp without time zone,
    email_address character varying(255),
    is_blocked boolean NOT NULL,
    max_calls_per_day integer,
    max_calls_per_second integer,
    name character varying(255)
);


ALTER TABLE public.api_user OWNER TO postgres;

--
-- Name: daily_service_report; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.daily_service_report (
    date timestamp without time zone NOT NULL,
    num_customers_refunded integer,
    percent_customers_on_time double precision,
    percent_customers_refunded double precision,
    percent_customers_within_five_minutes_expected_time double precision
);


ALTER TABLE public.daily_service_report OWNER TO postgres;

--
-- Name: destination_code_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.destination_code_mapping (
    destination_code character varying(255) NOT NULL,
    direction_number integer NOT NULL,
    destination_station_code character varying(255),
    line_code character varying(255)
);


ALTER TABLE public.destination_code_mapping OWNER TO postgres;

--
-- Name: direction_metrics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.direction_metrics (
    id bigint NOT NULL,
    average_headway_adherence double precision,
    average_minimum_headways double precision,
    average_on_time_performance double precision,
    average_platform_wait_time double precision,
    average_schedule_adherence double precision,
    average_train_delay integer,
    average_train_frequency double precision,
    expected_num_trains integer,
    expected_platform_wait_time double precision,
    expected_standard_deviation_train_frequency double precision,
    expected_train_frequency double precision,
    maximum_train_delay integer,
    median_train_delay integer,
    minimum_train_delay integer,
    num_cars integer NOT NULL,
    num_delayed_trains integer,
    num_eight_car_trains integer NOT NULL,
    num_trains integer NOT NULL,
    platform_wait_time_trend_status integer,
    should_exclude_from_reports boolean,
    standard_deviation_train_frequency double precision,
    train_frequency_status integer,
    date timestamp without time zone NOT NULL,
    direction character varying(255),
    direction_number integer NOT NULL,
    line_code character varying(255) NOT NULL,
    towards_station_name character varying(255)
);


ALTER TABLE public.direction_metrics OWNER TO postgres;

--
-- Name: duplicate_train_event; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.duplicate_train_event (
    id bigint NOT NULL,
    date timestamp without time zone NOT NULL,
    destination_station_code character varying(255),
    kept_train_direction_number integer,
    kept_train_id character varying(255),
    line_code character varying(255),
    real_train_id character varying(255),
    removed_train_direction_number integer,
    removed_train_id character varying(255),
    station_code character varying(255)
);


ALTER TABLE public.duplicate_train_event OWNER TO postgres;

--
-- Name: duplicate_train_event_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.duplicate_train_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.duplicate_train_event_id_seq OWNER TO postgres;

--
-- Name: duplicate_train_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.duplicate_train_event_id_seq OWNED BY public.duplicate_train_event.id;


--
-- Name: hibernate_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.hibernate_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hibernate_sequence OWNER TO postgres;

--
-- Name: line_metrics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.line_metrics (
    id bigint NOT NULL,
    average_headway_adherence double precision,
    average_minimum_headways double precision,
    average_on_time_performance double precision,
    average_platform_wait_time double precision,
    average_schedule_adherence double precision,
    average_train_delay integer,
    average_train_frequency double precision,
    expected_num_trains integer,
    expected_platform_wait_time double precision,
    expected_standard_deviation_train_frequency double precision,
    expected_train_frequency double precision,
    maximum_train_delay integer,
    median_train_delay integer,
    minimum_train_delay integer,
    num_cars integer NOT NULL,
    num_delayed_trains integer,
    num_eight_car_trains integer NOT NULL,
    num_trains integer NOT NULL,
    platform_wait_time_trend_status integer,
    should_exclude_from_reports boolean,
    standard_deviation_train_frequency double precision,
    train_frequency_status integer,
    budgeted_num_cars integer,
    budgeted_num_eight_car_trains integer,
    budgeted_num_trains integer,
    date timestamp without time zone NOT NULL,
    line_code character varying(255) NOT NULL
);


ALTER TABLE public.line_metrics OWNER TO postgres;

--
-- Name: line_metrics_direction_metrics_by_direction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.line_metrics_direction_metrics_by_direction (
    "system_metrics$line_metrics_id" bigint NOT NULL,
    direction_metrics_by_direction_id bigint NOT NULL,
    direction_metrics_by_direction_key integer NOT NULL
);


ALTER TABLE public.line_metrics_direction_metrics_by_direction OWNER TO postgres;

--
-- Name: rail_incident; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rail_incident (
    description character varying(255) NOT NULL,
    incident_id character varying(255) NOT NULL,
    "timestamp" bigint NOT NULL,
    date timestamp without time zone NOT NULL,
    keywords_array text[],
    keywords character varying(255),
    line_codes text[] NOT NULL,
    station_codes text[] NOT NULL
);


ALTER TABLE public.rail_incident OWNER TO postgres;

--
-- Name: speed_restriction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.speed_restriction (
    id bigint NOT NULL,
    as_of character varying(255),
    description character varying(255),
    from_station_code character varying(255) NOT NULL,
    from_station_name character varying(255) NOT NULL,
    group_id bigint,
    maximum_speed integer,
    source character varying(255),
    to_station_code character varying(255),
    to_station_name character varying(255),
    track_number integer NOT NULL
);


ALTER TABLE public.speed_restriction OWNER TO postgres;

--
-- Name: speed_restriction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.speed_restriction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.speed_restriction_id_seq OWNER TO postgres;

--
-- Name: speed_restriction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.speed_restriction_id_seq OWNED BY public.speed_restriction.id;


--
-- Name: station_problem_tweet; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.station_problem_tweet (
    id bigint NOT NULL,
    date timestamp without time zone NOT NULL,
    keywords text[],
    line_codes text[],
    station_codes text[] NOT NULL,
    text text NOT NULL,
    twitter_id bigint NOT NULL,
    user_id bigint NOT NULL,
    user_name character varying(255)
);


ALTER TABLE public.station_problem_tweet OWNER TO postgres;

--
-- Name: station_problem_tweet_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.station_problem_tweet_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.station_problem_tweet_id_seq OWNER TO postgres;

--
-- Name: station_problem_tweet_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.station_problem_tweet_id_seq OWNED BY public.station_problem_tweet.id;


--
-- Name: station_tag; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.station_tag (
    id bigint NOT NULL,
    date timestamp without time zone NOT NULL,
    line_codes text[],
    station_code character varying(255) NOT NULL,
    tweet_id bigint,
    type character varying(255) NOT NULL,
    user_id character varying(255) NOT NULL
);


ALTER TABLE public.station_tag OWNER TO postgres;

--
-- Name: station_tag_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.station_tag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.station_tag_id_seq OWNER TO postgres;

--
-- Name: station_tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.station_tag_id_seq OWNED BY public.station_tag.id;


--
-- Name: station_to_station_travel_time; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.station_to_station_travel_time (
    station_codes_key character varying(255) NOT NULL,
    distance bigint,
    from_station_code character varying(255) NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    to_station_code character varying(255) NOT NULL
);


ALTER TABLE public.station_to_station_travel_time OWNER TO postgres;

--
-- Name: station_to_station_trip; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.station_to_station_trip (
    id bigint NOT NULL,
    arriving_direction_number integer,
    arriving_station_code character varying(255),
    arriving_time timestamp without time zone,
    arriving_track_number integer,
    departing_station_code character varying(255),
    departing_time timestamp without time zone,
    destination_station_code character varying(255),
    line_code character varying(255),
    num_cars integer,
    real_train_id character varying(255),
    seconds_at_departing_station integer,
    train_id character varying(255),
    trip_duration double precision,
    trip_id uuid
);


ALTER TABLE public.station_to_station_trip OWNER TO postgres;

--
-- Name: station_to_station_trip_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.station_to_station_trip_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.station_to_station_trip_id_seq OWNER TO postgres;

--
-- Name: station_to_station_trip_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.station_to_station_trip_id_seq OWNED BY public.station_to_station_trip.id;


--
-- Name: system_metrics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_metrics (
    id bigint NOT NULL,
    date timestamp without time zone NOT NULL
);


ALTER TABLE public.system_metrics OWNER TO postgres;

--
-- Name: system_metrics_line_metrics_by_line; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_metrics_line_metrics_by_line (
    system_metrics_id bigint NOT NULL,
    line_metrics_by_line_id bigint NOT NULL,
    line_metrics_by_line_key character varying(255) NOT NULL
);


ALTER TABLE public.system_metrics_line_metrics_by_line OWNER TO postgres;

--
-- Name: track_circuit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.track_circuit (
    api_id integer NOT NULL,
    from_chain_marker double precision,
    length double precision NOT NULL,
    to_chain_marker double precision,
    track_id character varying(255) NOT NULL,
    track_name character varying(255) NOT NULL
);


ALTER TABLE public.track_circuit OWNER TO postgres;

--
-- Name: train_car_problem_tweet; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.train_car_problem_tweet (
    id bigint NOT NULL,
    date timestamp without time zone NOT NULL,
    keywords text[],
    line_codes text[],
    text text NOT NULL,
    train_car_id character varying(255) NOT NULL,
    twitter_id bigint NOT NULL,
    user_id bigint NOT NULL,
    user_name character varying(255)
);


ALTER TABLE public.train_car_problem_tweet OWNER TO postgres;

--
-- Name: train_car_problem_tweet_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.train_car_problem_tweet_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.train_car_problem_tweet_id_seq OWNER TO postgres;

--
-- Name: train_car_problem_tweet_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.train_car_problem_tweet_id_seq OWNED BY public.train_car_problem_tweet.id;


--
-- Name: train_departure; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.train_departure (
    departure_station_code character varying(255) NOT NULL,
    departure_time timestamp without time zone NOT NULL,
    direction_number integer NOT NULL,
    line_code character varying(255) NOT NULL,
    departure_station_name character varying(255),
    destination_station_code character varying(255),
    destination_station_name character varying(255),
    direction_name character varying(255),
    line_name character varying(255),
    num_cars integer,
    real_train_id character varying(255),
    train_id character varying(255),
    trip_id character varying(255),
    type character varying(255) NOT NULL
);


ALTER TABLE public.train_departure OWNER TO postgres;

--
-- Name: train_departure_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.train_departure_info (
    id bigint NOT NULL,
    departure_station_code character varying(255),
    departure_station_name character varying(255),
    direction_name character varying(255),
    direction_number integer,
    headway_deviation double precision,
    line_code character varying(255),
    line_name character varying(255),
    observed_departure_time timestamp without time zone,
    observed_destination_station_code character varying(255),
    observed_destination_station_name character varying(255),
    observed_num_cars integer,
    observed_time_since_last_departure double precision,
    real_train_id character varying(255),
    schedule_deviation double precision,
    scheduled_departure_time timestamp without time zone,
    scheduled_destination_station_code character varying(255),
    scheduled_destination_station_name character varying(255),
    scheduled_time_since_last_departure double precision,
    train_id character varying(255)
);


ALTER TABLE public.train_departure_info OWNER TO postgres;

--
-- Name: train_departure_info_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.train_departure_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.train_departure_info_id_seq OWNER TO postgres;

--
-- Name: train_departure_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.train_departure_info_id_seq OWNED BY public.train_departure_info.id;


--
-- Name: train_disappearance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.train_disappearance (
    id bigint NOT NULL,
    date timestamp without time zone NOT NULL,
    destination_station_code character varying(255),
    direction_number integer,
    line_code character varying(255),
    real_train_id character varying(255),
    station_code character varying(255),
    track_circuit_id integer,
    train_id character varying(255)
);


ALTER TABLE public.train_disappearance OWNER TO postgres;

--
-- Name: train_disappearance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.train_disappearance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.train_disappearance_id_seq OWNER TO postgres;

--
-- Name: train_disappearance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.train_disappearance_id_seq OWNED BY public.train_disappearance.id;


--
-- Name: train_expressed_station_event; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.train_expressed_station_event (
    id bigint NOT NULL,
    date timestamp without time zone NOT NULL,
    destination_station_code character varying(255),
    direction_number integer,
    line_code character varying(255),
    num_cars character varying(255),
    num_seconds_at_station integer,
    real_train_id character varying(255),
    station_code character varying(255),
    track_number integer,
    train_id character varying(255)
);


ALTER TABLE public.train_expressed_station_event OWNER TO postgres;

--
-- Name: train_expressed_station_event_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.train_expressed_station_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.train_expressed_station_event_id_seq OWNER TO postgres;

--
-- Name: train_expressed_station_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.train_expressed_station_event_id_seq OWNED BY public.train_expressed_station_event.id;


--
-- Name: train_offload; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.train_offload (
    id bigint NOT NULL,
    date timestamp without time zone NOT NULL,
    destination_station_code character varying(255),
    direction_number integer,
    line_code character varying(255),
    real_train_id character varying(255),
    station_code character varying(255),
    train_id character varying(255)
);


ALTER TABLE public.train_offload OWNER TO postgres;

--
-- Name: train_offload_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.train_offload_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.train_offload_id_seq OWNER TO postgres;

--
-- Name: train_offload_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.train_offload_id_seq OWNED BY public.train_offload.id;


--
-- Name: train_prediction_accuracy_measurement; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.train_prediction_accuracy_measurement (
    id bigint NOT NULL,
    average_prediction_error double precision NOT NULL,
    destination_station_code character varying(255) NOT NULL,
    has_corresponding_wmata_measurement boolean NOT NULL,
    line_code character varying(255) NOT NULL,
    measurement_end_time timestamp without time zone NOT NULL,
    measurement_start_prediction character varying(255) NOT NULL,
    measurement_start_time timestamp without time zone NOT NULL,
    num_prediction_samples bigint NOT NULL,
    prediction_origin_station character varying(255) NOT NULL,
    prediction_source character varying(255) NOT NULL
);


ALTER TABLE public.train_prediction_accuracy_measurement OWNER TO postgres;

--
-- Name: train_prediction_accuracy_measurement_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.train_prediction_accuracy_measurement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.train_prediction_accuracy_measurement_id_seq OWNER TO postgres;

--
-- Name: train_prediction_accuracy_measurement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.train_prediction_accuracy_measurement_id_seq OWNED BY public.train_prediction_accuracy_measurement.id;


--
-- Name: train_problem_tweet; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.train_problem_tweet (
    id bigint NOT NULL,
    date timestamp without time zone NOT NULL,
    keywords text[],
    line_codes text[],
    real_train_id character varying(255) NOT NULL,
    text text NOT NULL,
    train_id character varying(255) NOT NULL,
    twitter_id bigint NOT NULL,
    user_id bigint NOT NULL,
    user_name character varying(255)
);


ALTER TABLE public.train_problem_tweet OWNER TO postgres;

--
-- Name: train_problem_tweet_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.train_problem_tweet_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.train_problem_tweet_id_seq OWNER TO postgres;

--
-- Name: train_problem_tweet_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.train_problem_tweet_id_seq OWNED BY public.train_problem_tweet.id;


--
-- Name: train_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.train_status (
    id bigint NOT NULL,
    num_cars character varying(255),
    destination_station character varying(255),
    destination_station_code character varying(255),
    destination_station_name character varying(255),
    group_number character varying(255),
    line_code character varying(255),
    location_station_code character varying(255),
    location_station_name character varying(255),
    eta character varying(255),
    previous_station_code character varying(255),
    should_render_on_left boolean NOT NULL,
    are_doors_open boolean,
    are_doors_open_on_left boolean,
    are_doors_open_on_right boolean,
    are_doors_operating_manually boolean,
    circuit_name character varying(255),
    current_station_code character varying(255),
    current_station_name character varying(255),
    num_times_delayed integer NOT NULL,
    destination_id character varying(255),
    destination_station_abbreviation character varying(255),
    direction integer,
    direction_number integer,
    distance_from_next_station integer,
    estimated_minutes_away double precision,
    first_observed_train timestamp without time zone,
    is_adjusting_on_platform boolean,
    is_holding_or_slow boolean NOT NULL,
    is_keyed_down boolean NOT NULL,
    is_not_on_revenue_track boolean NOT NULL,
    is_scheduled boolean NOT NULL,
    last_visited_station timestamp without time zone,
    last_visited_station_code character varying(255),
    lat double precision,
    lon double precision,
    max_minutes_away double precision,
    minutes_away double precision,
    num_negative_tags integer NOT NULL,
    num_positive_tags integer NOT NULL,
    observed_date timestamp without time zone NOT NULL,
    original_destination_code character varying(255),
    original_line_code character varying(255),
    parent_min character varying(255),
    previous_station_name character varying(255),
    raw_track_circuit_id integer,
    real_train_id character varying(255),
    seconds_at_last_visited_station integer,
    seconds_delayed integer,
    num_seconds_off_schedule integer NOT NULL,
    seconds_since_last_moved integer NOT NULL,
    track_circuit_id integer,
    track_number integer NOT NULL,
    train_id character varying(255),
    train_speed integer,
    trip_id uuid,
    was_keyed_down boolean NOT NULL
);


ALTER TABLE public.train_status OWNER TO postgres;

--
-- Name: train_status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.train_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.train_status_id_seq OWNER TO postgres;

--
-- Name: train_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.train_status_id_seq OWNED BY public.train_status.id;


--
-- Name: train_tag; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.train_tag (
    id bigint NOT NULL,
    date timestamp without time zone NOT NULL,
    line_code character varying(255),
    real_train_id character varying(255),
    station_code character varying(255),
    train_id character varying(255) NOT NULL,
    tweet_id bigint,
    type character varying(255) NOT NULL,
    user_id character varying(255) NOT NULL
);


ALTER TABLE public.train_tag OWNER TO postgres;

--
-- Name: train_tag_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.train_tag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.train_tag_id_seq OWNER TO postgres;

--
-- Name: train_tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.train_tag_id_seq OWNED BY public.train_tag.id;


--
-- Name: trip_state; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trip_state (
    id bigint NOT NULL,
    date timestamp without time zone NOT NULL,
    expected_ride_time double precision,
    from_station_code character varying(255) NOT NULL,
    predicted_ride_time double precision,
    time_since_last_train double precision,
    time_until_next_train double precision,
    to_station_code character varying(255) NOT NULL
);


ALTER TABLE public.trip_state OWNER TO postgres;

--
-- Name: trip_state_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.trip_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.trip_state_id_seq OWNER TO postgres;

--
-- Name: trip_state_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.trip_state_id_seq OWNED BY public.trip_state.id;


--
-- Name: api_request id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_request ALTER COLUMN id SET DEFAULT nextval('public.api_request_id_seq'::regclass);


--
-- Name: duplicate_train_event id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.duplicate_train_event ALTER COLUMN id SET DEFAULT nextval('public.duplicate_train_event_id_seq'::regclass);


--
-- Name: speed_restriction id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.speed_restriction ALTER COLUMN id SET DEFAULT nextval('public.speed_restriction_id_seq'::regclass);


--
-- Name: station_problem_tweet id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.station_problem_tweet ALTER COLUMN id SET DEFAULT nextval('public.station_problem_tweet_id_seq'::regclass);


--
-- Name: station_tag id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.station_tag ALTER COLUMN id SET DEFAULT nextval('public.station_tag_id_seq'::regclass);


--
-- Name: station_to_station_trip id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.station_to_station_trip ALTER COLUMN id SET DEFAULT nextval('public.station_to_station_trip_id_seq'::regclass);


--
-- Name: train_car_problem_tweet id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_car_problem_tweet ALTER COLUMN id SET DEFAULT nextval('public.train_car_problem_tweet_id_seq'::regclass);


--
-- Name: train_departure_info id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_departure_info ALTER COLUMN id SET DEFAULT nextval('public.train_departure_info_id_seq'::regclass);


--
-- Name: train_disappearance id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_disappearance ALTER COLUMN id SET DEFAULT nextval('public.train_disappearance_id_seq'::regclass);


--
-- Name: train_expressed_station_event id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_expressed_station_event ALTER COLUMN id SET DEFAULT nextval('public.train_expressed_station_event_id_seq'::regclass);


--
-- Name: train_offload id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_offload ALTER COLUMN id SET DEFAULT nextval('public.train_offload_id_seq'::regclass);


--
-- Name: train_prediction_accuracy_measurement id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_prediction_accuracy_measurement ALTER COLUMN id SET DEFAULT nextval('public.train_prediction_accuracy_measurement_id_seq'::regclass);


--
-- Name: train_problem_tweet id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_problem_tweet ALTER COLUMN id SET DEFAULT nextval('public.train_problem_tweet_id_seq'::regclass);


--
-- Name: train_status id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_status ALTER COLUMN id SET DEFAULT nextval('public.train_status_id_seq'::regclass);


--
-- Name: train_tag id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_tag ALTER COLUMN id SET DEFAULT nextval('public.train_tag_id_seq'::regclass);


--
-- Name: trip_state id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_state ALTER COLUMN id SET DEFAULT nextval('public.trip_state_id_seq'::regclass);


--
-- Data for Name: api_request; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.api_request (id, api_key, date, endpoint, originating_ip_address, params) FROM stdin;
\.


--
-- Data for Name: api_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.api_user (api_key, activation_date, email_address, is_blocked, max_calls_per_day, max_calls_per_second, name) FROM stdin;
\.


--
-- Data for Name: daily_service_report; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.daily_service_report (date, num_customers_refunded, percent_customers_on_time, percent_customers_refunded, percent_customers_within_five_minutes_expected_time) FROM stdin;
\.


--
-- Data for Name: destination_code_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.destination_code_mapping (destination_code, direction_number, destination_station_code, line_code) FROM stdin;
\.


--
-- Data for Name: direction_metrics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.direction_metrics (id, average_headway_adherence, average_minimum_headways, average_on_time_performance, average_platform_wait_time, average_schedule_adherence, average_train_delay, average_train_frequency, expected_num_trains, expected_platform_wait_time, expected_standard_deviation_train_frequency, expected_train_frequency, maximum_train_delay, median_train_delay, minimum_train_delay, num_cars, num_delayed_trains, num_eight_car_trains, num_trains, platform_wait_time_trend_status, should_exclude_from_reports, standard_deviation_train_frequency, train_frequency_status, date, direction, direction_number, line_code, towards_station_name) FROM stdin;
\.


--
-- Data for Name: duplicate_train_event; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.duplicate_train_event (id, date, destination_station_code, kept_train_direction_number, kept_train_id, line_code, real_train_id, removed_train_direction_number, removed_train_id, station_code) FROM stdin;
\.


--
-- Data for Name: line_metrics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.line_metrics (id, average_headway_adherence, average_minimum_headways, average_on_time_performance, average_platform_wait_time, average_schedule_adherence, average_train_delay, average_train_frequency, expected_num_trains, expected_platform_wait_time, expected_standard_deviation_train_frequency, expected_train_frequency, maximum_train_delay, median_train_delay, minimum_train_delay, num_cars, num_delayed_trains, num_eight_car_trains, num_trains, platform_wait_time_trend_status, should_exclude_from_reports, standard_deviation_train_frequency, train_frequency_status, budgeted_num_cars, budgeted_num_eight_car_trains, budgeted_num_trains, date, line_code) FROM stdin;
\.


--
-- Data for Name: line_metrics_direction_metrics_by_direction; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.line_metrics_direction_metrics_by_direction ("system_metrics$line_metrics_id", direction_metrics_by_direction_id, direction_metrics_by_direction_key) FROM stdin;
\.


--
-- Data for Name: rail_incident; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rail_incident (description, incident_id, "timestamp", date, keywords_array, keywords, line_codes, station_codes) FROM stdin;
\.


--
-- Data for Name: speed_restriction; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.speed_restriction (id, as_of, description, from_station_code, from_station_name, group_id, maximum_speed, source, to_station_code, to_station_name, track_number) FROM stdin;
\.


--
-- Data for Name: station_problem_tweet; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.station_problem_tweet (id, date, keywords, line_codes, station_codes, text, twitter_id, user_id, user_name) FROM stdin;
\.


--
-- Data for Name: station_tag; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.station_tag (id, date, line_codes, station_code, tweet_id, type, user_id) FROM stdin;
\.


--
-- Data for Name: station_to_station_travel_time; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) FROM stdin;
\.


--
-- Data for Name: station_to_station_trip; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.station_to_station_trip (id, arriving_direction_number, arriving_station_code, arriving_time, arriving_track_number, departing_station_code, departing_time, destination_station_code, line_code, num_cars, real_train_id, seconds_at_departing_station, train_id, trip_duration, trip_id) FROM stdin;
\.


--
-- Data for Name: system_metrics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.system_metrics (id, date) FROM stdin;
\.


--
-- Data for Name: system_metrics_line_metrics_by_line; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.system_metrics_line_metrics_by_line (system_metrics_id, line_metrics_by_line_id, line_metrics_by_line_key) FROM stdin;
\.


--
-- Data for Name: track_circuit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.track_circuit (api_id, from_chain_marker, length, to_chain_marker, track_id, track_name) FROM stdin;
1	\N	642	\N	A15-4Y1	A1
2	\N	10	\N	A15-5ATU	A1
3	\N	101	\N	A15-5ATN	A1
4	\N	10	\N	A15-7ATN	A1
5	\N	101	\N	A15-7ATU	A1
6	\N	213	\N	A15-A1-948	A1
7	\N	600	\N	A15-A1-942	A1
8	\N	52	\N	A15-A1-941	A1
9	\N	10	\N	A15-1ATU	A1
10	\N	204	\N	A15-1ATN	A1
11	\N	10	\N	A15-3ATN	A1
12	\N	204	\N	A15-3ATU	A1
13	\N	487	\N	A15-A1-932	A1
14	\N	979	\N	A15-A1-922	A1
15	\N	1015	\N	A15-A1-912	A1
16	\N	749	\N	A15-A1-905	A1
17	\N	836	\N	A15-A1-896	A1
18	\N	824	\N	A15-A1-888	A1
19	\N	896	\N	A15-A1-879	A1
20	\N	893	\N	A15-A1-870	A1
21	\N	897	\N	A15-A1-861	A1
22	\N	892	\N	A15-A1-852	A1
23	\N	802	\N	A15-A1-844	A1
24	\N	987	\N	A15-A1-834	A1
25	\N	744	\N	A14-A1-827	A1
26	\N	450	\N	A14-A1-823	A1
27	\N	455	\N	A14-A1-818	A1
28	\N	151	\N	A14-A1-816	A1
29	\N	297	\N	A14-A1-814	A1
30	\N	461	\N	A14-A1-809	A1
31	\N	256	\N	A14-A1-806	A1
32	\N	600	\N	A14-A1-805	A1
33	\N	425	\N	A14-A1-796	A1
34	\N	447	\N	A14-A1-792	A1
35	\N	453	\N	A14-A1-787	A1
36	\N	370	\N	A14-A1-783	A1
37	\N	830	\N	A14-A1-775	A1
38	\N	857	\N	A14-A1-766	A1
39	\N	843	\N	A14-A1-758	A1
40	\N	810	\N	A14-A1-750	A1
41	\N	765	\N	A14-A1-742	A1
42	\N	875	\N	A13-A1-734	A1
43	\N	1230	\N	A13-A1-721	A1
44	\N	410	\N	A13-A1-717	A1
45	\N	499	\N	A13-A1-712	A1
46	\N	437	\N	A13-A1-708	A1
47	\N	341	\N	A13-A1-704	A1
48	\N	10	\N	A13-1ATU	A1
49	\N	161	\N	A13-1ATN	A1
50	\N	10	\N	A13-3ATN	A1
51	\N	161	\N	A13-3ATU	A1
52	\N	52	\N	A13-A1-700	A1
53	\N	600	\N	A13-A1-699	A1
54	\N	396	\N	A13-A1-690	A1
55	\N	390	\N	A13-A1-687	A1
56	\N	370	\N	A13-A1-683	A1
57	\N	1089	\N	A13-A1-672	A1
58	\N	1325	\N	A13-A1-659	A1
59	\N	520	\N	A12-A1-653	A1
60	\N	770	\N	A12-A1-646	A1
61	\N	435	\N	A12-A1-641	A1
62	\N	600	\N	A12-A1-635	A1
63	\N	483	\N	A12-A1-631	A1
64	\N	602	\N	A12-A1-625	A1
65	\N	936	\N	A12-A1-615	A1
66	\N	873	\N	A12-A1-607	A1
67	\N	700	\N	A12-A1-600	A1
68	\N	1167	\N	A11-A1-588	A1
69	\N	471	\N	A11-A1-583	A1
70	\N	259	\N	A11-A1-581	A1
71	\N	10	\N	A11-5ATU	A1
72	\N	93	\N	A11-5ATN	A1
73	\N	103	\N	A11-5ABT	A1
74	\N	364	\N	A11-A1-575	A1
75	\N	354	\N	A11-A1-572	A1
76	\N	81	\N	A11-9ABT	A1
77	\N	10	\N	A11-9TN	A1
78	\N	115	\N	A11-9TU	A1
79	\N	88	\N	A11-A1-569	A1
80	\N	600	\N	A11-A1-566	A1
81	\N	503	\N	A11-A1-558	A1
82	\N	610	\N	A11-A1-551	A1
83	\N	342	\N	A11-A1-548	A1
84	\N	1176	\N	A11-A1-536	A1
85	\N	1053	\N	A11-A1-526	A1
86	\N	656	\N	A11-A1-519	A1
87	\N	840	\N	A11-A1-511	A1
88	\N	1266	\N	A11-A1-498	A1
89	\N	1142	\N	A10-A1-487	A1
90	\N	703	\N	A10-A1-480	A1
91	\N	1289	\N	A10-A1-467	A1
92	\N	701	\N	A10-A1-460	A1
93	\N	705	\N	A10-A1-453	A1
94	\N	235	\N	A10-A1-450	A1
95	\N	600	\N	A10-A1-444	A1
96	\N	52	\N	A10-A1-443	A1
97	\N	10	\N	A10-1ATU	A1
98	\N	161	\N	A10-1ATN	A1
99	\N	10	\N	A10-3ATN	A1
100	\N	161	\N	A10-3ATU	A1
101	\N	386	\N	A10-A1-437	A1
102	\N	455	\N	A10-A1-432	A1
103	\N	1235	\N	A10-A1-420	A1
104	\N	831	\N	A10-A1-411	A1
105	\N	552	\N	A09-A1-406	A1
106	\N	564	\N	A09-A1-400	A1
107	\N	387	\N	A09-A1-396	A1
108	\N	126	\N	A09-A1-395	A1
109	\N	600	\N	A09-A1-389	A1
110	\N	113	\N	A09-A1-388	A1
111	\N	498	\N	A09-A1-383	A1
112	\N	717	\N	A09-A1-376	A1
113	\N	1288	\N	A09-A1-363	A1
114	\N	1085	\N	A09-A1-352	A1
115	\N	1110	\N	A09-A1-341	A1
116	\N	730	\N	A08-A1-334	A1
117	\N	904	\N	A08-A1-325	A1
118	\N	597	\N	A08-A1-319	A1
119	\N	414	\N	A08-A1-315	A1
120	\N	575	\N	A08-A1-309	A1
121	\N	10	\N	A08-1ATU	A1
122	\N	167	\N	A08-1ATN	A1
123	\N	10	\N	A08-3ATN	A1
124	\N	167	\N	A08-3ATU	A1
125	\N	110	\N	A08-A1-304	A1
126	\N	600	\N	A08-A1-303	A1
127	\N	545	\N	A08-A1-293	A1
128	\N	514	\N	A08-A1-288	A1
129	\N	1066	\N	A08-A1-277	A1
130	\N	600	\N	A07-A1-271	A1
131	\N	640	\N	A07-A1-265	A1
132	\N	170	\N	A07-A1-263	A1
133	\N	600	\N	A07-A1-262	A1
134	\N	503	\N	A07-A1-252	A1
135	\N	608	\N	A07-A1-246	A1
136	\N	312	\N	A07-A1-243	A1
137	\N	1218	\N	A07-A1-231	A1
138	\N	1026	\N	A07-A1-221	A1
139	\N	790	\N	A06-A1-212	A1
140	\N	646	\N	A06-A1-206	A1
141	\N	138	\N	A06-A1-205	A1
142	\N	600	\N	A06-A1-199	A1
143	\N	128	\N	A06-A1-197	A1
144	\N	10	\N	A06-1ATU	A1
145	\N	161	\N	A06-1ATN	A1
146	\N	10	\N	A06-3ATN	A1
147	\N	161	\N	A06-3ATU	A1
148	\N	290	\N	A06-A1-191	A1
149	\N	393	\N	A06-A1-187	A1
150	\N	307	\N	A06-A1-184	A1
151	\N	460	\N	A06-A1-179	A1
152	\N	525	\N	A06-A1-174	A1
153	\N	275	\N	A05-A1-171	A1
154	\N	600	\N	A05-A1-169	A1
155	\N	270	\N	A05-A1-163	A1
156	\N	593	\N	A05-A1-157	A1
157	\N	227	\N	A05-A1-155	A1
158	\N	238	\N	A05-A1-152	A1
159	\N	272	\N	A05-A1-149	A1
160	\N	525	\N	A05-A1-144	A1
161	\N	390	\N	A04-A1-140	A1
162	\N	475	\N	A04-A1-136	A1
163	\N	150	\N	A04-A1-134	A1
164	\N	600	\N	A04-A1-131	A1
165	\N	623	\N	A04-A1-122	A1
166	\N	533	\N	A04-A1-116	A1
167	\N	813	\N	A04-A1-108	A1
168	\N	1330	\N	A04-A1-95	A1
169	\N	424	\N	A03-A1-91	A1
170	\N	440	\N	A03-A1-86	A1
171	\N	195	\N	A03-A1-84	A1
172	\N	549	\N	A03-A1-79	A1
173	\N	518	\N	A03-A1-74	A1
174	\N	10	\N	A03-1ATU	A1
175	\N	81	\N	A03-1ATN	A1
176	\N	10	\N	A03-3ATN	A1
177	\N	81	\N	A03-3ATU	A1
178	\N	97	\N	A03-A1-71	A1
179	\N	600	\N	A03-A1-70	A1
180	\N	400	\N	A03-A1-61	A1
181	\N	269	\N	A03-A1-59	A1
182	\N	240	\N	A03-A1-56	A1
183	\N	10	\N	A02-5ATU	A1
184	\N	261	\N	A02-5ATN	A1
185	\N	352	\N	A02-A1-51	A1
186	\N	349	\N	A02-A1-47	A1
187	\N	10	\N	A02-9TN	A1
188	\N	161	\N	A02-9TU	A1
189	\N	59	\N	A02-A1-44	A1
190	\N	600	\N	A02-A1-42	A1
191	\N	349	\N	A02-A1-35	A1
192	\N	349	\N	A02-A1-32	A1
193	\N	290	\N	A02-A1-29	A1
194	\N	708	\N	A01-A1-22	A1
195	\N	738	\N	A01-A1-14	A1
196	\N	194	\N	A01-A1-13	A1
197	\N	218	\N	A01-A1-10	A1
198	\N	185	\N	A01-A1-8	A1
199	\N	133	\N	A01-A1-7	A1
200	\N	196	\N	A01-A1-5	A1
201	\N	168	\N	A01-A1-4	A1
202	\N	50	\N	A01-A1-3	A1
203	\N	600	\N	A01-A1-2	A1
204	\N	642	\N	A15-4Y2	A2
205	\N	10	\N	A15-7BTU	A2
206	\N	101	\N	A15-7BTN	A2
207	\N	10	\N	A15-5BTN	A2
208	\N	101	\N	A15-5BTU	A2
209	\N	213	\N	A15-A2-948	A2
210	\N	600	\N	A15-A2-942	A2
211	\N	52	\N	A15-A2-941	A2
212	\N	10	\N	A15-3BTU	A2
213	\N	204	\N	A15-3BTN	A2
214	\N	10	\N	A15-1BTN	A2
215	\N	204	\N	A15-1BTU	A2
216	\N	660	\N	A15-A2-930	A2
217	\N	806	\N	A15-A2-922	A2
218	\N	426	\N	A15-A2-918	A2
219	\N	1342	\N	A15-A2-905	A2
220	\N	1240	\N	A15-A2-892	A2
221	\N	420	\N	A15-A2-888	A2
222	\N	894	\N	A15-A2-879	A2
223	\N	895	\N	A15-A2-870	A2
224	\N	997	\N	A15-A2-860	A2
225	\N	792	\N	A15-A2-852	A2
226	\N	596	\N	A15-A2-846	A2
227	\N	1193	\N	A14-A2-834	A2
228	\N	1235	\N	A14-A2-822	A2
229	\N	562	\N	A14-A2-816	A2
230	\N	569	\N	A14-A2-811	A2
231	\N	438	\N	A14-A2-806	A2
232	\N	600	\N	A14-A2-800	A2
233	\N	625	\N	A14-A2-794	A2
234	\N	515	\N	A14-A2-789	A2
235	\N	555	\N	A14-A2-783	A2
236	\N	625	\N	A14-A2-777	A2
237	\N	1062	\N	A14-A2-766	A2
238	\N	1063	\N	A14-A2-756	A2
239	\N	590	\N	A14-A2-750	A2
240	\N	820	\N	A13-A2-742	A2
241	\N	820	\N	A13-A2-734	A2
242	\N	820	\N	A13-A2-725	A2
243	\N	820	\N	A13-A2-717	A2
244	\N	647	\N	A13-A2-711	A2
245	\N	629	\N	A13-A2-704	A2
246	\N	10	\N	A13-3BTU	A2
247	\N	161	\N	A13-3BTN	A2
248	\N	10	\N	A13-1BTN	A2
249	\N	161	\N	A13-1BTU	A2
250	\N	52	\N	A13-A2-700	A2
251	\N	600	\N	A13-A2-694	A2
252	\N	739	\N	A13-A2-687	A2
253	\N	540	\N	A13-A2-682	A2
254	\N	552	\N	A13-A2-676	A2
255	\N	424	\N	A13-A2-672	A2
256	\N	720	\N	A12-A2-665	A2
257	\N	1125	\N	A12-A2-653	A2
258	\N	590	\N	A12-A2-648	A2
259	\N	605	\N	A12-A2-641	A2
260	\N	600	\N	A12-A2-635	A2
261	\N	515	\N	A12-A2-630	A2
262	\N	595	\N	A12-A2-624	A2
263	\N	513	\N	A12-A2-619	A2
264	\N	399	\N	A12-A2-615	A2
265	\N	873	\N	A12-A2-607	A2
266	\N	700	\N	A11-A2-600	A2
267	\N	1125	\N	A11-A2-588	A2
268	\N	513	\N	A11-A2-583	A2
269	\N	259	\N	A11-A2-581	A2
270	\N	10	\N	A11-7TU	A2
271	\N	93	\N	A11-7TN	A2
272	\N	103	\N	A11-7ABT	A2
273	\N	718	\N	A11-A2-572	A2
274	\N	103	\N	A11-11BBT	A2
275	\N	10	\N	A11-11BTN	A2
276	\N	93	\N	A11-11BTU	A2
277	\N	88	\N	A11-A2-569	A2
278	\N	600	\N	A11-A2-563	A2
279	\N	662	\N	A11-A2-556	A2
280	\N	465	\N	A11-A2-551	A2
281	\N	645	\N	A11-A2-545	A2
282	\N	1467	\N	A11-A2-530	A2
283	\N	454	\N	A11-A2-526	A2
284	\N	669	\N	A11-A2-519	A2
285	\N	830	\N	A11-A2-511	A2
286	\N	1140	\N	A10-A2-499	A2
287	\N	1282	\N	A10-A2-487	A2
288	\N	988	\N	A10-A2-477	A2
289	\N	999	\N	A10-A2-467	A2
290	\N	346	\N	A10-A2-463	A2
291	\N	493	\N	A10-A2-458	A2
292	\N	522	\N	A10-A2-453	A2
293	\N	280	\N	A10-A2-450	A2
294	\N	600	\N	A10-A2-444	A2
295	\N	52	\N	A10-A2-443	A2
296	\N	10	\N	A10-3BTU	A2
297	\N	161	\N	A10-3BTN	A2
298	\N	10	\N	A10-1BTN	A2
299	\N	161	\N	A10-1BTU	A2
300	\N	464	\N	A10-A2-436	A2
301	\N	466	\N	A10-A2-431	A2
302	\N	409	\N	A10-A2-427	A2
303	\N	734	\N	A10-A2-420	A2
304	\N	757	\N	A09-A2-412	A2
305	\N	619	\N	A09-A2-406	A2
306	\N	587	\N	A09-A2-400	A2
307	\N	367	\N	A09-A2-396	A2
308	\N	126	\N	A09-A2-395	A2
309	\N	600	\N	A09-A2-389	A2
310	\N	109	\N	A09-A2-388	A2
311	\N	413	\N	A09-A2-384	A2
312	\N	516	\N	A09-A2-379	A2
313	\N	568	\N	A09-A2-373	A2
314	\N	1016	\N	A09-A2-363	A2
315	\N	1097	\N	A09-A2-352	A2
316	\N	1098	\N	A08-A2-341	A2
317	\N	790	\N	A08-A2-333	A2
318	\N	834	\N	A08-A2-325	A2
319	\N	916	\N	A08-A2-316	A2
320	\N	670	\N	A08-A2-309	A2
321	\N	10	\N	A08-3BTU	A2
322	\N	167	\N	A08-3BTN	A2
323	\N	10	\N	A08-1BTN	A2
324	\N	167	\N	A08-1BTU	A2
325	\N	110	\N	A08-A2-304	A2
326	\N	600	\N	A08-A2-301	A2
327	\N	165	\N	A08-A2-297	A2
328	\N	505	\N	A08-A2-291	A2
329	\N	475	\N	A08-A2-287	A2
330	\N	337	\N	A08-A2-283	A2
331	\N	368	\N	A07-A2-280	A2
332	\N	255	\N	A07-A2-277	A2
333	\N	395	\N	A07-A2-273	A2
334	\N	735	\N	A07-A2-266	A2
335	\N	280	\N	A07-A2-263	A2
336	\N	600	\N	A07-A2-257	A2
337	\N	403	\N	A07-A2-253	A2
338	\N	597	\N	A07-A2-247	A2
339	\N	896	\N	A07-A2-238	A2
340	\N	702	\N	A07-A2-231	A2
341	\N	1026	\N	A06-A2-221	A2
342	\N	618	\N	A06-A2-215	A2
343	\N	365	\N	A06-A2-211	A2
344	\N	518	\N	A06-A2-206	A2
345	\N	140	\N	A06-A2-205	A2
346	\N	600	\N	A06-A2-199	A2
347	\N	128	\N	A06-A2-197	A2
348	\N	10	\N	A06-3BTU	A2
349	\N	161	\N	A06-3BTN	A2
350	\N	10	\N	A06-1BTN	A2
351	\N	161	\N	A06-1BTU	A2
352	\N	288	\N	A06-A2-191	A2
353	\N	395	\N	A06-A2-187	A2
354	\N	652	\N	A06-A2-181	A2
355	\N	915	\N	A05-A2-171	A2
356	\N	600	\N	A05-A2-165	A2
357	\N	313	\N	A05-A2-162	A2
358	\N	503	\N	A05-A2-157	A2
359	\N	281	\N	A05-A2-154	A2
360	\N	803	\N	A04-A2-146	A2
361	\N	640	\N	A04-A2-140	A2
362	\N	600	\N	A04-A2-134	A2
363	\N	600	\N	A04-A2-128	A2
364	\N	400	\N	A04-A2-124	A2
365	\N	602	\N	A04-A2-118	A2
366	\N	476	\N	A04-A2-113	A2
367	\N	491	\N	A04-A2-108	A2
368	\N	1270	\N	A03-A2-96	A2
369	\N	923	\N	A03-A2-86	A2
370	\N	630	\N	A03-A2-80	A2
371	\N	406	\N	A03-A2-76	A2
372	\N	226	\N	A03-A2-74	A2
373	\N	10	\N	A03-3BTU	A2
374	\N	82	\N	A03-3BTN	A2
375	\N	10	\N	A03-1BTN	A2
376	\N	82	\N	A03-1BTU	A2
377	\N	97	\N	A03-A2-71	A2
378	\N	600	\N	A03-A2-65	A2
379	\N	400	\N	A03-A2-61	A2
380	\N	269	\N	A03-A2-59	A2
381	\N	240	\N	A02-A2-56	A2
382	\N	10	\N	A02-7TU	A2
383	\N	136	\N	A02-7TN	A2
384	\N	363	\N	A02-A2-51	A2
385	\N	338	\N	A02-A2-47	A2
386	\N	10	\N	A02-11BTN	A2
387	\N	208	\N	A02-11BTU	A2
388	\N	59	\N	A02-A2-44	A2
389	\N	600	\N	A02-A2-38	A2
390	\N	81	\N	A02-A2-37	A2
391	\N	10	\N	A02-13TU	A2
392	\N	81	\N	A02-13TN	A2
393	\N	224	\N	A02-A2-34	A2
394	\N	239	\N	A01-A2-31	A2
395	\N	278	\N	A01-A2-29	A2
396	\N	638	\N	A01-A2-22	A2
397	\N	842	\N	A01-A2-14	A2
398	\N	381	\N	A01-A2-10	A2
399	\N	291	\N	A01-A2-7	A2
400	\N	414	\N	A01-A2-3	A2
462	\N	221	\N	A01-B1-3	B1
463	\N	275	\N	A01-B1-5	B1
464	\N	266	\N	B01-B1-8	B1
465	\N	58	\N	B01-B1-10	B1
466	\N	85	\N	B01-B1-11	B1
467	\N	600	\N	B01-B1-12	B1
468	\N	293	\N	B01-B1-18	B1
469	\N	311	\N	B02-B1-21	B1
470	\N	262	\N	B02-B1-24	B1
471	\N	243	\N	B02-B1-27	B1
472	\N	10	\N	B02-1ATU	B1
473	\N	10	\N	B02-1ATN	B1
474	\N	10	\N	B02-3ATN	B1
475	\N	63	\N	B02-3ATU	B1
476	\N	73	\N	B02-B1-31	B1
477	\N	600	\N	B02-B1-32	B1
478	\N	451	\N	B02-B1-38	B1
479	\N	261	\N	B02-B1-42	B1
480	\N	428	\N	B02-B1-45	B1
481	\N	545	\N	B02-B1-49	B1
482	\N	545	\N	B03-B1-55	B1
483	\N	546	\N	B03-B1-60	B1
484	\N	70	\N	B03-B1-65	B1
485	\N	600	\N	B03-B1-66	B1
486	\N	545	\N	B03-B1-72	B1
487	\N	500	\N	B03-B1-78	B1
488	\N	471	\N	B03-B1-82	B1
489	\N	10	\N	B03-1ATU	B1
490	\N	116	\N	B03-1ATN	B1
491	\N	10	\N	B03-3ATN	B1
492	\N	117	\N	B03-3ATU	B1
493	\N	399	\N	B35-B1-90	B1
494	\N	530	\N	B35-B1-94	B1
495	\N	255	\N	B35-B1-99	B1
496	\N	600	\N	B35-B1-102	B1
497	\N	193	\N	B35-B1-108	B1
498	\N	494	\N	B35-B1-110	B1
499	\N	10	\N	B99-7ATU	B1
500	\N	190	\N	B99-7ATN	B1
501	\N	580	\N	B99-B1-116	B1
502	\N	107	\N	B99-B1-122	B1
503	\N	10	\N	B99-17ATU	B1
504	\N	187	\N	B99-17ATN	B1
505	\N	399	\N	B99-B1-125	B1
506	\N	10	\N	B99-27ATN	B1
507	\N	194	\N	B99-27ATU	B1
508	\N	906	\N	B99-B1-131	B1
509	\N	412	\N	B99-B1-140	B1
510	\N	362	\N	B99-B1-144	B1
511	\N	609	\N	B99-B1-148	B1
512	\N	508	\N	B04-B1-154	B1
513	\N	600	\N	B04-B1-159	B1
514	\N	404	\N	B04-B1-165	B1
515	\N	438	\N	B04-B1-169	B1
516	\N	142	\N	B04-B1-174	B1
517	\N	10	\N	B04-1ATU	B1
518	\N	10	\N	B04-1ATN	B1
519	\N	10	\N	B04-3ATN	B1
520	\N	62	\N	B04-3ATU	B1
521	\N	598	\N	B04-B1-177	B1
522	\N	439	\N	B04-B1-183	B1
523	\N	534	\N	B04-B1-187	B1
524	\N	307	\N	B05-B1-193	B1
525	\N	369	\N	B05-B1-196	B1
526	\N	538	\N	B05-B1-199	B1
527	\N	600	\N	B05-B1-205	B1
528	\N	147	\N	B05-B1-210	B1
529	\N	510	\N	B05-B1-212	B1
530	\N	391	\N	B05-B1-217	B1
531	\N	619	\N	B05-B1-221	B1
532	\N	656	\N	B05-B1-227	B1
533	\N	1118	\N	B05-B1-234	B1
534	\N	525	\N	B06-B1-245	B1
535	\N	362	\N	B06-B1-250	B1
536	\N	10	\N	B06-1ATU	B1
537	\N	196	\N	B06-1ATN	B1
538	\N	240	\N	B06-1ABT	B1
539	\N	10	\N	B06-3ATN	B1
540	\N	10	\N	B06-3ATU	B1
541	\N	10	\N	B06-5ATU	B1
542	\N	202	\N	B06-5ATN	B1
543	\N	144	\N	B06-5ABT	B1
544	\N	435	\N	B06-B1-262	B1
545	\N	500	\N	B06-B1-266	B1
546	\N	411	\N	B06-B1-271	B1
547	\N	50	\N	B06-B1-275	B1
548	\N	600	\N	B06-B1-276	B1
549	\N	624	\N	B06-B1-282	B1
550	\N	370	\N	B06-B1-287	B1
551	\N	380	\N	B06-B1-292	B1
552	\N	587	\N	B06-B1-296	B1
553	\N	1034	\N	B06-B1-301	B1
554	\N	822	\N	B06-B1-312	B1
555	\N	823	\N	B06-B1-320	B1
556	\N	802	\N	B07-B1-328	B1
557	\N	803	\N	B07-B1-336	B1
558	\N	623	\N	B07-B1-344	B1
559	\N	90	\N	B07-3ABT	B1
560	\N	10	\N	B07-3ATN	B1
561	\N	85	\N	B07-3ATU	B1
562	\N	10	\N	B07-1ATU	B1
563	\N	86	\N	B07-1ATN	B1
564	\N	89	\N	B07-1ABT	B1
565	\N	630	\N	B07-B1-354	B1
566	\N	358	\N	B07-B1-361	B1
567	\N	370	\N	B07-B1-364	B1
568	\N	341	\N	B07-B1-368	B1
569	\N	314	\N	B07-B1-371	B1
570	\N	175	\N	B07-B1-374	B1
571	\N	600	\N	B07-B1-376	B1
572	\N	443	\N	B07-B1-382	B1
573	\N	271	\N	B07-B1-387	B1
574	\N	325	\N	B07-B1-389	B1
575	\N	751	\N	B07-B1-393	B1
576	\N	888	\N	B07-B1-400	B1
577	\N	715	\N	B08-B1-409	B1
578	\N	894	\N	B08-B1-416	B1
579	\N	486	\N	B08-B1-425	B1
580	\N	231	\N	B08-B1-430	B1
581	\N	350	\N	B08-B1-432	B1
582	\N	336	\N	B08-B1-436	B1
583	\N	119	\N	B08-B1-439	B1
584	\N	10	\N	B08-1ATU	B1
585	\N	195	\N	B08-1ATN	B1
586	\N	277	\N	B08-1ABT	B1
587	\N	277	\N	B08-3ABT	B1
588	\N	10	\N	B08-3ATN	B1
589	\N	195	\N	B08-3ATU	B1
590	\N	110	\N	B08-B1-450	B1
591	\N	600	\N	B08-B1-451	B1
592	\N	39	\N	B08-B1-457	B1
593	\N	10	\N	B08-5ATU	B1
594	\N	134	\N	B08-5ATN	B1
595	\N	182	\N	B08-5ABT	B1
596	\N	684	\N	B08-B1-461	B1
597	\N	99	\N	B08-9ABT	B1
598	\N	10	\N	B08-9TN	B1
599	\N	145	\N	B08-9TU	B1
600	\N	585	\N	B08-B1-470	B1
601	\N	1195	\N	B08-B1-476	B1
602	\N	456	\N	B08-B1-488	B1
603	\N	558	\N	B08-B1-493	B1
604	\N	1142	\N	B09-B1-499	B1
605	\N	1195	\N	B09-B1-510	B1
606	\N	605	\N	B09-B1-522	B1
607	\N	350	\N	B09-B1-528	B1
608	\N	195	\N	B09-B1-532	B1
609	\N	255	\N	B09-B1-533	B1
610	\N	420	\N	B09-B1-536	B1
611	\N	600	\N	B09-B1-540	B1
612	\N	350	\N	B09-B1-546	B1
613	\N	240	\N	B09-B1-550	B1
614	\N	397	\N	B09-B1-552	B1
615	\N	573	\N	B09-B1-556	B1
616	\N	10	\N	B09-1ATU	B1
617	\N	119	\N	B09-1ATN	B1
618	\N	10	\N	B09-3ATN	B1
619	\N	198	\N	B09-3ATU	B1
620	\N	605	\N	B09-B1-566	B1
621	\N	1514	\N	B09-B1-572	B1
622	\N	786	\N	B09-B1-587	B1
623	\N	1260	\N	B10-B1-595	B1
624	\N	340	\N	B10-B1-608	B1
625	\N	510	\N	B10-B1-611	B1
626	\N	230	\N	B10-B1-616	B1
627	\N	360	\N	B10-B1-618	B1
628	\N	382	\N	B10-B1-622	B1
629	\N	600	\N	B10-B1-626	B1
630	\N	96	\N	B10-B1-632	B1
631	\N	10	\N	B10-1ATU	B1
632	\N	226	\N	B10-1ATN	B1
633	\N	10	\N	B10-3ATN	B1
634	\N	232	\N	B10-3ATU	B1
635	\N	647	\N	B10-B1-638	B1
636	\N	380	\N	B10-B1-644	B1
637	\N	605	\N	B10-B1-648	B1
638	\N	740	\N	B10-B1-654	B1
639	\N	741	\N	B10-B1-661	B1
640	\N	741	\N	B10-B1-669	B1
641	\N	693	\N	B11-B1-676	B1
642	\N	741	\N	B11-B1-683	B1
643	\N	716	\N	B11-B1-690	B1
644	\N	803	\N	B11-B1-698	B1
645	\N	540	\N	B11-B1-706	B1
646	\N	355	\N	B11-B1-711	B1
647	\N	10	\N	B11-1ATU	B1
648	\N	192	\N	B11-1ATN	B1
649	\N	10	\N	B11-3ATN	B1
650	\N	191	\N	B11-3ATU	B1
651	\N	55	\N	B11-B1-718	B1
652	\N	600	\N	B11-B1-719	B1
653	\N	248	\N	B11-32T	B1
654	\N	120	\N	B11-7ABT	B1
655	\N	10	\N	B11-7ATN	B1
656	\N	110	\N	B11-7ATU	B1
657	\N	10	\N	B11-5ATU	B1
658	\N	120	\N	B11-5ATN	B1
659	\N	120	\N	B11-5ABT	B1
661	\N	600	\N	A01-B2-2	B2
662	\N	130	\N	A01-B2-3	B2
663	\N	133	\N	A01-B2-4	B2
664	\N	226	\N	B01-B2-6	B2
665	\N	273	\N	B01-B2-8	B2
666	\N	143	\N	B01-B2-11	B2
667	\N	600	\N	B01-B2-16	B2
668	\N	244	\N	B02-B2-18	B2
669	\N	310	\N	B02-B2-20	B2
670	\N	275	\N	B02-B2-24	B2
671	\N	291	\N	B02-B2-26	B2
672	\N	10	\N	B02-3BTU	B2
673	\N	10	\N	B02-3BTN	B2
674	\N	10	\N	B02-1BTN	B2
675	\N	63	\N	B02-1BTU	B2
676	\N	73	\N	B02-B2-31	B2
677	\N	600	\N	B02-B2-32	B2
678	\N	335	\N	B02-B2-38	B2
679	\N	735	\N	B02-B2-42	B2
680	\N	445	\N	B03-B2-49	B2
681	\N	414	\N	B03-B2-54	B2
682	\N	321	\N	B03-B2-58	B2
683	\N	236	\N	B03-B2-61	B2
684	\N	174	\N	B03-B2-63	B2
685	\N	73	\N	B03-B2-65	B2
686	\N	600	\N	B03-B2-69	B2
687	\N	50	\N	B03-B2-72	B2
688	\N	443	\N	B03-B2-73	B2
689	\N	228	\N	B03-B2-77	B2
690	\N	338	\N	B03-B2-79	B2
691	\N	192	\N	B03-B2-83	B2
692	\N	271	\N	B03-B2-85	B2
693	\N	10	\N	B03-3BTU	B2
694	\N	116	\N	B03-3BTN	B2
695	\N	10	\N	B03-1BTN	B2
696	\N	117	\N	B03-1BTU	B2
697	\N	207	\N	B35-B2-90	B2
698	\N	350	\N	B35-B2-92	B2
699	\N	625	\N	B35-B2-95	B2
700	\N	600	\N	B35-B2-102	B2
701	\N	253	\N	B35-B2-108	B2
702	\N	350	\N	B35-B2-110	B2
703	\N	247	\N	B99-B2-114	B2
704	\N	10	\N	B99-11ATU	B2
705	\N	205	\N	B99-11ATN	B2
706	\N	506	\N	B99-B2-118	B2
707	\N	656	\N	B99-B2-123	B2
708	\N	10	\N	B99-37ATU	B2
709	\N	187	\N	B99-37ATN	B2
710	\N	320	\N	B99-B2-132	B2
711	\N	10	\N	B99-45ATN	B2
712	\N	185	\N	B99-45ATU	B2
713	\N	980	\N	B99-B2-137	B2
714	\N	250	\N	B99-B2-147	B2
715	\N	546	\N	B04-B2-149	B2
716	\N	311	\N	B04-B2-155	B2
717	\N	600	\N	B04-B2-162	B2
718	\N	350	\N	B04-B2-165	B2
719	\N	302	\N	B04-B2-169	B2
720	\N	332	\N	B04-B2-172	B2
721	\N	10	\N	B04-3BTU	B2
722	\N	10	\N	B04-3BTN	B2
723	\N	10	\N	B04-1BTN	B2
724	\N	62	\N	B04-1BTU	B2
725	\N	580	\N	B04-B2-177	B2
726	\N	582	\N	B04-B2-183	B2
727	\N	409	\N	B05-B2-189	B2
728	\N	426	\N	B05-B2-193	B2
729	\N	385	\N	B05-B2-197	B2
730	\N	403	\N	B05-B2-201	B2
731	\N	600	\N	B05-B2-208	B2
732	\N	50	\N	B05-B2-210	B2
733	\N	177	\N	B05-B2-211	B2
734	\N	166	\N	B05-B2-213	B2
735	\N	264	\N	B05-B2-215	B2
736	\N	345	\N	B05-B2-217	B2
737	\N	398	\N	B05-B2-221	B2
738	\N	282	\N	B05-B2-225	B2
739	\N	347	\N	B05-B2-228	B2
740	\N	284	\N	B05-B2-231	B2
741	\N	388	\N	B06-B2-234	B2
742	\N	1255	\N	B06-B2-237	B2
743	\N	528	\N	B06-B2-250	B2
744	\N	52	\N	B06-1BBT	B2
745	\N	10	\N	B06-1BTN	B2
746	\N	10	\N	B06-1BTU	B2
747	\N	10	\N	B06-3BTU	B2
748	\N	240	\N	B06-3BTN	B2
749	\N	10	\N	B06-7TU	B2
750	\N	162	\N	B06-7TN	B2
751	\N	162	\N	B06-7BT	B2
752	\N	343	\N	B06-B2-262	B2
753	\N	313	\N	B06-B2-265	B2
754	\N	239	\N	B06-B2-268	B2
755	\N	263	\N	B06-B2-271	B2
756	\N	238	\N	B06-B2-273	B2
757	\N	600	\N	B06-B2-279	B2
758	\N	50	\N	B06-B2-281	B2
759	\N	199	\N	B06-B2-282	B2
760	\N	305	\N	B06-B2-284	B2
761	\N	195	\N	B06-B2-287	B2
762	\N	261	\N	B06-B2-289	B2
763	\N	193	\N	B06-B2-292	B2
764	\N	171	\N	B06-B2-294	B2
765	\N	279	\N	B06-B2-296	B2
766	\N	243	\N	B06-B2-298	B2
767	\N	361	\N	B06-B2-301	B2
768	\N	738	\N	B06-B2-304	B2
769	\N	991	\N	B06-B2-312	B2
770	\N	654	\N	B07-B2-322	B2
771	\N	802	\N	B07-B2-328	B2
772	\N	803	\N	B07-B2-336	B2
773	\N	625	\N	B07-B2-344	B2
774	\N	10	\N	B07-3BTU	B2
775	\N	173	\N	B07-3BTN	B2
776	\N	10	\N	B07-1BTN	B2
777	\N	173	\N	B07-1BTU	B2
778	\N	645	\N	B07-B2-354	B2
779	\N	513	\N	B07-B2-361	B2
780	\N	250	\N	B07-B2-366	B2
781	\N	246	\N	B07-B2-368	B2
782	\N	175	\N	B07-B2-371	B2
783	\N	179	\N	B07-B2-372	B2
784	\N	201	\N	B07-B2-374	B2
785	\N	600	\N	B07-B2-379	B2
786	\N	50	\N	B07-B2-382	B2
787	\N	159	\N	B07-B2-383	B2
788	\N	327	\N	B07-B2-384	B2
789	\N	253	\N	B07-B2-387	B2
790	\N	250	\N	B07-B2-390	B2
791	\N	185	\N	B07-B2-393	B2
792	\N	191	\N	B07-B2-394	B2
793	\N	217	\N	B07-B2-396	B2
794	\N	293	\N	B07-B2-398	B2
795	\N	301	\N	B07-B2-401	B2
796	\N	452	\N	B08-B2-404	B2
797	\N	359	\N	B08-B2-409	B2
798	\N	1250	\N	B08-B2-413	B2
799	\N	1042	\N	B08-B2-425	B2
800	\N	485	\N	B08-B2-435	B2
801	\N	308	\N	B08-B2-440	B2
802	\N	82	\N	B08-1BBT	B2
803	\N	10	\N	B08-1BTN	B2
804	\N	76	\N	B08-1BTU	B2
805	\N	10	\N	B08-3BTU	B2
806	\N	76	\N	B08-3BTN	B2
807	\N	82	\N	B08-3BBT	B2
808	\N	426	\N	B08-B2-447	B2
809	\N	600	\N	B08-B2-451	B2
810	\N	115	\N	B08-B2-457	B2
811	\N	10	\N	B08-7TU	B2
812	\N	140	\N	B08-7TN	B2
813	\N	112	\N	B08-7ABT	B2
814	\N	676	\N	B08-B2-461	B2
815	\N	185	\N	B08-11BBT	B2
816	\N	10	\N	B08-11BTN	B2
817	\N	147	\N	B08-11BTU	B2
818	\N	894	\N	B08-B2-471	B2
819	\N	798	\N	B08-B2-480	B2
820	\N	456	\N	B08-B2-488	B2
821	\N	558	\N	B09-B2-493	B2
822	\N	1142	\N	B09-B2-499	B2
823	\N	1300	\N	B09-B2-510	B2
824	\N	640	\N	B09-B2-523	B2
825	\N	410	\N	B09-B2-529	B2
826	\N	300	\N	B09-B2-534	B2
827	\N	394	\N	B09-B2-537	B2
828	\N	600	\N	B09-B2-540	B2
829	\N	406	\N	B09-B2-546	B2
830	\N	260	\N	B09-B2-551	B2
831	\N	297	\N	B09-B2-553	B2
832	\N	393	\N	B09-B2-556	B2
833	\N	204	\N	B09-B2-560	B2
834	\N	10	\N	B09-3BTU	B2
835	\N	129	\N	B09-3BTN	B2
836	\N	10	\N	B09-1BTN	B2
837	\N	187	\N	B09-1BTU	B2
838	\N	605	\N	B09-B2-566	B2
839	\N	1514	\N	B09-B2-572	B2
840	\N	1486	\N	B10-B2-587	B2
841	\N	542	\N	B10-B2-602	B2
842	\N	633	\N	B10-B2-607	B2
843	\N	425	\N	B10-B2-614	B2
844	\N	400	\N	B10-B2-618	B2
845	\N	383	\N	B10-B2-622	B2
846	\N	600	\N	B10-B2-626	B2
847	\N	96	\N	B10-B2-632	B2
848	\N	10	\N	B10-3BTU	B2
849	\N	226	\N	B10-3BTN	B2
850	\N	10	\N	B10-1BTN	B2
851	\N	232	\N	B10-1BTU	B2
852	\N	647	\N	B10-B2-638	B2
853	\N	420	\N	B10-B2-644	B2
854	\N	565	\N	B10-B2-648	B2
855	\N	749	\N	B10-B2-654	B2
856	\N	741	\N	B10-B2-661	B2
857	\N	741	\N	B11-B2-669	B2
858	\N	718	\N	B11-B2-676	B2
859	\N	723	\N	B11-B2-683	B2
860	\N	716	\N	B11-B2-690	B2
861	\N	803	\N	B11-B2-698	B2
862	\N	858	\N	B11-B2-706	B2
863	\N	10	\N	B11-3BTU	B2
864	\N	192	\N	B11-3BTN	B2
865	\N	10	\N	B11-1BTN	B2
866	\N	192	\N	B11-1BTU	B2
867	\N	55	\N	B11-B2-718	B2
868	\N	600	\N	B11-B2-719	B2
869	\N	248	\N	B11-B2-725	B2
870	\N	10	\N	B11-7BTU	B2
871	\N	109	\N	B11-7BTN	B2
872	\N	120	\N	B11-7BBT	B2
873	\N	120	\N	B11-5BBT	B2
874	\N	10	\N	B11-5BTN	B2
875	\N	120	\N	B11-5BTU	B2
943	\N	841	\N	C15-C1-629	C1
944	\N	600	\N	C15-C1-623	C1
945	\N	53	\N	C15-C1-622	C1
946	\N	10	\N	C15-1ATU	C1
947	\N	193	\N	C15-1ATN	C1
948	\N	10	\N	C15-3ATN	C1
949	\N	193	\N	C15-3ATU	C1
950	\N	154	\N	C15-C1-617	C1
951	\N	407	\N	C15-C1-613	C1
952	\N	310	\N	C15-C1-609	C1
953	\N	430	\N	C15-C1-605	C1
954	\N	410	\N	C14-C1-601	C1
955	\N	600	\N	C14-C1-599	C1
956	\N	225	\N	C14-C1-593	C1
957	\N	10	\N	C14-1TU	C1
958	\N	77	\N	C14-1TN	C1
959	\N	87	\N	C14-1ABT	C1
960	\N	505	\N	C14-C1-586	C1
961	\N	428	\N	C14-C1-582	C1
962	\N	552	\N	C14-C1-576	C1
963	\N	165	\N	C97-C1-574	C1
964	\N	151	\N	C97-1ABT	C1
965	\N	10	\N	C97-1TN	C1
966	\N	141	\N	C97-1TU	C1
967	\N	598	\N	C97-C1-566	C1
968	\N	185	\N	C97-C1-564	C1
969	\N	600	\N	C13-C1-558	C1
970	\N	580	\N	C13-C1-552	C1
971	\N	657	\N	C13-C1-546	C1
972	\N	175	\N	C12-C1-544	C1
973	\N	525	\N	C12-C1-539	C1
974	\N	300	\N	C12-C1-536	C1
975	\N	616	\N	C12-C1-529	C1
976	\N	600	\N	C12-C1-523	C1
977	\N	52	\N	C12-C1-522	C1
978	\N	10	\N	C12-1ATU	C1
979	\N	161	\N	C12-1ATN	C1
980	\N	10	\N	C12-3ATN	C1
981	\N	161	\N	C12-3ATU	C1
982	\N	765	\N	C12-C1-512	C1
983	\N	785	\N	C12-C1-504	C1
984	\N	608	\N	C12-C1-498	C1
985	\N	1328	\N	C12-C1-485	C1
991	\N	240	\N	C11-C1-456	C1
995	\N	408	\N	C11-C1-425	C1
996	\N	959	\N	C11-C1-415	C1
997	\N	971	\N	C10-C1-405	C1
998	\N	815	\N	C10-C1-397	C1
999	\N	815	\N	C10-C1-389	C1
1000	\N	158	\N	C10-C1-387	C1
1001	\N	586	\N	C10-C1-382	C1
1002	\N	266	\N	C10-C1-379	C1
1003	\N	291	\N	C10-C1-376	C1
1004	\N	290	\N	C10-C1-373	C1
1005	\N	191	\N	C10-C1-372	C1
1006	\N	10	\N	C10-5ATU	C1
1007	\N	125	\N	C10-5ATN	C1
1008	\N	112	\N	C10-5ABT	C1
1009	\N	63	\N	C10-C1-368	C1
1010	\N	600	\N	C10-C1-367	C1
1011	\N	63	\N	C10-C1-361	C1
1012	\N	112	\N	C10-9ABT	C1
1013	\N	10	\N	C10-9TN	C1
1014	\N	125	\N	C10-9TU	C1
1015	\N	149	\N	C10-C1-358	C1
1016	\N	191	\N	C10-C1-356	C1
1017	\N	117	\N	C10-C1-355	C1
1018	\N	178	\N	C10-C1-353	C1
1019	\N	275	\N	C10-C1-349	C1
1020	\N	187	\N	C10-C1-347	C1
1021	\N	337	\N	C10-C1-343	C1
1022	\N	424	\N	C10-C1-339	C1
1023	\N	171	\N	C09-C1-337	C1
1024	\N	600	\N	C09-C1-336	C1
1025	\N	431	\N	C09-C1-327	C1
1026	\N	485	\N	C09-C1-322	C1
1027	\N	501	\N	C09-C1-317	C1
1028	\N	508	\N	C09-C1-312	C1
1029	\N	455	\N	C09-C1-308	C1
1030	\N	200	\N	C08-C1-306	C1
1031	\N	196	\N	C08-C1-304	C1
1032	\N	264	\N	C08-C1-301	C1
1033	\N	180	\N	C08-C1-299	C1
1034	\N	198	\N	C08-C1-297	C1
1035	\N	50	\N	C08-C1-296	C1
1036	\N	600	\N	C08-C1-295	C1
1037	\N	73	\N	C08-C1-290	C1
1038	\N	10	\N	C08-1ATU	C1
1039	\N	81	\N	C08-1ATN	C1
1040	\N	10	\N	C08-3ATN	C1
1041	\N	81	\N	C08-3ATU	C1
1042	\N	237	\N	C08-C1-286	C1
1043	\N	255	\N	C08-C1-283	C1
1044	\N	306	\N	C08-C1-280	C1
1045	\N	237	\N	C08-C1-278	C1
1046	\N	196	\N	C08-C1-276	C1
1047	\N	248	\N	C08-C1-273	C1
1048	\N	276	\N	C08-C1-270	C1
1049	\N	310	\N	C07-C1-267	C1
1050	\N	235	\N	C07-C1-266	C1
1051	\N	61	\N	C07-C1-264	C1
1052	\N	600	\N	C07-C1-262	C1
1053	\N	59	\N	C07-C1-257	C1
1054	\N	10	\N	C07-1TU	C1
1055	\N	128	\N	C07-1TN	C1
1056	\N	117	\N	C07-1ABT	C1
1057	\N	337	\N	C07-C1-252	C1
1058	\N	232	\N	C07-C1-250	C1
1059	\N	266	\N	C07-C1-247	C1
1060	\N	726	\N	C07-C1-240	C1
1061	\N	1219	\N	C07-C1-228	C1
1062	\N	998	\N	C07-C1-218	C1
1063	\N	671	\N	C06-C1-211	C1
1064	\N	254	\N	C06-C1-209	C1
1065	\N	348	\N	C06-C1-205	C1
1066	\N	242	\N	C06-C1-203	C1
1067	\N	292	\N	C06-C1-200	C1
1068	\N	293	\N	C06-C1-197	C1
1069	\N	265	\N	C06-C1-194	C1
1070	\N	600	\N	C06-C1-192	C1
1071	\N	59	\N	C06-C1-187	C1
1072	\N	10	\N	C06-1ATU	C1
1073	\N	82	\N	C06-1ATN	C1
1074	\N	10	\N	C06-3ATN	C1
1075	\N	81	\N	C06-3ATU	C1
1076	\N	295	\N	C06-C1-183	C1
1077	\N	299	\N	C06-C1-180	C1
1078	\N	227	\N	C06-C1-178	C1
1079	\N	482	\N	C06-C1-173	C1
1080	\N	245	\N	C06-C1-171	C1
1081	\N	750	\N	C06-C1-163	C1
1082	\N	331	\N	C06-C1-159	C1
1083	\N	247	\N	C06-C1-157	C1
1084	\N	278	\N	C06-C1-154	C1
1085	\N	172	\N	C06-C1-152	C1
1086	\N	203	\N	C06-C1-150	C1
1087	\N	210	\N	C05-C1-148	C1
1088	\N	136	\N	C05-1ABT	C1
1089	\N	10	\N	C05-1TN	C1
1090	\N	128	\N	C05-1TU	C1
1091	\N	81	\N	C05-C1-145	C1
1092	\N	600	\N	C05-C1-143	C1
1093	\N	180	\N	C05-C1-136	C1
1094	\N	328	\N	C05-C1-134	C1
1095	\N	376	\N	C05-C1-131	C1
1096	\N	136	\N	C05-C1-128	C1
1097	\N	797	\N	C05-C1-120	C1
1098	\N	863	\N	C05-C1-111	C1
1099	\N	825	\N	C05-C1-103	C1
1100	\N	826	\N	C04-C1-95	C1
1101	\N	548	\N	C04-C1-89	C1
1102	\N	768	\N	C04-C1-82	C1
1103	\N	479	\N	C04-C1-77	C1
1104	\N	267	\N	C04-C1-74	C1
1105	\N	600	\N	C04-C1-68	C1
1106	\N	59	\N	C04-C1-67	C1
1107	\N	10	\N	C04-1ATU	C1
1108	\N	148	\N	C04-1ATN	C1
1109	\N	10	\N	C04-3ATN	C1
1110	\N	149	\N	C04-3ATU	C1
1111	\N	295	\N	C04-C1-62	C1
1112	\N	310	\N	C04-C1-59	C1
1113	\N	320	\N	C04-C1-55	C1
1114	\N	308	\N	C04-C1-52	C1
1115	\N	344	\N	C04-C1-49	C1
1116	\N	230	\N	C03-C1-47	C1
1117	\N	600	\N	C03-C1-44	C1
1118	\N	425	\N	C03-C1-36	C1
1119	\N	293	\N	C02-C1-33	C1
1120	\N	375	\N	C02-C1-30	C1
1121	\N	10	\N	C02-1ATU	C1
1122	\N	82	\N	C02-1ATN	C1
1123	\N	10	\N	C02-3ATN	C1
1124	\N	82	\N	C02-3ATU	C1
1125	\N	124	\N	C02-C1-27	C1
1126	\N	600	\N	C02-C1-24	C1
1127	\N	261	\N	C02-C1-18	C1
1128	\N	178	\N	C02-C1-15	C1
1129	\N	254	\N	C02-C1-13	C1
1130	\N	327	\N	C02-C1-10	C1
1131	\N	168	\N	C01-C1-8	C1
1132	\N	236	\N	C01-C1-6	C1
1133	\N	167	\N	C01-C1-4	C1
1134	\N	168	\N	C01-C1-2	C1
1135	\N	600	\N	C01-C1-1	C1
1136	\N	841	\N	C15-C2-629	C2
1137	\N	600	\N	C15-C2-623	C2
1138	\N	53	\N	C15-C2-622	C2
1139	\N	10	\N	C15-3BTU	C2
1140	\N	193	\N	C15-3BTN	C2
1141	\N	10	\N	C15-1BTN	C2
1142	\N	193	\N	C15-1BTU	C2
1143	\N	174	\N	C15-C2-617	C2
1144	\N	311	\N	C15-C2-613	C2
1145	\N	419	\N	C15-C2-609	C2
1146	\N	275	\N	C14-C2-607	C2
1147	\N	550	\N	C14-C2-601	C2
1148	\N	600	\N	C14-C2-595	C2
1149	\N	225	\N	C14-C2-593	C2
1150	\N	10	\N	C14-3TU	C2
1151	\N	77	\N	C14-3TN	C2
1152	\N	88	\N	C14-3ABT	C2
1153	\N	320	\N	C14-C2-587	C2
1154	\N	495	\N	C14-C2-582	C2
1155	\N	423	\N	C97-C2-578	C2
1156	\N	369	\N	C97-C2-574	C2
1157	\N	151	\N	C97-3ABT	C2
1158	\N	10	\N	C97-3TN	C2
1159	\N	141	\N	C97-3TU	C2
1160	\N	455	\N	C97-C2-567	C2
1161	\N	316	\N	C13-C2-564	C2
1162	\N	600	\N	C13-C2-562	C2
1163	\N	354	\N	C13-C2-554	C2
1164	\N	461	\N	C13-C2-550	C2
1165	\N	586	\N	C12-C2-544	C2
1166	\N	310	\N	C12-C2-541	C2
1167	\N	365	\N	C12-C2-537	C2
1168	\N	317	\N	C12-C2-534	C2
1169	\N	450	\N	C12-C2-529	C2
1170	\N	600	\N	C12-C2-523	C2
1171	\N	52	\N	C12-C2-522	C2
1172	\N	10	\N	C12-3BTU	C2
1173	\N	161	\N	C12-3BTN	C2
1174	\N	10	\N	C12-1BTN	C2
1175	\N	161	\N	C12-1BTU	C2
1176	\N	322	\N	C12-C2-516	C2
1177	\N	308	\N	C12-C2-513	C2
1178	\N	415	\N	C12-C2-509	C2
1179	\N	505	\N	C12-C2-504	C2
1180	\N	964	\N	C12-C2-494	C2
1181	\N	965	\N	C11-C2-485	C2
1182	\N	695	\N	C11-C2-478	C2
1187	\N	240	\N	C11-C2-456	C2
1193	\N	1374	\N	C10-C2-411	C2
1194	\N	579	\N	C10-C2-405	C2
1195	\N	894	\N	C10-C2-396	C2
1196	\N	894	\N	C10-C2-387	C2
1197	\N	971	\N	C10-C2-378	C2
1198	\N	291	\N	C10-C2-375	C2
1199	\N	304	\N	C10-C2-372	C2
1200	\N	10	\N	C10-7TU	C2
1201	\N	125	\N	C10-7TN	C2
1202	\N	112	\N	C10-7ABT	C2
1203	\N	63	\N	C10-C2-368	C2
1204	\N	600	\N	C10-C2-362	C2
1205	\N	63	\N	C10-C2-361	C2
1206	\N	112	\N	C10-11BBT	C2
1207	\N	10	\N	C10-11BTN	C2
1208	\N	125	\N	C10-11BTU	C2
1209	\N	131	\N	C10-C2-358	C2
1210	\N	261	\N	C10-C2-355	C2
1211	\N	292	\N	C10-C2-353	C2
1212	\N	386	\N	C10-C2-347	C2
1213	\N	237	\N	C10-C2-344	C2
1214	\N	205	\N	C10-C2-342	C2
1215	\N	222	\N	C09-C2-340	C2
1216	\N	268	\N	C09-C2-337	C2
1217	\N	600	\N	C09-C2-331	C2
1218	\N	81	\N	C09-C2-330	C2
1219	\N	207	\N	C09-C2-329	C2
1220	\N	294	\N	C09-C2-326	C2
1221	\N	290	\N	C09-C2-323	C2
1222	\N	250	\N	C09-C2-320	C2
1223	\N	295	\N	C09-C2-317	C2
1224	\N	444	\N	C09-C2-313	C2
1225	\N	655	\N	C08-C2-306	C2
1226	\N	189	\N	C08-C2-304	C2
1227	\N	217	\N	C08-C2-302	C2
1228	\N	247	\N	C08-C2-300	C2
1229	\N	299	\N	C08-C2-297	C2
1230	\N	600	\N	C08-C2-291	C2
1231	\N	73	\N	C08-C2-290	C2
1232	\N	10	\N	C08-3BTU	C2
1233	\N	82	\N	C08-3BTN	C2
1234	\N	10	\N	C08-1BTN	C2
1235	\N	81	\N	C08-1BTU	C2
1236	\N	247	\N	C08-C2-286	C2
1237	\N	262	\N	C08-C2-283	C2
1238	\N	182	\N	C08-C2-281	C2
1239	\N	184	\N	C08-C2-279	C2
1240	\N	180	\N	C08-C2-278	C2
1241	\N	148	\N	C08-C2-276	C2
1242	\N	421	\N	C07-C2-272	C2
1243	\N	418	\N	C07-C2-267	C2
1244	\N	280	\N	C07-C2-266	C2
1245	\N	59	\N	C07-C2-264	C2
1246	\N	600	\N	C07-C2-258	C2
1247	\N	60	\N	C07-C2-257	C2
1248	\N	10	\N	C07-3TU	C2
1249	\N	40	\N	C07-3TN	C2
1250	\N	150	\N	C07-3ABT	C2
1251	\N	300	\N	C07-C2-251	C2
1252	\N	296	\N	C07-C2-249	C2
1253	\N	246	\N	C07-C2-246	C2
1254	\N	144	\N	C07-C2-245	C2
1255	\N	453	\N	C07-C2-240	C2
1256	\N	570	\N	C07-C2-234	C2
1257	\N	997	\N	C06-C2-224	C2
1258	\N	651	\N	C06-C2-218	C2
1259	\N	739	\N	C06-C2-211	C2
1260	\N	740	\N	C06-C2-203	C2
1261	\N	258	\N	C06-C2-201	C2
1262	\N	266	\N	C06-C2-198	C2
1263	\N	258	\N	C06-C2-195	C2
1264	\N	102	\N	C06-C2-194	C2
1265	\N	600	\N	C06-C2-188	C2
1266	\N	59	\N	C06-C2-187	C2
1267	\N	10	\N	C06-3BTU	C2
1268	\N	82	\N	C06-3BTN	C2
1269	\N	10	\N	C06-1BTN	C2
1270	\N	81	\N	C06-1BTU	C2
1271	\N	266	\N	C06-C2-183	C2
1272	\N	265	\N	C06-C2-181	C2
1273	\N	252	\N	C06-C2-178	C2
1274	\N	252	\N	C06-C2-176	C2
1275	\N	252	\N	C06-C2-173	C2
1276	\N	991	\N	C06-C2-163	C2
1277	\N	894	\N	C06-C2-154	C2
1278	\N	184	\N	C06-C2-152	C2
1279	\N	211	\N	C05-C2-150	C2
1280	\N	265	\N	C05-C2-148	C2
1281	\N	9	\N	C05-3ABT	C2
1282	\N	10	\N	C05-3TN	C2
1283	\N	128	\N	C05-3TU	C2
1284	\N	48	\N	C05-C2-145	C2
1285	\N	600	\N	C05-C2-139	C2
1286	\N	193	\N	C05-C2-137	C2
1287	\N	190	\N	C05-C2-135	C2
1288	\N	344	\N	C05-C2-131	C2
1289	\N	356	\N	C05-C2-128	C2
1290	\N	697	\N	C05-C2-121	C2
1291	\N	963	\N	C05-C2-111	C2
1292	\N	550	\N	C04-C2-106	C2
1293	\N	825	\N	C04-C2-98	C2
1294	\N	826	\N	C04-C2-89	C2
1295	\N	735	\N	C04-C2-82	C2
1296	\N	417	\N	C04-C2-78	C2
1297	\N	362	\N	C04-C2-74	C2
1298	\N	600	\N	C04-C2-68	C2
1299	\N	59	\N	C04-C2-67	C2
1300	\N	10	\N	C04-3BTU	C2
1301	\N	148	\N	C04-3BTN	C2
1302	\N	10	\N	C04-1BTN	C2
1303	\N	149	\N	C04-1BTU	C2
1304	\N	456	\N	C04-C2-60	C2
1305	\N	362	\N	C04-C2-56	C2
1306	\N	95	\N	C04-C2-55	C2
1307	\N	170	\N	C04-C2-54	C2
1308	\N	353	\N	C04-C2-50	C2
1309	\N	359	\N	C03-C2-47	C2
1310	\N	600	\N	C03-C2-41	C2
1311	\N	149	\N	C03-C2-39	C2
1312	\N	271	\N	C02-C2-36	C2
1313	\N	392	\N	C02-C2-32	C2
1314	\N	88	\N	C02-5ABT	C2
1315	\N	10	\N	C02-5TN	C2
1316	\N	83	\N	C02-5TU	C2
1317	\N	102	\N	C02-C2-30	C2
1318	\N	10	\N	C02-3BTU	C2
1319	\N	82	\N	C02-3BTN	C2
1320	\N	10	\N	C02-1BTN	C2
1321	\N	82	\N	C02-1BTU	C2
1322	\N	124	\N	C02-C2-27	C2
1323	\N	600	\N	C02-C2-21	C2
1324	\N	358	\N	C02-C2-17	C2
1325	\N	682	\N	C02-C2-10	C2
1326	\N	175	\N	C01-C2-8	C2
1327	\N	178	\N	C01-C2-7	C2
1328	\N	185	\N	C01-C2-5	C2
1329	\N	244	\N	C01-C2-2	C2
1330	\N	600	\N	C01-C2-1	C2
1378	\N	185	\N	C01-D1-4	D1
1379	\N	152	\N	C01-D1-6	D1
1380	\N	172	\N	C01-D1-7	D1
1381	\N	188	\N	D01-D1-9	D1
1382	\N	171	\N	D01-D1-11	D1
1383	\N	93	\N	D01-D1-12	D1
1384	\N	600	\N	D01-D1-13	D1
1385	\N	275	\N	D01-D1-19	D1
1386	\N	253	\N	D01-D1-22	D1
1387	\N	10	\N	D02-1ATU	D1
1388	\N	82	\N	D02-1ATN	D1
1389	\N	10	\N	D02-3ATN	D1
1390	\N	81	\N	D02-3ATU	D1
1391	\N	242	\N	D02-D1-26	D1
1392	\N	463	\N	D02-D1-29	D1
1393	\N	600	\N	D02-D1-34	D1
1394	\N	305	\N	D02-D1-40	D1
1395	\N	234	\N	D02-D1-43	D1
1396	\N	425	\N	D02-D1-45	D1
1397	\N	421	\N	D02-D1-49	D1
1398	\N	449	\N	D03-D1-53	D1
1399	\N	209	\N	D03-D1-58	D1
1400	\N	600	\N	D03-D1-60	D1
1401	\N	307	\N	D03-D1-66	D1
1402	\N	405	\N	D03-D1-69	D1
1403	\N	279	\N	D04-D1-73	D1
1404	\N	116	\N	D04-D1-76	D1
1405	\N	50	\N	D04-D1-77	D1
1406	\N	600	\N	D04-D1-78	D1
1407	\N	68	\N	D04-D1-84	D1
1408	\N	10	\N	D04-1ATU	D1
1409	\N	142	\N	D04-1ATN	D1
1410	\N	10	\N	D04-3ATN	D1
1411	\N	142	\N	D04-3ATU	D1
1412	\N	105	\N	D04-D1-87	D1
1413	\N	638	\N	D04-D1-88	D1
1414	\N	316	\N	D04-D1-95	D1
1415	\N	267	\N	D04-D1-98	D1
1416	\N	344	\N	D04-D1-101	D1
1417	\N	410	\N	D05-D1-104	D1
1418	\N	600	\N	D05-D1-108	D1
1419	\N	511	\N	D05-D1-114	D1
1420	\N	414	\N	D05-D1-119	D1
1421	\N	337	\N	D06-D1-123	D1
1422	\N	359	\N	D06-D1-127	D1
1423	\N	482	\N	D06-D1-130	D1
1424	\N	600	\N	D06-D1-135	D1
1425	\N	59	\N	D06-D1-141	D1
1426	\N	10	\N	D06-1ATU	D1
1427	\N	142	\N	D06-1ATN	D1
1428	\N	10	\N	D06-3ATN	D1
1429	\N	142	\N	D06-3ATU	D1
1430	\N	578	\N	D06-D1-145	D1
1431	\N	149	\N	D06-D1-150	D1
1432	\N	392	\N	D07-D1-152	D1
1433	\N	508	\N	D07-D1-156	D1
1434	\N	379	\N	D07-D1-161	D1
1435	\N	320	\N	D07-D1-165	D1
1436	\N	600	\N	D07-D1-168	D1
1437	\N	484	\N	D07-D1-174	D1
1438	\N	430	\N	D07-D1-179	D1
1439	\N	453	\N	D07-D1-183	D1
1440	\N	512	\N	D07-D1-188	D1
1441	\N	634	\N	D08-D1-193	D1
1442	\N	637	\N	D08-D1-199	D1
1443	\N	600	\N	D08-D1-205	D1
1444	\N	716	\N	D08-D1-211	D1
1445	\N	224	\N	D08-D1-218	D1
1446	\N	486	\N	D08-D1-221	D1
1447	\N	589	\N	D08-D1-223	D1
1448	\N	384	\N	D08-D1-232	D1
1449	\N	683	\N	D08-D1-236	D1
1450	\N	727	\N	D08-D1-242	D1
1451	\N	1026	\N	D98-D1-250	D1
1452	\N	1113	\N	D98-D1-260	D1
1453	\N	10	\N	D98-5ATU	D1
1454	\N	105	\N	D98-5ATN	D1
1455	\N	91	\N	D98-5ABT	D1
1456	\N	672	\N	D98-D1-273	D1
1457	\N	91	\N	D98-9ABT	D1
1458	\N	10	\N	D98-9TN	D1
1459	\N	81	\N	D98-9TU	D1
1460	\N	121	\N	D98-D1-281	D1
1461	\N	10	\N	D98-13TU	D1
1462	\N	105	\N	D98-13TN	D1
1463	\N	149	\N	D98-13ABT	D1
1464	\N	132	\N	D98-D1-285	D1
1465	\N	902	\N	D09-D1-287	D1
1466	\N	226	\N	D09-D1-296	D1
1467	\N	289	\N	D09-D1-298	D1
1468	\N	173	\N	D09-D1-301	D1
1469	\N	146	\N	D09-D1-302	D1
1470	\N	153	\N	D09-D1-304	D1
1471	\N	234	\N	D09-D1-305	D1
1472	\N	267	\N	D09-D1-308	D1
1473	\N	324	\N	D09-D1-310	D1
1474	\N	241	\N	D09-D1-313	D1
1475	\N	600	\N	D09-D1-316	D1
1476	\N	182	\N	D09-D1-322	D1
1477	\N	178	\N	D09-D1-324	D1
1478	\N	227	\N	D09-D1-325	D1
1479	\N	188	\N	D09-D1-328	D1
1480	\N	366	\N	D09-D1-329	D1
1481	\N	491	\N	D09-D1-333	D1
1482	\N	516	\N	D09-D1-338	D1
1483	\N	662	\N	D10-D1-343	D1
1484	\N	330	\N	D10-D1-350	D1
1485	\N	490	\N	D10-D1-353	D1
1486	\N	493	\N	D10-D1-358	D1
1487	\N	600	\N	D10-D1-362	D1
1488	\N	367	\N	D10-D1-368	D1
1489	\N	500	\N	D10-D1-372	D1
1490	\N	694	\N	D10-D1-377	D1
1491	\N	1004	\N	D10-D1-384	D1
1492	\N	890	\N	D10-D1-390	D1
1493	\N	515	\N	D11-D1-399	D1
1494	\N	370	\N	D11-D1-405	D1
1495	\N	422	\N	D11-D1-408	D1
1496	\N	172	\N	D11-D1-412	D1
1497	\N	171	\N	D11-D1-414	D1
1498	\N	246	\N	D11-D1-416	D1
1499	\N	198	\N	D11-D1-418	D1
1500	\N	600	\N	D11-D1-420	D1
1501	\N	51	\N	D11-D1-426	D1
1502	\N	10	\N	D11-1ATU	D1
1503	\N	181	\N	D11-1ATN	D1
1504	\N	10	\N	D11-3ATN	D1
1505	\N	195	\N	D11-3ATU	D1
1506	\N	224	\N	D11-D1-431	D1
1507	\N	450	\N	D11-D1-433	D1
1508	\N	584	\N	D11-D1-438	D1
1509	\N	766	\N	D11-D1-443	D1
1510	\N	890	\N	D11-D1-451	D1
1511	\N	1345	\N	D11-D1-460	D1
1512	\N	922	\N	D12-D1-473	D1
1513	\N	1443	\N	D12-D1-483	D1
1514	\N	382	\N	D12-D1-497	D1
1515	\N	201	\N	D12-D1-501	D1
1516	\N	295	\N	D12-D1-503	D1
1517	\N	239	\N	D12-D1-506	D1
1518	\N	232	\N	D12-D1-508	D1
1519	\N	256	\N	D12-D1-510	D1
1520	\N	240	\N	D12-D1-513	D1
1521	\N	149	\N	D12-D1-515	D1
1522	\N	600	\N	D12-D1-517	D1
1523	\N	255	\N	D12-D1-523	D1
1524	\N	267	\N	D12-D1-525	D1
1525	\N	377	\N	D12-D1-528	D1
1526	\N	336	\N	D12-D1-532	D1
1527	\N	771	\N	D12-D1-535	D1
1528	\N	1012	\N	D12-D1-543	D1
1529	\N	756	\N	D12-D1-553	D1
1530	\N	450	\N	D13-D1-561	D1
1531	\N	451	\N	D13-D1-565	D1
1532	\N	305	\N	D13-D1-570	D1
1533	\N	429	\N	D13-D1-573	D1
1534	\N	326	\N	D13-D1-577	D1
1535	\N	274	\N	D13-D1-580	D1
1536	\N	447	\N	D13-D1-583	D1
1537	\N	10	\N	D13-1ATU	D1
1538	\N	181	\N	D13-1ATN	D1
1539	\N	10	\N	D13-3ATN	D1
1540	\N	180	\N	D13-3ATU	D1
1541	\N	218	\N	D13-D1-591	D1
1542	\N	600	\N	D13-D1-594	D1
1544	\N	185	\N	C01-D2-4	D2
1545	\N	241	\N	D01-D2-6	D2
1546	\N	233	\N	D01-D2-8	D2
1547	\N	180	\N	D01-D2-10	D2
1548	\N	122	\N	D01-D2-12	D2
1549	\N	600	\N	D01-D2-16	D2
1550	\N	423	\N	D02-D2-19	D2
1551	\N	115	\N	D02-D2-24	D2
1552	\N	10	\N	D02-3BTU	D2
1553	\N	82	\N	D02-3BTN	D2
1554	\N	10	\N	D02-1BTN	D2
1555	\N	81	\N	D02-1BTU	D2
1556	\N	370	\N	D02-D2-26	D2
1557	\N	174	\N	D02-D2-30	D2
1558	\N	152	\N	D02-D2-32	D2
1559	\N	600	\N	D02-D2-36	D2
1560	\N	206	\N	D02-D2-40	D2
1561	\N	328	\N	D02-D2-42	D2
1562	\N	156	\N	D02-D2-45	D2
1563	\N	465	\N	D02-D2-46	D2
1564	\N	256	\N	D03-D2-51	D2
1565	\N	156	\N	D03-D2-54	D2
1566	\N	195	\N	D03-D2-55	D2
1567	\N	237	\N	D03-D2-58	D2
1568	\N	600	\N	D03-D2-64	D2
1569	\N	188	\N	D03-D2-66	D2
1570	\N	306	\N	D04-D2-68	D2
1571	\N	186	\N	D04-D2-71	D2
1572	\N	182	\N	D04-D2-73	D2
1573	\N	158	\N	D04-D2-75	D2
1574	\N	131	\N	D04-D2-76	D2
1575	\N	600	\N	D04-D2-82	D2
1576	\N	68	\N	D04-D2-84	D2
1577	\N	10	\N	D04-3BTU	D2
1578	\N	142	\N	D04-3BTN	D2
1579	\N	10	\N	D04-1BTN	D2
1580	\N	142	\N	D04-1BTU	D2
1581	\N	201	\N	D04-D2-87	D2
1582	\N	351	\N	D04-D2-89	D2
1583	\N	191	\N	D04-D2-93	D2
1584	\N	219	\N	D04-D2-95	D2
1585	\N	196	\N	D04-D2-97	D2
1586	\N	323	\N	D04-D2-99	D2
1587	\N	262	\N	D05-D2-102	D2
1588	\N	183	\N	D05-D2-105	D2
1589	\N	154	\N	D05-D2-107	D2
1590	\N	600	\N	D05-D2-111	D2
1591	\N	452	\N	D05-D2-114	D2
1592	\N	290	\N	D05-D2-119	D2
1593	\N	349	\N	D06-D2-121	D2
1594	\N	159	\N	D06-D2-125	D2
1595	\N	197	\N	D06-D2-127	D2
1596	\N	319	\N	D06-D2-129	D2
1597	\N	356	\N	D06-D2-132	D2
1598	\N	600	\N	D06-D2-138	D2
1599	\N	59	\N	D06-D2-141	D2
1600	\N	10	\N	D06-3BTU	D2
1601	\N	142	\N	D06-3BTN	D2
1602	\N	10	\N	D06-1BTN	D2
1603	\N	142	\N	D06-1BTU	D2
1604	\N	132	\N	D06-D2-145	D2
1605	\N	186	\N	D07-D2-146	D2
1606	\N	357	\N	D07-D2-148	D2
1607	\N	722	\N	D07-D2-151	D2
1608	\N	300	\N	D07-D2-159	D2
1609	\N	610	\N	D07-D2-162	D2
1610	\N	600	\N	D07-D2-171	D2
1611	\N	624	\N	D07-D2-174	D2
1612	\N	302	\N	D07-D2-180	D2
1613	\N	445	\N	D07-D2-183	D2
1614	\N	482	\N	D08-D2-188	D2
1615	\N	547	\N	D08-D2-192	D2
1616	\N	508	\N	D08-D2-198	D2
1617	\N	246	\N	D08-D2-204	D2
1618	\N	600	\N	D08-D2-208	D2
1619	\N	427	\N	D08-D2-211	D2
1620	\N	611	\N	D08-D2-216	D2
1621	\N	1011	\N	D08-D2-221	D2
1622	\N	404	\N	D08-D2-232	D2
1623	\N	359	\N	D08-D2-236	D2
1624	\N	1058	\N	D98-D2-240	D2
1625	\N	1078	\N	D98-D2-250	D2
1626	\N	1051	\N	D98-D2-261	D2
1627	\N	10	\N	D98-7TU	D2
1628	\N	106	\N	D98-7TN	D2
1629	\N	91	\N	D98-7ABT	D2
1630	\N	672	\N	D98-D2-273	D2
1631	\N	91	\N	D98-11BBT	D2
1632	\N	10	\N	D98-11BTN	D2
1633	\N	81	\N	D98-11BTU	D2
1634	\N	121	\N	D98-D2-281	D2
1635	\N	10	\N	D98-15TU	D2
1636	\N	105	\N	D98-15TN	D2
1637	\N	144	\N	D98-15ABT	D2
1638	\N	1039	\N	D98-D2-285	D2
1639	\N	1138	\N	D09-D2-296	D2
1640	\N	324	\N	D09-D2-307	D2
1641	\N	314	\N	D09-D2-310	D2
1642	\N	261	\N	D09-D2-313	D2
1643	\N	600	\N	D09-D2-320	D2
1644	\N	341	\N	D09-D2-322	D2
1645	\N	269	\N	D09-D2-325	D2
1646	\N	216	\N	D09-D2-328	D2
1647	\N	199	\N	D09-D2-330	D2
1648	\N	211	\N	D09-D2-332	D2
1649	\N	396	\N	D09-D2-334	D2
1650	\N	398	\N	D10-D2-338	D2
1651	\N	625	\N	D10-D2-342	D2
1652	\N	485	\N	D10-D2-348	D2
1653	\N	358	\N	D10-D2-353	D2
1654	\N	197	\N	D10-D2-357	D2
1655	\N	229	\N	D10-D2-359	D2
1656	\N	138	\N	D10-D2-361	D2
1657	\N	600	\N	D10-D2-365	D2
1658	\N	214	\N	D10-D2-368	D2
1659	\N	408	\N	D10-D2-370	D2
1660	\N	447	\N	D10-D2-375	D2
1661	\N	228	\N	D10-D2-379	D2
1662	\N	264	\N	D10-D2-381	D2
1663	\N	157	\N	D10-D2-384	D2
1664	\N	425	\N	D10-D2-386	D2
1665	\N	1332	\N	D11-D2-390	D2
1666	\N	859	\N	D11-D2-399	D2
1667	\N	625	\N	D11-D2-408	D2
1668	\N	174	\N	D11-D2-414	D2
1669	\N	424	\N	D11-D2-416	D2
1670	\N	600	\N	D11-D2-425	D2
1671	\N	67	\N	D11-D2-426	D2
1672	\N	88	\N	D11-1BBT	D2
1673	\N	10	\N	D11-1BTN	D2
1674	\N	77	\N	D11-1BTU	D2
1675	\N	10	\N	D11-3BTU	D2
1676	\N	78	\N	D11-3BTN	D2
1677	\N	111	\N	D11-3BBT	D2
1678	\N	639	\N	D11-D2-430	D2
1679	\N	625	\N	D11-D2-437	D2
1680	\N	752	\N	D11-D2-443	D2
1681	\N	905	\N	D11-D2-451	D2
1682	\N	1039	\N	D11-D2-460	D2
1683	\N	613	\N	D12-D2-470	D2
1684	\N	614	\N	D12-D2-476	D2
1685	\N	1011	\N	D12-D2-483	D2
1686	\N	1013	\N	D12-D2-493	D2
1687	\N	435	\N	D12-D2-503	D2
1688	\N	277	\N	D12-D2-507	D2
1689	\N	270	\N	D12-D2-510	D2
1690	\N	221	\N	D12-D2-513	D2
1691	\N	213	\N	D12-D2-515	D2
1692	\N	600	\N	D12-D2-521	D2
1693	\N	60	\N	D12-D2-523	D2
1694	\N	198	\N	D12-D2-524	D2
1695	\N	202	\N	D12-D2-526	D2
1696	\N	215	\N	D12-D2-528	D2
1697	\N	136	\N	D12-D2-530	D2
1698	\N	195	\N	D12-D2-531	D2
1699	\N	229	\N	D12-D2-533	D2
1700	\N	685	\N	D12-D2-535	D2
1701	\N	1098	\N	D12-D2-542	D2
1702	\N	666	\N	D12-D2-553	D2
1703	\N	991	\N	D13-D2-560	D2
1704	\N	739	\N	D13-D2-570	D2
1705	\N	1043	\N	D13-D2-577	D2
1706	\N	10	\N	D13-3BTU	D2
1707	\N	180	\N	D13-3BTN	D2
1708	\N	10	\N	D13-1BTN	D2
1709	\N	181	\N	D13-1BTU	D2
1710	\N	218	\N	D13-D2-591	D2
1711	\N	600	\N	D13-D2-594	D2
1744	\N	201	\N	F01-E1-3	E1
1745	\N	611	\N	F01-E1-5	E1
1746	\N	584	\N	F01-E1-11	E1
1747	\N	575	\N	F01-E1-17	E1
1748	\N	10	\N	E01-1ATU	E1
1749	\N	157	\N	E01-1ATN	E1
1750	\N	10	\N	E01-3ATN	E1
1751	\N	157	\N	E01-3ATU	E1
1752	\N	80	\N	E01-E1-26	E1
1753	\N	600	\N	E01-E1-27	E1
1754	\N	96	\N	E01-E1-33	E1
1755	\N	10	\N	E01-5ATU	E1
1756	\N	91	\N	E01-5ATN	E1
1757	\N	101	\N	E01-5ABT	E1
1758	\N	296	\N	E01-E1-36	E1
1759	\N	485	\N	E01-E1-39	E1
1760	\N	101	\N	E01-9ABT	E1
1761	\N	10	\N	E01-9TN	E1
1762	\N	91	\N	E01-9TU	E1
1763	\N	646	\N	E01-E1-46	E1
1764	\N	600	\N	E02-E1-52	E1
1765	\N	424	\N	E02-E1-58	E1
1766	\N	407	\N	E02-E1-62	E1
1767	\N	708	\N	E02-E1-66	E1
1768	\N	10	\N	E03-1ATU	E1
1769	\N	156	\N	E03-1ATN	E1
1770	\N	10	\N	E03-3ATN	E1
1771	\N	156	\N	E03-3ATU	E1
1772	\N	84	\N	E03-E1-77	E1
1773	\N	600	\N	E03-E1-78	E1
1774	\N	228	\N	E03-E1-84	E1
1775	\N	590	\N	E03-E1-86	E1
1776	\N	665	\N	E03-E1-92	E1
1777	\N	686	\N	E04-E1-99	E1
1778	\N	599	\N	E04-E1-105	E1
1779	\N	520	\N	E04-E1-111	E1
1780	\N	368	\N	E04-E1-117	E1
1781	\N	459	\N	E04-E1-120	E1
1782	\N	600	\N	E04-E1-125	E1
1783	\N	293	\N	E04-E1-131	E1
1784	\N	420	\N	E04-E1-134	E1
1785	\N	540	\N	E04-E1-138	E1
1786	\N	640	\N	E04-E1-143	E1
1787	\N	680	\N	E05-E1-150	E1
1788	\N	290	\N	E05-E1-157	E1
1789	\N	420	\N	E05-E1-160	E1
1790	\N	287	\N	E05-E1-164	E1
1791	\N	10	\N	E05-1ATU	E1
1792	\N	199	\N	E05-1ATN	E1
1793	\N	10	\N	E05-3ATN	E1
1794	\N	198	\N	E05-3ATU	E1
1795	\N	130	\N	E05-E1-171	E1
1796	\N	600	\N	E05-E1-172	E1
1797	\N	494	\N	E05-E1-178	E1
1798	\N	645	\N	E05-E1-183	E1
1799	\N	737	\N	E05-E1-190	E1
1800	\N	988	\N	E05-E1-197	E1
1801	\N	828	\N	E05-E1-207	E1
1802	\N	492	\N	E05-E1-215	E1
1803	\N	835	\N	E06-E1-220	E1
1804	\N	665	\N	E06-E1-228	E1
1805	\N	672	\N	E06-E1-235	E1
1806	\N	523	\N	E06-E1-242	E1
1807	\N	362	\N	E06-E1-248	E1
1808	\N	507	\N	E06-E1-253	E1
1809	\N	600	\N	E06-E1-258	E1
1810	\N	393	\N	E06-E1-264	E1
1811	\N	638	\N	E06-E1-268	E1
1812	\N	104	\N	E06-5ABT	E1
1813	\N	10	\N	E06-5TN	E1
1814	\N	94	\N	E06-5TU	E1
1815	\N	685	\N	E06-E1-276	E1
1816	\N	10	\N	E06-1ATU	E1
1817	\N	143	\N	E06-1ATN	E1
1818	\N	10	\N	E06-3ATN	E1
1819	\N	143	\N	E06-3ATU	E1
1820	\N	60	\N	E06-E1-286	E1
1821	\N	701	\N	E06-E1-287	E1
1822	\N	1000	\N	E06-E1-294	E1
1823	\N	960	\N	E06-E1-304	E1
1824	\N	1240	\N	E07-E1-314	E1
1825	\N	700	\N	E07-E1-326	E1
1826	\N	412	\N	E07-E1-333	E1
1827	\N	438	\N	E07-E1-337	E1
1828	\N	410	\N	E07-E1-342	E1
1829	\N	240	\N	E07-E1-346	E1
1830	\N	600	\N	E07-E1-348	E1
1831	\N	400	\N	E07-E1-354	E1
1832	\N	415	\N	E07-E1-358	E1
1833	\N	600	\N	E07-E1-362	E1
1834	\N	935	\N	E07-E1-368	E1
1835	\N	575	\N	E07-E1-378	E1
1836	\N	525	\N	E07-E1-383	E1
1837	\N	635	\N	E07-E1-389	E1
1838	\N	475	\N	E07-E1-395	E1
1839	\N	240	\N	E08-E1-400	E1
1840	\N	945	\N	E08-E1-402	E1
1841	\N	64	\N	E08-E1-411	E1
1842	\N	10	\N	E08-1ATU	E1
1843	\N	101	\N	E08-1ATN	E1
1844	\N	10	\N	E08-3ATN	E1
1845	\N	101	\N	E08-3ATU	E1
1846	\N	414	\N	E08-E1-414	E1
1847	\N	350	\N	E08-E1-419	E1
1848	\N	336	\N	E08-E1-422	E1
1849	\N	354	\N	E08-E1-425	E1
1850	\N	600	\N	E08-E1-429	E1
1851	\N	345	\N	E08-E1-435	E1
1852	\N	565	\N	E08-E1-438	E1
1853	\N	550	\N	E08-E1-444	E1
1854	\N	155	\N	E08-E1-450	E1
1855	\N	1095	\N	E08-E1-451	E1
1856	\N	1000	\N	E08-E1-462	E1
1857	\N	435	\N	E08-E1-472	E1
1858	\N	565	\N	E08-E1-476	E1
1859	\N	900	\N	E08-E1-482	E1
1860	\N	510	\N	E09-E1-491	E1
1861	\N	662	\N	E09-E1-496	E1
1862	\N	928	\N	E09-E1-503	E1
1863	\N	547	\N	E09-E1-512	E1
1864	\N	553	\N	E09-E1-517	E1
1865	\N	546	\N	E09-E1-523	E1
1866	\N	10	\N	E09-1ATU	E1
1867	\N	166	\N	E09-1ATN	E1
1868	\N	10	\N	E09-3ATN	E1
1869	\N	166	\N	E09-3ATU	E1
1870	\N	60	\N	E09-E1-531	E1
1871	\N	600	\N	E09-E1-532	E1
1872	\N	378	\N	E09-E1-538	E1
1873	\N	300	\N	E09-E1-542	E1
1874	\N	446	\N	E09-E1-545	E1
1875	\N	604	\N	E09-E1-549	E1
1876	\N	1120	\N	E09-E1-556	E1
1877	\N	630	\N	E09-E1-567	E1
1878	\N	760	\N	E09-E1-573	E1
1879	\N	840	\N	E09-E1-581	E1
1880	\N	550	\N	E09-E1-589	E1
1881	\N	750	\N	E09-E1-595	E1
1882	\N	638	\N	E10-E1-602	E1
1883	\N	662	\N	E10-E1-608	E1
1884	\N	680	\N	E10-E1-615	E1
1885	\N	820	\N	E10-E1-622	E1
1886	\N	950	\N	E10-E1-630	E1
1887	\N	1004	\N	E10-E1-640	E1
1888	\N	774	\N	E10-E1-650	E1
1889	\N	10	\N	E10-1ATU	E1
1890	\N	200	\N	E10-1ATN	E1
1891	\N	10	\N	E10-3ATN	E1
1892	\N	200	\N	E10-3ATU	E1
1893	\N	55	\N	E10-E1-661	E1
1894	\N	600	\N	E10-E1-662	E1
1895	\N	190	\N	E10-E1-668	E1
1896	\N	310	\N	E10-E1-670	E1
1897	\N	500	\N	E10-E1-673	E1
1899	\N	600	\N	F01-E2-1	E2
1900	\N	276	\N	F01-E2-3	E2
1901	\N	295	\N	F01-E2-6	E2
1902	\N	495	\N	F01-E2-9	E2
1903	\N	270	\N	F01-E2-14	E2
1904	\N	325	\N	E01-E2-16	E2
1905	\N	310	\N	E01-E2-20	E2
1906	\N	10	\N	E01-3BTU	E2
1907	\N	157	\N	E01-3BTN	E2
1908	\N	10	\N	E01-1BTN	E2
1909	\N	157	\N	E01-1BTU	E2
1910	\N	80	\N	E01-E2-26	E2
1911	\N	600	\N	E01-E2-31	E2
1912	\N	96	\N	E01-E2-33	E2
1913	\N	10	\N	E01-7TU	E2
1914	\N	91	\N	E01-7TN	E2
1915	\N	101	\N	E01-7ABT	E2
1916	\N	424	\N	E01-E2-36	E2
1917	\N	357	\N	E01-E2-40	E2
1918	\N	101	\N	E01-11BBT	E2
1919	\N	10	\N	E01-11BTN	E2
1920	\N	91	\N	E01-11BTU	E2
1921	\N	393	\N	E02-E2-46	E2
1922	\N	253	\N	E02-E2-50	E2
1923	\N	600	\N	E02-E2-54	E2
1924	\N	604	\N	E02-E2-58	E2
1925	\N	390	\N	E02-E2-64	E2
1926	\N	487	\N	E03-E2-68	E2
1927	\N	10	\N	E03-3BTU	E2
1928	\N	156	\N	E03-3BTN	E2
1929	\N	10	\N	E03-1BTN	E2
1930	\N	156	\N	E03-1BTU	E2
1931	\N	84	\N	E03-E2-77	E2
1932	\N	600	\N	E03-E2-78	E2
1933	\N	468	\N	E03-E2-84	E2
1934	\N	380	\N	E03-E2-88	E2
1935	\N	487	\N	E04-E2-92	E2
1936	\N	341	\N	E04-E2-97	E2
1937	\N	546	\N	E04-E2-100	E2
1938	\N	421	\N	E04-E2-105	E2
1939	\N	680	\N	E04-E2-110	E2
1940	\N	205	\N	E04-E2-116	E2
1941	\N	642	\N	E04-E2-118	E2
1942	\N	600	\N	E04-E2-125	E2
1943	\N	301	\N	E04-E2-131	E2
1944	\N	412	\N	E04-E2-134	E2
1945	\N	530	\N	E04-E2-138	E2
1946	\N	685	\N	E05-E2-143	E2
1947	\N	600	\N	E05-E2-150	E2
1948	\N	255	\N	E05-E2-156	E2
1949	\N	470	\N	E05-E2-158	E2
1950	\N	352	\N	E05-E2-163	E2
1951	\N	10	\N	E05-3BTU	E2
1952	\N	199	\N	E05-3BTN	E2
1953	\N	10	\N	E05-1BTN	E2
1954	\N	198	\N	E05-1BTU	E2
1955	\N	130	\N	E05-E2-171	E2
1956	\N	600	\N	E05-E2-172	E2
1957	\N	244	\N	E05-E2-178	E2
1958	\N	240	\N	E05-E2-181	E2
1959	\N	140	\N	E05-E2-183	E2
1960	\N	350	\N	E05-E2-185	E2
1961	\N	360	\N	E05-E2-188	E2
1962	\N	230	\N	E05-E2-192	E2
1963	\N	312	\N	E05-E2-194	E2
1964	\N	648	\N	E05-E2-197	E2
1965	\N	1168	\N	E05-E2-204	E2
1966	\N	1180	\N	E06-E2-215	E2
1967	\N	1512	\N	E06-E2-227	E2
1968	\N	525	\N	E06-E2-242	E2
1969	\N	369	\N	E06-E2-248	E2
1970	\N	505	\N	E06-E2-253	E2
1971	\N	600	\N	E06-E2-258	E2
1972	\N	193	\N	E06-E2-264	E2
1973	\N	890	\N	E06-E2-266	E2
1974	\N	157	\N	E06-E2-275	E2
1975	\N	684	\N	E06-E2-276	E2
1976	\N	10	\N	E06-3BTU	E2
1977	\N	144	\N	E06-3BTN	E2
1978	\N	10	\N	E06-1BTN	E2
1979	\N	144	\N	E06-1BTU	E2
1980	\N	60	\N	E06-E2-286	E2
1981	\N	701	\N	E06-E2-287	E2
1982	\N	600	\N	E06-E2-294	E2
1983	\N	709	\N	E06-E2-300	E2
1984	\N	660	\N	E07-E2-307	E2
1985	\N	1240	\N	E07-E2-314	E2
1986	\N	700	\N	E07-E2-326	E2
1987	\N	412	\N	E07-E2-333	E2
1988	\N	438	\N	E07-E2-337	E2
1989	\N	410	\N	E07-E2-342	E2
1990	\N	660	\N	E07-E2-346	E2
1991	\N	976	\N	E07-E2-352	E2
1992	\N	600	\N	E07-E2-362	E2
1994	\N	550	\N	E07-E2-372	E2
1995	\N	1092	\N	E07-E2-378	E2
1996	\N	635	\N	E07-E2-389	E2
1997	\N	475	\N	E08-E2-395	E2
1998	\N	940	\N	E08-E2-400	E2
1999	\N	271	\N	E08-E2-409	E2
2000	\N	64	\N	E08-E2-412	E2
2001	\N	10	\N	E08-3BTU	E2
2002	\N	101	\N	E08-3BTN	E2
2003	\N	10	\N	E08-1BTN	E2
2004	\N	101	\N	E08-1BTU	E2
2005	\N	418	\N	E08-E2-414	E2
2006	\N	450	\N	E08-E2-419	E2
2007	\N	236	\N	E08-E2-423	E2
2008	\N	354	\N	E08-E2-425	E2
2009	\N	600	\N	E08-E2-429	E2
2010	\N	345	\N	E08-E2-435	E2
2011	\N	365	\N	E08-E2-438	E2
2012	\N	890	\N	E08-E2-442	E2
2013	\N	310	\N	E08-E2-451	E2
2014	\N	500	\N	E08-E2-454	E2
2015	\N	875	\N	E08-E2-459	E2
2016	\N	835	\N	E08-E2-468	E2
2017	\N	565	\N	E08-E2-476	E2
2018	\N	900	\N	E09-E2-482	E2
2019	\N	510	\N	E09-E2-491	E2
2020	\N	695	\N	E09-E2-496	E2
2021	\N	895	\N	E09-E2-503	E2
2022	\N	547	\N	E09-E2-512	E2
2023	\N	553	\N	E09-E2-517	E2
2024	\N	560	\N	E09-E2-523	E2
2025	\N	10	\N	E09-3BTU	E2
2026	\N	167	\N	E09-3BTN	E2
2027	\N	10	\N	E09-1BTN	E2
2028	\N	167	\N	E09-1BTU	E2
2029	\N	60	\N	E09-E2-531	E2
2030	\N	600	\N	E09-E2-532	E2
2031	\N	598	\N	E09-E2-538	E2
2032	\N	526	\N	E09-E2-544	E2
2033	\N	769	\N	E09-E2-549	E2
2034	\N	956	\N	E09-E2-557	E2
2035	\N	627	\N	E09-E2-567	E2
2036	\N	760	\N	E09-E2-573	E2
2037	\N	840	\N	E09-E2-581	E2
2038	\N	550	\N	E09-E2-589	E2
2039	\N	750	\N	E10-E2-595	E2
2040	\N	638	\N	E10-E2-602	E2
2041	\N	662	\N	E10-E2-608	E2
2042	\N	680	\N	E10-E2-615	E2
2043	\N	820	\N	E10-E2-622	E2
2044	\N	950	\N	E10-E2-630	E2
2045	\N	1176	\N	E10-E2-640	E2
2046	\N	131	\N	E10-5BBT	E2
2047	\N	10	\N	E10-5BATN	E2
2048	\N	121	\N	E10-5BATU	E2
2049	\N	345	\N	E10-E2-650	E2
2050	\N	10	\N	E10-3BTU	E2
2051	\N	200	\N	E10-3BTN	E2
2052	\N	10	\N	E10-1BTN	E2
2053	\N	200	\N	E10-1BTU	E2
2054	\N	55	\N	E10-E2-661	E2
2055	\N	600	\N	E10-E2-662	E2
2056	\N	190	\N	E10-E2-668	E2
2057	\N	310	\N	E10-E2-670	E2
2058	\N	493	\N	E10-E2-673	E2
2110	\N	651	\N	F11-YL1-5T	F1
2111	\N	106	\N	F11-7ABT	F1
2112	\N	10	\N	F11-7ATN	F1
2113	\N	170	\N	F11-7ATU	F1
2114	\N	10	\N	F11-5ATU	F1
2115	\N	169	\N	F11-5ATN	F1
2116	\N	106	\N	F11-5ABT	F1
2117	\N	320	\N	F11-YL1-34T	F1
2118	\N	600	\N	F11-F1-540	F1
2119	\N	140	\N	F11-F1-539	F1
2120	\N	10	\N	F11-1ATU	F1
2121	\N	191	\N	F11-1ATN	F1
2122	\N	10	\N	F11-3ATN	F1
2123	\N	191	\N	F11-3ATU	F1
2124	\N	744	\N	F11-F1-527	F1
2125	\N	620	\N	F11-F1-521	F1
2126	\N	833	\N	F11-F1-513	F1
2127	\N	836	\N	F11-F1-504	F1
2128	\N	1231	\N	F11-F1-492	F1
2129	\N	655	\N	F10-F1-485	F1
2130	\N	1382	\N	F10-F1-471	F1
2131	\N	415	\N	F10-F1-467	F1
2132	\N	230	\N	F10-F1-465	F1
2133	\N	356	\N	F10-F1-462	F1
2134	\N	580	\N	F10-F1-456	F1
2135	\N	120	\N	F10-F1-455	F1
2136	\N	600	\N	F10-F1-451	F1
2137	\N	224	\N	F10-F1-446	F1
2138	\N	360	\N	F10-F1-443	F1
2139	\N	740	\N	F10-F1-435	F1
2140	\N	746	\N	F10-F1-428	F1
2141	\N	750	\N	F10-F1-420	F1
2142	\N	390	\N	F10-F1-417	F1
2143	\N	700	\N	F10-F1-410	F1
2144	\N	843	\N	F09-F1-401	F1
2145	\N	360	\N	F09-F1-398	F1
2146	\N	395	\N	F09-F1-394	F1
2147	\N	448	\N	F09-F1-389	F1
2148	\N	585	\N	F09-F1-383	F1
2149	\N	10	\N	F09-1ATU	F1
2150	\N	193	\N	F09-1ATN	F1
2151	\N	10	\N	F09-3ATN	F1
2152	\N	193	\N	F09-3ATU	F1
2153	\N	111	\N	F09-F1-378	F1
2154	\N	600	\N	F09-F1-374	F1
2155	\N	241	\N	F09-F1-370	F1
2156	\N	660	\N	F09-F1-363	F1
2157	\N	580	\N	F09-F1-358	F1
2158	\N	325	\N	F09-F1-354	F1
2159	\N	545	\N	F09-F1-349	F1
2160	\N	863	\N	F09-F1-340	F1
2161	\N	460	\N	F08-F1-336	F1
2162	\N	150	\N	F08-F1-334	F1
2163	\N	553	\N	F08-F1-329	F1
2164	\N	370	\N	F08-F1-325	F1
2165	\N	170	\N	F08-F1-323	F1
2166	\N	210	\N	F08-F1-321	F1
2167	\N	300	\N	F08-F1-318	F1
2168	\N	240	\N	F08-F1-316	F1
2169	\N	345	\N	F08-F1-312	F1
2170	\N	600	\N	F08-F1-310	F1
2171	\N	125	\N	F08-F1-305	F1
2172	\N	10	\N	F08-1ATU	F1
2173	\N	168	\N	F08-1ATN	F1
2174	\N	10	\N	F08-3ATN	F1
2175	\N	168	\N	F08-3ATU	F1
2176	\N	293	\N	F08-F1-298	F1
2177	\N	515	\N	F08-F1-293	F1
2178	\N	475	\N	F08-F1-288	F1
2179	\N	1399	\N	F08-F1-274	F1
2180	\N	630	\N	F07-F1-268	F1
2181	\N	735	\N	F07-F1-261	F1
2182	\N	380	\N	F07-F1-257	F1
2183	\N	600	\N	F07-F1-254	F1
2184	\N	560	\N	F07-F1-245	F1
2185	\N	400	\N	F07-F1-241	F1
2186	\N	720	\N	F07-F1-234	F1
2187	\N	1132	\N	F07-F1-222	F1
2188	\N	558	\N	F06-F1-217	F1
2189	\N	630	\N	F06-F1-211	F1
2190	\N	400	\N	F06-F1-207	F1
2191	\N	300	\N	F06-F1-204	F1
2192	\N	635	\N	F06-F1-198	F1
2193	\N	511	\N	F06-F1-192	F1
2194	\N	10	\N	F06-1ATU	F1
2195	\N	165	\N	F06-1ATN	F1
2196	\N	10	\N	F06-3ATN	F1
2197	\N	165	\N	F06-3ATU	F1
2198	\N	55	\N	F06-F1-188	F1
2199	\N	600	\N	F06-F1-185	F1
2200	\N	434	\N	F06-F1-178	F1
2201	\N	833	\N	F06-F1-170	F1
2202	\N	1500	\N	F06-F1-155	F1
2203	\N	1013	\N	F06-F1-145	F1
2204	\N	523	\N	F05-F1-140	F1
2205	\N	520	\N	F05-F1-135	F1
2206	\N	485	\N	F05-F1-130	F1
2207	\N	346	\N	F05-F1-127	F1
2208	\N	600	\N	F05-F1-121	F1
2209	\N	59	\N	F05-F1-120	F1
2210	\N	10	\N	F05-1ATU	F1
2211	\N	159	\N	F05-1ATN	F1
2212	\N	10	\N	F05-3ATN	F1
2213	\N	159	\N	F05-3ATU	F1
2214	\N	467	\N	F05-F1-112	F1
2215	\N	480	\N	F05-F1-107	F1
2216	\N	575	\N	F05-F1-101	F1
2217	\N	405	\N	F04-F1-97	F1
2218	\N	402	\N	F04-F1-93	F1
2219	\N	600	\N	F04-F1-90	F1
2220	\N	204	\N	F04-F1-85	F1
2221	\N	475	\N	F04-F1-80	F1
2222	\N	320	\N	F04-F1-77	F1
2223	\N	770	\N	F04-F1-69	F1
2224	\N	405	\N	F03-F1-65	F1
2225	\N	566	\N	F03-F1-59	F1
2226	\N	470	\N	F03-F1-55	F1
2227	\N	148	\N	F03-5ABT	F1
2228	\N	10	\N	F03-5TN	F1
2229	\N	138	\N	F03-5TU	F1
2230	\N	52	\N	F03-F1-51	F1
2231	\N	600	\N	F03-F1-49	F1
2232	\N	52	\N	F03-F1-44	F1
2233	\N	10	\N	F03-1ATU	F1
2234	\N	94	\N	F03-1ATN	F1
2235	\N	10	\N	F03-3ATN	F1
2236	\N	94	\N	F03-3ATU	F1
2237	\N	475	\N	F03-F1-38	F1
2238	\N	565	\N	F03-F1-32	F1
2239	\N	610	\N	F03-F1-26	F1
2240	\N	440	\N	F03-F1-22	F1
2241	\N	600	\N	F02-F1-20	F1
2242	\N	240	\N	F02-F1-13	F1
2243	\N	345	\N	F02-F1-10	F1
2244	\N	455	\N	F02-F1-5	F1
2245	\N	239	\N	F01-F1-3	F1
2246	\N	600	\N	F01-F1-1	F1
2247	\N	681	\N	F11-YL2-5T	F2
2248	\N	10	\N	F11-7BTU	F2
2249	\N	169	\N	F11-7BTN	F2
2250	\N	106	\N	F11-7BBT	F2
2251	\N	106	\N	F11-5BBT	F2
2252	\N	10	\N	F11-5BTN	F2
2253	\N	170	\N	F11-5BTU	F2
2254	\N	318	\N	F11-F2-546	F2
2255	\N	600	\N	F11-F2-540	F2
2256	\N	140	\N	F11-F2-539	F2
2257	\N	10	\N	F11-3BTU	F2
2258	\N	191	\N	F11-3BTN	F2
2259	\N	10	\N	F11-1BTN	F2
2260	\N	191	\N	F11-1BTU	F2
2261	\N	528	\N	F11-F2-529	F2
2262	\N	850	\N	F11-F2-521	F2
2263	\N	830	\N	F11-F2-513	F2
2264	\N	829	\N	F11-F2-504	F2
2265	\N	941	\N	F10-F2-495	F2
2266	\N	945	\N	F10-F2-485	F2
2267	\N	1186	\N	F10-F2-473	F2
2268	\N	585	\N	F10-F2-467	F2
2269	\N	630	\N	F10-F2-461	F2
2270	\N	530	\N	F10-F2-456	F2
2271	\N	120	\N	F10-F2-455	F2
2272	\N	600	\N	F10-F2-449	F2
2273	\N	656	\N	F10-F2-442	F2
2274	\N	367	\N	F10-F2-438	F2
2275	\N	287	\N	F10-F2-435	F2
2276	\N	130	\N	F10-F2-434	F2
2277	\N	485	\N	F10-F2-429	F2
2278	\N	395	\N	F10-F2-425	F2
2279	\N	530	\N	F10-F2-420	F2
2280	\N	350	\N	F10-F2-417	F2
2281	\N	968	\N	F09-F2-407	F2
2282	\N	942	\N	F09-F2-397	F2
2283	\N	670	\N	F09-F2-391	F2
2284	\N	530	\N	F09-F2-385	F2
2285	\N	208	\N	F09-F2-383	F2
2286	\N	10	\N	F09-3BTU	F2
2287	\N	193	\N	F09-3BTN	F2
2288	\N	10	\N	F09-1BTN	F2
2289	\N	193	\N	F09-1BTU	F2
2290	\N	111	\N	F09-F2-378	F2
2291	\N	600	\N	F09-F2-372	F2
2292	\N	445	\N	F09-F2-368	F2
2293	\N	410	\N	F09-F2-364	F2
2294	\N	590	\N	F09-F2-358	F2
2295	\N	345	\N	F09-F2-354	F2
2296	\N	545	\N	F09-F2-349	F2
2297	\N	726	\N	F08-F2-342	F2
2298	\N	750	\N	F08-F2-334	F2
2299	\N	885	\N	F08-F2-325	F2
2300	\N	485	\N	F08-F2-320	F2
2301	\N	470	\N	F08-F2-316	F2
2302	\N	345	\N	F08-F2-312	F2
2303	\N	600	\N	F08-F2-306	F2
2304	\N	125	\N	F08-F2-305	F2
2305	\N	10	\N	F08-3BTU	F2
2306	\N	168	\N	F08-3BTN	F2
2307	\N	10	\N	F08-1BTN	F2
2308	\N	168	\N	F08-1BTU	F2
2309	\N	414	\N	F08-F2-298	F2
2310	\N	420	\N	F08-F2-293	F2
2311	\N	1030	\N	F08-F2-283	F2
2312	\N	890	\N	F07-F2-274	F2
2313	\N	415	\N	F07-F2-270	F2
2314	\N	605	\N	F07-F2-264	F2
2315	\N	335	\N	F07-F2-261	F2
2316	\N	385	\N	F07-F2-257	F2
2317	\N	600	\N	F07-F2-253	F2
2318	\N	500	\N	F07-F2-246	F2
2319	\N	120	\N	F07-F2-245	F2
2320	\N	340	\N	F07-F2-241	F2
2321	\N	460	\N	F07-F2-237	F2
2322	\N	1035	\N	F07-F2-226	F2
2323	\N	930	\N	F06-F2-217	F2
2324	\N	635	\N	F06-F2-211	F2
2325	\N	697	\N	F06-F2-204	F2
2326	\N	635	\N	F06-F2-198	F2
2327	\N	511	\N	F06-F2-192	F2
2328	\N	10	\N	F06-3BTU	F2
2329	\N	165	\N	F06-3BTN	F2
2330	\N	10	\N	F06-1BTN	F2
2331	\N	165	\N	F06-1BTU	F2
2332	\N	55	\N	F06-F2-188	F2
2333	\N	600	\N	F06-F2-182	F2
2334	\N	294	\N	F06-F2-179	F2
2335	\N	375	\N	F06-F2-176	F2
2336	\N	598	\N	F06-F2-170	F2
2337	\N	1008	\N	F06-F2-160	F2
2338	\N	1500	\N	F05-F2-145	F2
2339	\N	667	\N	F05-F2-138	F2
2340	\N	700	\N	F05-F2-131	F2
2341	\N	441	\N	F05-F2-127	F2
2342	\N	600	\N	F05-F2-121	F2
2343	\N	59	\N	F05-F2-120	F2
2344	\N	10	\N	F05-3BTU	F2
2345	\N	159	\N	F05-3BTN	F2
2346	\N	10	\N	F05-1BTN	F2
2347	\N	159	\N	F05-1BTU	F2
2348	\N	472	\N	F05-F2-112	F2
2349	\N	475	\N	F05-F2-107	F2
2350	\N	610	\N	F05-F2-101	F2
2351	\N	772	\N	F05-F2-93	F2
2352	\N	600	\N	F04-F2-87	F2
2353	\N	233	\N	F04-F2-85	F2
2354	\N	490	\N	F04-F2-80	F2
2355	\N	603	\N	F04-F2-74	F2
2356	\N	410	\N	F04-F2-69	F2
2357	\N	555	\N	F03-F2-64	F2
2358	\N	560	\N	F03-F2-58	F2
2359	\N	320	\N	F03-F2-55	F2
2360	\N	148	\N	F03-7ABT	F2
2361	\N	10	\N	F03-7TN	F2
2362	\N	138	\N	F03-7TU	F2
2363	\N	52	\N	F03-F2-51	F2
2364	\N	600	\N	F03-F2-45	F2
2365	\N	52	\N	F03-F2-44	F2
2366	\N	10	\N	F03-3BTU	F2
2367	\N	94	\N	F03-3BTN	F2
2368	\N	10	\N	F03-1BTN	F2
2369	\N	94	\N	F03-1BTU	F2
2370	\N	385	\N	F03-F2-39	F2
2371	\N	376	\N	F03-F2-35	F2
2372	\N	279	\N	F03-F2-32	F2
2373	\N	319	\N	F03-F2-29	F2
2374	\N	546	\N	F02-F2-24	F2
2375	\N	185	\N	F02-F2-22	F2
2376	\N	600	\N	F02-F2-16	F2
2377	\N	158	\N	F02-F2-14	F2
2378	\N	387	\N	F02-F2-10	F2
2379	\N	463	\N	F01-F2-6	F2
2380	\N	271	\N	F01-F2-3	F2
2409	\N	115	\N	D98-13TR	G1
2410	\N	151	\N	D98-13BT	G1
2411	\N	832	\N	D98-G1-285	G1
2412	\N	1232	\N	G01-G1-294	G1
2413	\N	611	\N	G01-G1-306	G1
2414	\N	478	\N	G01-G1-312	G1
2415	\N	384	\N	G01-G1-317	G1
2416	\N	592	\N	G01-G1-321	G1
2417	\N	680	\N	G01-G1-327	G1
2418	\N	360	\N	G01-G1-333	G1
2419	\N	244	\N	G01-G1-337	G1
2420	\N	600	\N	G01-G1-339	G1
2421	\N	436	\N	G01-G1-345	G1
2422	\N	412	\N	G01-G1-350	G1
2423	\N	371	\N	G01-G1-354	G1
2424	\N	1159	\N	G02-G1-357	G1
2425	\N	748	\N	G02-G1-369	G1
2426	\N	778	\N	G02-G1-377	G1
2427	\N	967	\N	G02-G1-384	G1
2428	\N	263	\N	G02-G1-394	G1
2429	\N	476	\N	G02-G1-397	G1
2430	\N	292	\N	G02-G1-402	G1
2431	\N	626	\N	G02-G1-404	G1
2432	\N	475	\N	G02-G1-411	G1
2433	\N	176	\N	G02-G1-415	G1
2434	\N	600	\N	G02-G1-417	G1
2435	\N	657	\N	G02-G1-423	G1
2436	\N	444	\N	G02-G1-430	G1
2437	\N	557	\N	G03-G1-434	G1
2438	\N	472	\N	G03-G1-440	G1
2439	\N	410	\N	G03-G1-445	G1
2440	\N	548	\N	G03-G1-449	G1
2441	\N	299	\N	G03-G1-454	G1
2442	\N	245	\N	G03-G1-457	G1
2443	\N	491	\N	G03-G1-460	G1
2444	\N	10	\N	G03-1ATU	G1
2445	\N	191	\N	G03-1ATN	G1
2446	\N	10	\N	G03-3ATN	G1
2447	\N	191	\N	G03-3ATU	G1
2448	\N	90	\N	G03-G1-468	G1
2449	\N	600	\N	G03-G1-469	G1
2450	\N	245	\N	G03-G1-475	G1
2451	\N	276	\N	G03-G1-478	G1
2452	\N	521	\N	G03-G1-481	G1
2453	\N	447	\N	G03-G1-486	G1
2454	\N	436	\N	G03-G1-490	G1
2455	\N	950	\N	G03-G1-495	G1
2456	\N	950	\N	G03-G1-504	G1
2457	\N	800	\N	G04-G1-514	G1
2458	\N	755	\N	G04-G1-522	G1
2459	\N	445	\N	G04-G1-529	G1
2460	\N	410	\N	G04-G1-534	G1
2461	\N	170	\N	G04-G1-538	G1
2462	\N	210	\N	G04-G1-539	G1
2463	\N	409	\N	G04-G1-542	G1
2464	\N	10	\N	G04-1ATU	G1
2465	\N	202	\N	G04-1ATN	G1
2466	\N	10	\N	G04-3ATN	G1
2467	\N	201	\N	G04-3ATU	G1
2468	\N	58	\N	G04-G1-550	G1
2469	\N	600	\N	G04-G1-551	G1
2470	\N	260	\N	G04-G1-556	G1
2471	\N	510	\N	G04-G1-559	G1
2472	\N	410	\N	G04-G1-564	G1
2473	\N	430	\N	G04-G1-568	G1
2474	\N	910	\N	G04-G1-573	G1
2475	\N	700	\N	G04-G1-582	G1
2476	\N	900	\N	G04-G1-589	G1
2477	\N	650	\N	G05-G1-598	G1
2478	\N	240	\N	G05-G1-604	G1
2479	\N	365	\N	G05-G1-607	G1
2480	\N	195	\N	G05-G1-610	G1
2481	\N	607	\N	G05-G1-612	G1
2482	\N	10	\N	G05-1ATU	G1
2483	\N	202	\N	G05-1ATN	G1
2484	\N	10	\N	G05-3ATN	G1
2485	\N	202	\N	G05-3ATU	G1
2486	\N	55	\N	G05-G1-622	G1
2487	\N	600	\N	G05-G1-623	G1
2488	\N	533	\N	G05-G1-629	G1
2489	\N	457	\N	G05-G1-634	G1
2490	\N	198	\N	G05-G1-639	G1
2491	\N	10	\N	G05-5ATU	G1
2492	\N	90	\N	G05-5ATN	G1
2493	\N	94	\N	G05-5ABT	G1
2495	\N	115	\N	D98-15TR	G2
2496	\N	158	\N	D98-15BT	G2
2497	\N	313	\N	G01-G2-285	G2
2498	\N	531	\N	G01-G2-288	G2
2499	\N	920	\N	G01-G2-294	G2
2500	\N	902	\N	G01-G2-303	G2
2501	\N	1123	\N	G01-G2-312	G2
2502	\N	740	\N	G01-G2-323	G2
2503	\N	395	\N	G01-G2-330	G2
2504	\N	235	\N	G01-G2-334	G2
2505	\N	285	\N	G01-G2-337	G2
2506	\N	600	\N	G01-G2-342	G2
2507	\N	443	\N	G01-G2-345	G2
2508	\N	276	\N	G01-G2-350	G2
2509	\N	246	\N	G01-G2-353	G2
2510	\N	357	\N	G02-G2-355	G2
2511	\N	545	\N	G02-G2-359	G2
2512	\N	488	\N	G02-G2-364	G2
2513	\N	990	\N	G02-G2-369	G2
2514	\N	536	\N	G02-G2-379	G2
2515	\N	664	\N	G02-G2-384	G2
2516	\N	566	\N	G02-G2-391	G2
2517	\N	899	\N	G02-G2-397	G2
2518	\N	429	\N	G02-G2-406	G2
2519	\N	222	\N	G02-G2-410	G2
2520	\N	501	\N	G02-G2-412	G2
2521	\N	600	\N	G02-G2-418	G2
2522	\N	163	\N	G02-G2-423	G2
2523	\N	380	\N	G02-G2-425	G2
2524	\N	395	\N	G03-G2-429	G2
2525	\N	385	\N	G03-G2-433	G2
2526	\N	335	\N	G03-G2-436	G2
2527	\N	477	\N	G03-G2-440	G2
2528	\N	405	\N	G03-G2-445	G2
2529	\N	538	\N	G03-G2-449	G2
2530	\N	456	\N	G03-G2-454	G2
2531	\N	583	\N	G03-G2-459	G2
2532	\N	10	\N	G03-3BTU	G2
2533	\N	191	\N	G03-3BTN	G2
2534	\N	10	\N	G03-1BTN	G2
2535	\N	191	\N	G03-1BTU	G2
2536	\N	90	\N	G03-G2-468	G2
2537	\N	600	\N	G03-G2-469	G2
2538	\N	295	\N	G03-G2-475	G2
2539	\N	355	\N	G03-G2-478	G2
2540	\N	392	\N	G03-G2-482	G2
2541	\N	273	\N	G03-G2-486	G2
2542	\N	610	\N	G03-G2-489	G2
2543	\N	590	\N	G03-G2-495	G2
2544	\N	400	\N	G03-G2-501	G2
2545	\N	902	\N	G04-G2-505	G2
2546	\N	690	\N	G04-G2-514	G2
2547	\N	703	\N	G04-G2-521	G2
2548	\N	607	\N	G04-G2-528	G2
2549	\N	400	\N	G04-G2-534	G2
2550	\N	590	\N	G04-G2-538	G2
2551	\N	209	\N	G04-G2-544	G2
2552	\N	10	\N	G04-3BTU	G2
2553	\N	202	\N	G04-3BTN	G2
2554	\N	10	\N	G04-1BTN	G2
2555	\N	201	\N	G04-1BTU	G2
2556	\N	58	\N	G04-G2-550	G2
2557	\N	600	\N	G04-G2-551	G2
2558	\N	232	\N	G04-G2-556	G2
2559	\N	513	\N	G04-G2-559	G2
2560	\N	495	\N	G04-G2-564	G2
2561	\N	370	\N	G04-G2-569	G2
2562	\N	767	\N	G04-G2-573	G2
2563	\N	850	\N	G04-G2-580	G2
2564	\N	450	\N	G05-G2-589	G2
2565	\N	648	\N	G05-G2-593	G2
2566	\N	453	\N	G05-G2-600	G2
2567	\N	742	\N	G05-G2-604	G2
2568	\N	654	\N	G05-G2-612	G2
2569	\N	10	\N	G05-3BTU	G2
2570	\N	208	\N	G05-3BTN	G2
2571	\N	10	\N	G05-1BTN	G2
2572	\N	208	\N	G05-1BTU	G2
2573	\N	55	\N	G05-G2-622	G2
2574	\N	600	\N	G05-G2-623	G2
2575	\N	533	\N	G05-G2-629	G2
2576	\N	458	\N	G05-G2-634	G2
2577	\N	10	\N	G05-7TU	G2
2578	\N	104	\N	G05-7TN	G2
2579	\N	114	\N	G05-7AT	G2
2599	\N	910	\N	J03-J1-884	J1
2600	\N	106	\N	J03-9BT	J1
2601	\N	10	\N	J03-9TN	J1
2602	\N	40	\N	J03-9TU	J1
2603	\N	56	\N	J03-J1-881	J1
2604	\N	600	\N	J03-J1-875	J1
2605	\N	109	\N	J03-J1-874	J1
2606	\N	10	\N	J03-1ATU	J1
2607	\N	200	\N	J03-1ATN	J1
2608	\N	10	\N	J03-3ATN	J1
2609	\N	200	\N	J03-3ATU	J1
2610	\N	724	\N	J03-J1-863	J1
2611	\N	716	\N	J03-J1-856	J1
2612	\N	725	\N	J03-J1-849	J1
2613	\N	737	\N	J03-J1-841	J1
2614	\N	731	\N	J03-J1-834	J1
2615	\N	731	\N	J03-J1-827	J1
2616	\N	734	\N	J03-J1-819	J1
2617	\N	734	\N	J03-J1-812	J1
2618	\N	734	\N	J03-J1-805	J1
2619	\N	734	\N	J03-J1-797	J1
2620	\N	745	\N	J03-J1-790	J1
2621	\N	745	\N	J03-J1-782	J1
2622	\N	640	\N	J03-J1-776	J1
2623	\N	1006	\N	J02-J1-766	J1
2624	\N	840	\N	J02-J1-757	J1
2625	\N	840	\N	J02-J1-749	J1
2626	\N	846	\N	J02-J1-740	J1
2627	\N	845	\N	J02-J1-732	J1
2628	\N	919	\N	J02-J1-723	J1
2629	\N	610	\N	J02-J1-717	J1
2630	\N	730	\N	J02-J1-709	J1
2631	\N	465	\N	J02-J1-705	J1
2632	\N	575	\N	J02-J1-699	J1
2633	\N	460	\N	J02-J1-694	J1
2634	\N	600	\N	J02-J1-688	J1
2635	\N	66	\N	J02-J1-687	J1
2636	\N	10	\N	J02-1ATU	J1
2637	\N	168	\N	J02-1ATN	J1
2638	\N	10	\N	J02-3ATN	J1
2639	\N	167	\N	J02-3ATU	J1
2640	\N	468	\N	J02-J1-680	J1
2641	\N	164	\N	J02-J1-678	J1
2642	\N	846	\N	J02-J1-669	J1
2643	\N	946	\N	J02-J1-660	J1
2644	\N	1000	\N	J02-J1-650	J1
2645	\N	1000	\N	J02-J1-640	J1
2646	\N	1000	\N	J02-J1-630	J1
2647	\N	990	\N	J02-J1-620	J1
2648	\N	1005	\N	J01-J1-610	J1
2649	\N	995	\N	J01-J1-600	J1
2650	\N	660	\N	J01-J1-593	J1
2651	\N	540	\N	J01-J1-588	J1
2652	\N	350	\N	J01-J1-585	J1
2653	\N	450	\N	J01-J1-580	J1
2654	\N	225	\N	J01-J1-578	J1
2655	\N	275	\N	J01-J1-575	J1
2656	\N	600	\N	J01-J1-569	J1
2657	\N	143	\N	J01-J1-568	J1
2658	\N	10	\N	J01-1TU	J1
2659	\N	97	\N	J01-1TN	J1
2660	\N	57	\N	J01-1ABT	J1
2661	\N	468	\N	J01-J1-561	J1
2662	\N	225	\N	J01-J1-559	J1
2663	\N	405	\N	J01-J1-555	J1
2664	\N	635	\N	J01-J1-549	J1
2665	\N	1044	\N	C98-J1-538	J1
2666	\N	43	\N	C98-1ABT	J1
2667	\N	10	\N	C98-1ATN	J1
2668	\N	100	\N	C98-1ATU	J1
2669	\N	488	\N	C98-J1-532	J1
2670	\N	1565	\N	C98-J1-516	J1
2671	\N	1336	\N	C97-J1-503	J1
2672	\N	151	\N	C97-1BT	J1
2673	\N	10	\N	C97-1TR	J1
2674	\N	925	\N	J03-J2-884	J2
2675	\N	106	\N	J03-11BBT	J2
2676	\N	10	\N	J03-11BTN	J2
2677	\N	40	\N	J03-11BTU	J2
2678	\N	57	\N	J03-J2-881	J2
2679	\N	600	\N	J03-J2-875	J2
2680	\N	109	\N	J03-J2-874	J2
2681	\N	10	\N	J03-3BTU	J2
2682	\N	200	\N	J03-3BTN	J2
2683	\N	10	\N	J03-1BTN	J2
2684	\N	200	\N	J03-1BTU	J2
2685	\N	708	\N	J03-J2-863	J2
2686	\N	716	\N	J03-J2-856	J2
2687	\N	725	\N	J03-J2-849	J2
2688	\N	737	\N	J03-J2-841	J2
2689	\N	731	\N	J03-J2-834	J2
2690	\N	731	\N	J03-J2-827	J2
2691	\N	734	\N	J03-J2-819	J2
2692	\N	734	\N	J03-J2-812	J2
2693	\N	734	\N	J03-J2-805	J2
2694	\N	734	\N	J03-J2-797	J2
2695	\N	746	\N	J03-J2-790	J2
2696	\N	745	\N	J03-J2-782	J2
2697	\N	658	\N	J02-J2-776	J2
2698	\N	1005	\N	J02-J2-766	J2
2699	\N	840	\N	J02-J2-757	J2
2700	\N	840	\N	J02-J2-749	J2
2701	\N	846	\N	J02-J2-740	J2
2702	\N	845	\N	J02-J2-732	J2
2703	\N	919	\N	J02-J2-723	J2
2704	\N	610	\N	J02-J2-717	J2
2705	\N	710	\N	J02-J2-710	J2
2706	\N	760	\N	J02-J2-702	J2
2707	\N	290	\N	J02-J2-699	J2
2708	\N	470	\N	J02-J2-694	J2
2709	\N	600	\N	J02-J2-688	J2
2710	\N	66	\N	J02-J2-687	J2
2711	\N	10	\N	J02-3BTU	J2
2712	\N	168	\N	J02-3BTN	J2
2713	\N	10	\N	J02-1BTN	J2
2714	\N	167	\N	J02-1BTU	J2
2715	\N	469	\N	J02-J2-680	J2
2716	\N	330	\N	J02-J2-676	J2
2717	\N	680	\N	J02-J2-669	J2
2718	\N	540	\N	J02-J2-664	J2
2719	\N	400	\N	J02-J2-660	J2
2720	\N	1000	\N	J02-J2-650	J2
2721	\N	1000	\N	J02-J2-640	J2
2722	\N	1000	\N	J02-J2-630	J2
2723	\N	1000	\N	J01-J2-620	J2
2724	\N	1000	\N	J01-J2-610	J2
2725	\N	1000	\N	J01-J2-600	J2
2726	\N	660	\N	J01-J2-593	J2
2727	\N	230	\N	J01-J2-591	J2
2728	\N	575	\N	J01-J2-585	J2
2729	\N	235	\N	J01-J2-583	J2
2730	\N	365	\N	J01-J2-579	J2
2731	\N	435	\N	J01-J2-575	J2
2732	\N	600	\N	J01-J2-569	J2
2733	\N	143	\N	J01-J2-568	J2
2734	\N	10	\N	J01-3TU	J2
2735	\N	72	\N	J01-3TN	J2
2736	\N	82	\N	J01-3ABT	J2
2737	\N	193	\N	J01-J2-564	J2
2738	\N	400	\N	J01-J2-560	J2
2739	\N	425	\N	J01-J2-556	J2
2740	\N	715	\N	C98-J2-549	J2
2741	\N	360	\N	C98-J2-545	J2
2742	\N	684	\N	C98-J2-538	J2
2743	\N	83	\N	C98-3BBT	J2
2744	\N	10	\N	C98-3BTN	J2
2745	\N	71	\N	C98-3BTU	J2
2746	\N	800	\N	C98-J2-529	J2
2747	\N	230	\N	C98-J2-526	J2
2748	\N	596	\N	C98-J2-520	J2
2749	\N	414	\N	C97-J2-516	J2
2750	\N	1336	\N	C97-J2-503	J2
2751	\N	151	\N	C97-3BT	J2
2752	\N	10	\N	C97-3TR	J2
2769	\N	616	\N	K08-K1-798	K1
2770	\N	51	\N	K08-K1-797	K1
2771	\N	626	\N	K08-K1-791	K1
2772	\N	625	\N	K08-K1-784	K1
2773	\N	146	\N	K08-K1-783	K1
2774	\N	600	\N	K08-K1-781	K1
2775	\N	53	\N	K08-K1-776	K1
2776	\N	10	\N	K08-1ATU	K1
2777	\N	199	\N	K08-1ATN	K1
2778	\N	10	\N	K08-3ATN	K1
2779	\N	200	\N	K08-3ATU	K1
2780	\N	364	\N	K08-K1-768	K1
2781	\N	710	\N	K08-K1-761	K1
2782	\N	917	\N	K08-K1-752	K1
2783	\N	917	\N	K08-K1-743	K1
2784	\N	919	\N	K08-K1-734	K1
2785	\N	920	\N	K08-K1-725	K1
2786	\N	790	\N	K08-K1-717	K1
2787	\N	790	\N	K08-K1-709	K1
2788	\N	797	\N	K07-K1-701	K1
2789	\N	797	\N	K07-K1-693	K1
2790	\N	746	\N	K07-K1-686	K1
2791	\N	1177	\N	K07-K1-674	K1
2792	\N	665	\N	K07-K1-667	K1
2793	\N	558	\N	K07-K1-662	K1
2794	\N	501	\N	K07-K1-656	K1
2795	\N	525	\N	K07-K1-651	K1
2796	\N	600	\N	K07-K1-645	K1
2797	\N	464	\N	K07-K1-641	K1
2798	\N	682	\N	K07-K1-634	K1
2799	\N	1349	\N	K07-K1-620	K1
2800	\N	903	\N	K07-K1-611	K1
2801	\N	887	\N	K07-K1-602	K1
2802	\N	1111	\N	K07-K1-591	K1
2803	\N	600	\N	K07-K1-585	K1
2804	\N	851	\N	K06-K1-577	K1
2805	\N	860	\N	K06-K1-568	K1
2806	\N	549	\N	K06-K1-563	K1
2807	\N	1493	\N	K06-K1-548	K1
2808	\N	376	\N	K06-K1-544	K1
2809	\N	521	\N	K06-K1-538	K1
2810	\N	393	\N	K06-K1-534	K1
2811	\N	603	\N	K06-K1-528	K1
2812	\N	10	\N	K06-5ATU	K1
2813	\N	100	\N	K06-5ATN	K1
2814	\N	10	\N	K06-7ATN	K1
2815	\N	101	\N	K06-7ATU	K1
2816	\N	175	\N	K06-K1-524	K1
2817	\N	600	\N	K06-K1-523	K1
2818	\N	133	\N	K06-K1-517	K1
2819	\N	566	\N	K06-K1-511	K1
2820	\N	133	\N	K06-9ABT	K1
2821	\N	10	\N	K06-9TN	K1
2822	\N	123	\N	K06-9TU	K1
2823	\N	329	\N	K06-K1-505	K1
2824	\N	150	\N	K06-K1-504	K1
2825	\N	150	\N	K06-K1-502	K1
2826	\N	724	\N	K98-K1-495	K1
2827	\N	405	\N	K98-K1-491	K1
2828	\N	151	\N	K98-5ABT	K1
2829	\N	10	\N	K98-5TN	K1
2830	\N	141	\N	K98-5TU	K1
2831	\N	51	\N	K98-K1-487	K1
2832	\N	10	\N	K98-1ATU	K1
2833	\N	126	\N	K98-1ATN	K1
2834	\N	10	\N	K98-3ATN	K1
2835	\N	126	\N	K98-3ATU	K1
2836	\N	1070	\N	K98-K1-474	K1
2837	\N	909	\N	K98-K1-465	K1
2838	\N	1126	\N	K05-K1-454	K1
2839	\N	1125	\N	K05-K1-442	K1
2840	\N	1266	\N	K05-K1-430	K1
2841	\N	531	\N	K05-K1-424	K1
2842	\N	517	\N	K05-K1-419	K1
2843	\N	426	\N	K05-K1-415	K1
2844	\N	600	\N	K05-K1-409	K1
2845	\N	331	\N	K05-K1-406	K1
2846	\N	10	\N	K05-1ATU	K1
2847	\N	167	\N	K05-1ATN	K1
2848	\N	10	\N	K05-3ATN	K1
2849	\N	167	\N	K05-3ATU	K1
2850	\N	564	\N	K05-K1-397	K1
2851	\N	796	\N	K05-K1-389	K1
2852	\N	870	\N	K05-K1-380	K1
2853	\N	870	\N	K05-K1-371	K1
2854	\N	900	\N	K05-K1-362	K1
2855	\N	900	\N	K05-K1-353	K1
2856	\N	817	\N	K05-K1-345	K1
2857	\N	816	\N	K05-K1-337	K1
2858	\N	830	\N	K04-K1-329	K1
2859	\N	980	\N	K04-K1-319	K1
2860	\N	711	\N	K04-K1-312	K1
2861	\N	1069	\N	K04-K1-301	K1
2862	\N	298	\N	K04-K1-298	K1
2863	\N	219	\N	K04-K1-296	K1
2864	\N	205	\N	K04-K1-294	K1
2865	\N	240	\N	K04-K1-291	K1
2866	\N	125	\N	K04-K1-290	K1
2867	\N	143	\N	K04-K1-289	K1
2868	\N	259	\N	K04-K1-286	K1
2869	\N	259	\N	K04-K1-284	K1
2870	\N	600	\N	K04-K1-282	K1
2871	\N	108	\N	K04-K1-276	K1
2872	\N	10	\N	K04-1ATU	K1
2873	\N	121	\N	K04-1ATN	K1
2874	\N	10	\N	K04-3ATN	K1
2875	\N	119	\N	K04-3ATU	K1
2876	\N	114	\N	K04-K1-273	K1
2877	\N	247	\N	K04-K1-270	K1
2878	\N	223	\N	K04-K1-268	K1
2879	\N	117	\N	K04-K1-267	K1
2880	\N	218	\N	K04-K1-265	K1
2881	\N	219	\N	K04-K1-262	K1
2882	\N	224	\N	K04-K1-260	K1
2883	\N	217	\N	K03-K1-258	K1
2884	\N	216	\N	K03-K1-256	K1
2885	\N	217	\N	K03-K1-254	K1
2886	\N	600	\N	K03-K1-252	K1
2887	\N	54	\N	K03-K1-247	K1
2888	\N	219	\N	K03-K1-245	K1
2889	\N	212	\N	K03-K1-243	K1
2890	\N	204	\N	K03-K1-241	K1
2891	\N	137	\N	K03-K1-240	K1
2892	\N	211	\N	K03-K1-237	K1
2893	\N	207	\N	K02-K1-235	K1
2894	\N	173	\N	K02-K1-234	K1
2895	\N	153	\N	K02-K1-232	K1
2896	\N	112	\N	K02-K1-231	K1
2897	\N	191	\N	K02-K1-229	K1
2898	\N	600	\N	K02-K1-227	K1
2899	\N	51	\N	K02-K1-222	K1
2900	\N	10	\N	K02-1ATU	K1
2901	\N	90	\N	K02-1ATN	K1
2902	\N	10	\N	K02-3ATN	K1
2903	\N	102	\N	K02-3ATU	K1
2904	\N	160	\N	K02-K1-219	K1
2905	\N	168	\N	K02-K1-217	K1
2906	\N	128	\N	K02-K1-216	K1
2907	\N	160	\N	K02-K1-214	K1
2908	\N	185	\N	K02-K1-212	K1
2909	\N	503	\N	K02-K1-207	K1
2910	\N	520	\N	K01-K1-202	K1
2911	\N	600	\N	K01-K1-201	K1
2912	\N	156	\N	K01-K1-195	K1
2913	\N	298	\N	K01-K1-192	K1
2914	\N	629	\N	K01-K1-184	K1
2915	\N	409	\N	K01-K1-181	K1
2916	\N	449	\N	K01-K1-177	K1
2917	\N	373	\N	K01-K1-173	K1
2918	\N	265	\N	K01-K1-170	K1
2919	\N	547	\N	K01-K1-165	K1
2920	\N	347	\N	C05-K1-161	K1
2921	\N	398	\N	C05-K1-158	K1
2922	\N	248	\N	C05-K1-156	K1
2923	\N	262	\N	C05-K1-153	K1
2924	\N	213	\N	C05-K1-150	K1
2925	\N	278	\N	C05-K1-148	K1
2926	\N	116	\N	C05-1BT	K1
2927	\N	10	\N	C05-1TR	K1
2928	\N	616	\N	K08-K2-798	K2
2929	\N	51	\N	K08-K2-797	K2
2930	\N	626	\N	K08-K2-791	K2
2931	\N	626	\N	K08-K2-784	K2
2932	\N	149	\N	K08-K2-783	K2
2933	\N	600	\N	K08-K2-777	K2
2934	\N	53	\N	K08-K2-776	K2
2935	\N	10	\N	K08-3BTU	K2
2936	\N	199	\N	K08-3BTN	K2
2937	\N	10	\N	K08-1BTN	K2
2938	\N	200	\N	K08-1BTU	K2
2939	\N	571	\N	K08-K2-766	K2
2940	\N	487	\N	K08-K2-762	K2
2941	\N	358	\N	K08-K2-758	K2
2942	\N	1496	\N	K08-K2-743	K2
2943	\N	564	\N	K08-K2-737	K2
2944	\N	1275	\N	K08-K2-725	K2
2945	\N	790	\N	K08-K2-717	K2
2946	\N	790	\N	K07-K2-709	K2
2947	\N	1000	\N	K07-K2-699	K2
2948	\N	600	\N	K07-K2-693	K2
2949	\N	964	\N	K07-K2-683	K2
2950	\N	964	\N	K07-K2-674	K2
2951	\N	1102	\N	K07-K2-663	K2
2952	\N	606	\N	K07-K2-656	K2
2953	\N	525	\N	K07-K2-651	K2
2954	\N	600	\N	K07-K2-645	K2
2955	\N	264	\N	K07-K2-643	K2
2956	\N	560	\N	K07-K2-637	K2
2957	\N	435	\N	K07-K2-633	K2
2958	\N	431	\N	K07-K2-628	K2
2959	\N	803	\N	K07-K2-620	K2
2960	\N	894	\N	K07-K2-611	K2
2961	\N	894	\N	K07-K2-602	K2
2962	\N	856	\N	K07-K2-594	K2
2963	\N	855	\N	K06-K2-585	K2
2964	\N	957	\N	K06-K2-576	K2
2965	\N	754	\N	K06-K2-568	K2
2966	\N	1031	\N	K06-K2-558	K2
2967	\N	1031	\N	K06-K2-548	K2
2968	\N	675	\N	K06-K2-541	K2
2969	\N	679	\N	K06-K2-534	K2
2970	\N	566	\N	K06-K2-528	K2
2971	\N	10	\N	K06-17BTU	K2
2972	\N	100	\N	K06-17BTN	K2
2973	\N	10	\N	K06-15BTN	K2
2974	\N	101	\N	K06-15BTU	K2
2975	\N	175	\N	K06-K2-524	K2
2976	\N	600	\N	K06-K2-518	K2
2977	\N	724	\N	K06-K2-511	K2
2978	\N	138	\N	K06-11BBT	K2
2979	\N	10	\N	K06-11BTN	K2
2980	\N	129	\N	K06-11BTU	K2
2981	\N	318	\N	K06-K2-505	K2
2982	\N	150	\N	K06-K2-504	K2
2983	\N	150	\N	K98-K2-502	K2
2984	\N	702	\N	K98-K2-495	K2
2985	\N	427	\N	K98-K2-491	K2
2986	\N	151	\N	K98-7ABT	K2
2987	\N	10	\N	K98-7TN	K2
2988	\N	141	\N	K98-7TU	K2
2989	\N	51	\N	K98-K2-487	K2
2990	\N	10	\N	K98-3BTU	K2
2991	\N	126	\N	K98-3BTN	K2
2992	\N	10	\N	K98-1BTN	K2
2993	\N	126	\N	K98-1BTU	K2
2994	\N	915	\N	K98-K2-476	K2
2995	\N	1070	\N	K05-K2-465	K2
2996	\N	1025	\N	K05-K2-455	K2
2997	\N	1226	\N	K05-K2-442	K2
2998	\N	1258	\N	K05-K2-430	K2
2999	\N	529	\N	K05-K2-424	K2
3000	\N	943	\N	K05-K2-415	K2
3001	\N	600	\N	K05-K2-409	K2
3002	\N	331	\N	K05-K2-406	K2
3003	\N	10	\N	K05-3BTU	K2
3004	\N	167	\N	K05-3BTN	K2
3005	\N	10	\N	K05-1BTN	K2
3006	\N	167	\N	K05-1BTU	K2
3007	\N	794	\N	K05-K2-395	K2
3008	\N	626	\N	K05-K2-389	K2
3009	\N	1059	\N	K05-K2-378	K2
3010	\N	681	\N	K05-K2-371	K2
3011	\N	897	\N	K05-K2-362	K2
3012	\N	896	\N	K05-K2-353	K2
3013	\N	816	\N	K05-K2-345	K2
3014	\N	817	\N	K04-K2-337	K2
3015	\N	813	\N	K04-K2-329	K2
3016	\N	989	\N	K04-K2-319	K2
3017	\N	724	\N	K04-K2-312	K2
3018	\N	1064	\N	K04-K2-301	K2
3019	\N	633	\N	K04-K2-295	K2
3020	\N	454	\N	K04-K2-290	K2
3021	\N	382	\N	K04-K2-286	K2
3022	\N	279	\N	K04-K2-284	K2
3023	\N	600	\N	K04-K2-278	K2
3024	\N	108	\N	K04-K2-276	K2
3025	\N	10	\N	K04-3BTU	K2
3026	\N	121	\N	K04-3BTN	K2
3027	\N	10	\N	K04-1BTN	K2
3028	\N	119	\N	K04-1BTU	K2
3029	\N	261	\N	K04-K2-271	K2
3030	\N	298	\N	K04-K2-268	K2
3031	\N	298	\N	K04-K2-265	K2
3032	\N	292	\N	K04-K2-262	K2
3033	\N	186	\N	K03-K2-261	K2
3034	\N	268	\N	K03-K2-258	K2
3035	\N	221	\N	K03-K2-256	K2
3036	\N	182	\N	K03-K2-254	K2
3037	\N	600	\N	K03-K2-248	K2
3038	\N	131	\N	K03-K2-247	K2
3039	\N	126	\N	K03-K2-245	K2
3040	\N	257	\N	K03-K2-243	K2
3041	\N	212	\N	K03-K2-241	K2
3042	\N	155	\N	K02-K2-239	K2
3043	\N	202	\N	K02-K2-237	K2
3044	\N	163	\N	K02-K2-235	K2
3045	\N	146	\N	K02-K2-234	K2
3046	\N	206	\N	K02-K2-232	K2
3047	\N	274	\N	K02-K2-229	K2
3048	\N	600	\N	K02-K2-223	K2
3049	\N	51	\N	K02-K2-222	K2
3050	\N	10	\N	K02-3BTU	K2
3051	\N	90	\N	K02-3BTN	K2
3052	\N	10	\N	K02-1BTN	K2
3053	\N	102	\N	K02-1BTU	K2
3054	\N	251	\N	K02-K2-218	K2
3055	\N	185	\N	K02-K2-216	K2
3056	\N	178	\N	K02-K2-214	K2
3057	\N	354	\N	K02-K2-211	K2
3058	\N	248	\N	K01-K2-208	K2
3059	\N	310	\N	K01-K2-205	K2
3060	\N	297	\N	K01-K2-202	K2
3061	\N	600	\N	K01-K2-196	K2
3062	\N	113	\N	K01-K2-195	K2
3063	\N	348	\N	K01-K2-192	K2
3064	\N	289	\N	K01-K2-189	K2
3065	\N	330	\N	K01-K2-185	K2
3066	\N	328	\N	K01-K2-182	K2
3067	\N	585	\N	K01-K2-176	K2
3068	\N	590	\N	K01-K2-170	K2
3069	\N	1064	\N	C05-K2-160	K2
3070	\N	403	\N	C05-K2-156	K2
3071	\N	147	\N	C05-K2-154	K2
3072	\N	193	\N	C05-K2-152	K2
3073	\N	185	\N	C05-K2-150	K2
3074	\N	283	\N	C05-K2-148	K2
3075	\N	94	\N	C05-3BT	K2
3076	\N	10	\N	C05-3TR	K2
3105	\N	10	\N	C07-1TR	L1
3106	\N	95	\N	C07-1BT	L1
3107	\N	293	\N	C07-L1-253	L1
3108	\N	369	\N	C07-L1-249	L1
3109	\N	329	\N	C07-L1-154	L1
3110	\N	1360	\N	C07-L1-141	L1
3111	\N	1060	\N	C07-L1-130	L1
3112	\N	715	\N	C07-L1-123	L1
3113	\N	675	\N	C07-L1-116	L1
3114	\N	1080	\N	C07-L1-106	L1
3115	\N	742	\N	F03-L1-98	L1
3116	\N	1085	\N	F03-L1-88	L1
3117	\N	808	\N	F03-L1-80	L1
3118	\N	944	\N	F03-L1-71	L1
3119	\N	910	\N	F03-L1-62	L1
3120	\N	515	\N	F03-L1-57	L1
3121	\N	200	\N	F03-L1-55	L1
3122	\N	297	\N	F03-5BT	L1
3123	\N	10	\N	F03-5TR	L1
3124	\N	10	\N	C07-3TR	L2
3125	\N	234	\N	C07-3BT	L2
3126	\N	604	\N	C07-L2-249	L2
3127	\N	246	\N	C07-L2-155	L2
3128	\N	301	\N	C07-L2-152	L2
3129	\N	224	\N	C07-L2-150	L2
3130	\N	941	\N	C07-L2-141	L2
3131	\N	800	\N	C07-L2-133	L2
3132	\N	960	\N	C07-L2-123	L2
3133	\N	750	\N	C07-L2-116	L2
3134	\N	751	\N	F03-L2-108	L2
3135	\N	267	\N	F03-L2-106	L2
3136	\N	1205	\N	F03-L2-94	L2
3137	\N	621	\N	F03-L2-88	L2
3138	\N	958	\N	F03-L2-78	L2
3139	\N	700	\N	F03-L2-71	L2
3140	\N	572	\N	F03-L2-65	L2
3141	\N	300	\N	F03-L2-62	L2
3142	\N	502	\N	F03-L2-57	L2
3143	\N	251	\N	F03-L2-55	L2
3144	\N	148	\N	F03-7BT	L2
3145	\N	10	\N	F03-7TR	L2
3146	\N	1054	\N	N06-N1-1094	N1
3147	\N	10	\N	N06-5ATU	N1
3148	\N	150	\N	N06-5ATN	N1
3149	\N	159	\N	N06-5ABT	N1
3150	\N	658	\N	N06-N1-1084	N1
3151	\N	159	\N	N06-9ABT	N1
3152	\N	10	\N	N06-9TN	N1
3153	\N	149	\N	N06-9TU	N1
3154	\N	153	\N	N06-N1-1080	N1
3155	\N	600	\N	N06-N1-1074	N1
3156	\N	317	\N	N06-N1-1071	N1
3157	\N	900	\N	N06-N1-1061	N1
3158	\N	901	\N	N06-N1-1053	N1
3159	\N	560	\N	N06-N1-1047	N1
3160	\N	500	\N	N06-N1-1042	N1
3161	\N	1050	\N	N95-N1-1031	N1
3162	\N	979	\N	N95-N1-1022	N1
3163	\N	977	\N	N95-N1-1012	N1
3164	\N	10	\N	N95-1ATU	N1
3165	\N	124	\N	N95-1ATN	N1
3166	\N	135	\N	N95-1ABT	N1
3167	\N	134	\N	N95-3ABT	N1
3168	\N	10	\N	N95-3ATN	N1
3169	\N	125	\N	N95-3ATU	N1
3170	\N	786	\N	N95-N1-998	N1
3171	\N	387	\N	N95-N1-995	N1
3172	\N	400	\N	N95-N1-991	N1
3173	\N	805	\N	N95-N1-983	N1
3174	\N	804	\N	N94-N1-975	N1
3175	\N	976	\N	N94-N1-965	N1
3176	\N	975	\N	N94-N1-955	N1
3177	\N	1020	\N	N94-N1-945	N1
3178	\N	660	\N	N94-N1-938	N1
3179	\N	360	\N	N94-N1-935	N1
3180	\N	948	\N	N93-N1-925	N1
3181	\N	944	\N	N93-N1-916	N1
3182	\N	707	\N	N93-N1-909	N1
3183	\N	706	\N	N93-N1-902	N1
3184	\N	396	\N	N93-N1-898	N1
3185	\N	10	\N	N93-1ATU	N1
3186	\N	129	\N	N93-1ATN	N1
3187	\N	139	\N	N93-1ABT	N1
3188	\N	139	\N	N93-3ABT	N1
3189	\N	10	\N	N93-3ATN	N1
3190	\N	129	\N	N93-3ATU	N1
3191	\N	790	\N	N93-N1-884	N1
3192	\N	789	\N	N93-N1-876	N1
3193	\N	300	\N	N93-N1-873	N1
3194	\N	755	\N	N05-N1-866	N1
3195	\N	1028	\N	N05-N1-856	N1
3196	\N	862	\N	N05-N1-847	N1
3197	\N	863	\N	N05-N1-839	N1
3198	\N	629	\N	N05-N1-832	N1
3199	\N	1021	\N	N05-N1-822	N1
3200	\N	825	\N	N05-N1-814	N1
3201	\N	415	\N	N05-N1-810	N1
3202	\N	410	\N	N04-N1-806	N1
3203	\N	478	\N	N04-N1-801	N1
3204	\N	727	\N	N04-N1-793	N1
3205	\N	591	\N	N04-N1-787	N1
3206	\N	602	\N	N04-N1-781	N1
3207	\N	10	\N	N04-1ATU	N1
3208	\N	110	\N	N04-1ATN	N1
3209	\N	10	\N	N04-3ATN	N1
3210	\N	111	\N	N04-3ATU	N1
3211	\N	231	\N	N04-N1-777	N1
3212	\N	316	\N	N04-N1-773	N1
3213	\N	233	\N	N04-N1-771	N1
3214	\N	600	\N	N04-N1-765	N1
3215	\N	761	\N	N04-N1-761	N1
3216	\N	358	\N	N04-N1-758	N1
3217	\N	600	\N	N04-N1-752	N1
3218	\N	790	\N	N03-N1-744	N1
3219	\N	610	\N	N03-N1-738	N1
3220	\N	303	\N	N03-N1-735	N1
3221	\N	600	\N	N03-N1-729	N1
3222	\N	739	\N	N03-N1-722	N1
3223	\N	470	\N	N03-N1-717	N1
3224	\N	270	\N	N03-N1-715	N1
3225	\N	624	\N	N02-N1-708	N1
3226	\N	615	\N	N02-N1-702	N1
3227	\N	10	\N	N02-1ATU	N1
3228	\N	202	\N	N02-1ATN	N1
3229	\N	10	\N	N02-3ATN	N1
3230	\N	202	\N	N02-3ATU	N1
3231	\N	203	\N	N02-N1-696	N1
3232	\N	600	\N	N02-N1-690	N1
3233	\N	844	\N	N02-N1-681	N1
3234	\N	654	\N	N02-N1-675	N1
3235	\N	661	\N	N01-N1-668	N1
3236	\N	390	\N	N01-N1-664	N1
3237	\N	305	\N	N01-N1-661	N1
3238	\N	600	\N	N01-N1-655	N1
3239	\N	569	\N	N01-N1-650	N1
3240	\N	190	\N	N01-N1-648	N1
3241	\N	201	\N	N01-N1-646	N1
3242	\N	10	\N	N01-1ATU	N1
3243	\N	115	\N	N01-1ATN	N1
3244	\N	10	\N	N01-3ATN	N1
3245	\N	115	\N	N01-3ATU	N1
3246	\N	580	\N	N01-N1-637	N1
3247	\N	669	\N	N01-N1-631	N1
3248	\N	678	\N	N01-N1-624	N1
3249	\N	423	\N	N01-N1-620	N1
3250	\N	500	\N	N01-N1-615	N1
3251	\N	517	\N	N01-N1-609	N1
3252	\N	633	\N	N92-N1-603	N1
3253	\N	750	\N	N92-N1-596	N1
3254	\N	1050	\N	N92-N1-585	N1
3255	\N	819	\N	N92-N1-577	N1
3256	\N	410	\N	N92-N1-573	N1
3257	\N	409	\N	N92-N1-569	N1
3258	\N	192	\N	N92-N1-567	N1
3259	\N	10	\N	N92-1ATU	N1
3260	\N	129	\N	N92-1ATN	N1
3261	\N	139	\N	N92-1ABT	N1
3262	\N	139	\N	N92-3ABT	N1
3263	\N	10	\N	N92-3ATN	N1
3264	\N	129	\N	N92-3ATU	N1
3265	\N	568	\N	N92-N1-556	N1
3266	\N	500	\N	N92-N1-551	N1
3267	\N	250	\N	N91-N1-548	N1
3268	\N	615	\N	N91-N1-542	N1
3269	\N	10	\N	N91-5ATU	N1
3270	\N	140	\N	N91-5ATN	N1
3271	\N	150	\N	N91-5ABT	N1
3272	\N	425	\N	N91-N1-535	N1
3273	\N	415	\N	N91-N1-530	N1
3274	\N	1027	\N	N91-N1-522	N1
3275	\N	1026	\N	N91-N1-511	N1
3276	\N	844	\N	K98-N1-503	N1
3277	\N	850	\N	K98-N1-494	N1
3278	\N	298	\N	K98-N1-491	N1
3279	\N	10	\N	K98-5T	N1
3280	\N	0	\N	K98-5TR	N1
3281	\N	1065	\N	N06-N2-1094	N2
3282	\N	10	\N	N06-7TU	N2
3283	\N	149	\N	N06-7TN	N2
3284	\N	160	\N	N06-7ABT	N2
3285	\N	658	\N	N06-N2-1084	N2
3286	\N	119	\N	N06-11BBT	N2
3287	\N	10	\N	N06-11BTN	N2
3288	\N	109	\N	N06-11BTU	N2
3289	\N	153	\N	N06-N2-1080	N2
3290	\N	600	\N	N06-N2-1074	N2
3291	\N	317	\N	N06-N2-1071	N2
3292	\N	779	\N	N06-N2-1063	N2
3293	\N	389	\N	N06-N2-1059	N2
3294	\N	390	\N	N06-N2-1055	N2
3295	\N	232	\N	N06-N2-1053	N2
3296	\N	498	\N	N06-N2-1048	N2
3297	\N	582	\N	N95-N2-1042	N2
3298	\N	1050	\N	N95-N2-1031	N2
3299	\N	979	\N	N95-N2-1022	N2
3300	\N	977	\N	N95-N2-1012	N2
3301	\N	134	\N	N95-1BBT	N2
3302	\N	10	\N	N95-1BTN	N2
3303	\N	124	\N	N95-1BTU	N2
3304	\N	10	\N	N95-3BTU	N2
3305	\N	125	\N	N95-3BTN	N2
3306	\N	135	\N	N95-3BBT	N2
3307	\N	793	\N	N95-N2-999	N2
3308	\N	393	\N	N95-N2-995	N2
3309	\N	400	\N	N95-N2-991	N2
3310	\N	805	\N	N94-N2-983	N2
3311	\N	804	\N	N94-N2-975	N2
3312	\N	976	\N	N94-N2-965	N2
3313	\N	975	\N	N94-N2-955	N2
3314	\N	1020	\N	N94-N2-945	N2
3315	\N	660	\N	N94-N2-938	N2
3316	\N	360	\N	N93-N2-935	N2
3317	\N	943	\N	N93-N2-925	N2
3318	\N	942	\N	N93-N2-916	N2
3319	\N	906	\N	N93-N2-907	N2
3320	\N	903	\N	N93-N2-898	N2
3321	\N	134	\N	N93-1BBT	N2
3322	\N	10	\N	N93-1BTN	N2
3323	\N	124	\N	N93-1BTU	N2
3324	\N	10	\N	N93-3BTU	N2
3325	\N	124	\N	N93-3BTN	N2
3326	\N	134	\N	N93-3BBT	N2
3327	\N	259	\N	N93-N2-890	N2
3328	\N	700	\N	N93-N2-883	N2
3329	\N	632	\N	N93-N2-876	N2
3330	\N	300	\N	N05-N2-873	N2
3331	\N	585	\N	N05-N2-868	N2
3332	\N	884	\N	N05-N2-859	N2
3333	\N	351	\N	N05-N2-855	N2
3334	\N	835	\N	N05-N2-847	N2
3335	\N	835	\N	N05-N2-839	N2
3336	\N	638	\N	N05-N2-832	N2
3337	\N	650	\N	N05-N2-826	N2
3338	\N	362	\N	N05-N2-822	N2
3339	\N	825	\N	N05-N2-814	N2
3340	\N	415	\N	N04-N2-810	N2
3341	\N	410	\N	N04-N2-806	N2
3342	\N	694	\N	N04-N2-799	N2
3343	\N	531	\N	N04-N2-793	N2
3344	\N	595	\N	N04-N2-787	N2
3345	\N	598	\N	N04-N2-781	N2
3346	\N	10	\N	N04-3BTU	N2
3347	\N	110	\N	N04-3BTN	N2
3348	\N	10	\N	N04-1BTN	N2
3349	\N	111	\N	N04-1BTU	N2
3350	\N	231	\N	N04-N2-777	N2
3351	\N	549	\N	N04-N2-771	N2
3352	\N	600	\N	N04-N2-765	N2
3353	\N	731	\N	N04-N2-758	N2
3354	\N	400	\N	N03-N2-754	N2
3355	\N	600	\N	N03-N2-748	N2
3356	\N	498	\N	N03-N2-743	N2
3357	\N	502	\N	N03-N2-738	N2
3358	\N	303	\N	N03-N2-735	N2
3359	\N	600	\N	N03-N2-729	N2
3360	\N	714	\N	N03-N2-722	N2
3361	\N	413	\N	N03-N2-718	N2
3362	\N	300	\N	N02-N2-715	N2
3363	\N	590	\N	N02-N2-709	N2
3364	\N	658	\N	N02-N2-702	N2
3365	\N	10	\N	N02-3BTU	N2
3366	\N	202	\N	N02-3BTN	N2
3367	\N	10	\N	N02-1BTN	N2
3368	\N	202	\N	N02-1BTU	N2
3369	\N	203	\N	N02-N2-696	N2
3370	\N	600	\N	N02-N2-690	N2
3371	\N	462	\N	N02-N2-685	N2
3372	\N	371	\N	N02-N2-681	N2
3373	\N	851	\N	N01-N2-673	N2
3374	\N	461	\N	N01-N2-668	N2
3375	\N	390	\N	N01-N2-664	N2
3376	\N	305	\N	N01-N2-661	N2
3377	\N	600	\N	N01-N2-655	N2
3378	\N	233	\N	N01-N2-653	N2
3379	\N	235	\N	N01-N2-651	N2
3380	\N	127	\N	N01-N2-649	N2
3381	\N	357	\N	N01-N2-646	N2
3382	\N	10	\N	N01-3BTU	N2
3383	\N	115	\N	N01-3BTN	N2
3384	\N	10	\N	N01-1BTN	N2
3385	\N	115	\N	N01-1BTU	N2
3386	\N	603	\N	N01-N2-637	N2
3387	\N	885	\N	N01-N2-628	N2
3388	\N	443	\N	N01-N2-624	N2
3389	\N	442	\N	N01-N2-620	N2
3390	\N	280	\N	N01-N2-617	N2
3391	\N	688	\N	N92-N2-610	N2
3392	\N	692	\N	N92-N2-603	N2
3393	\N	900	\N	N92-N2-594	N2
3394	\N	900	\N	N92-N2-585	N2
3395	\N	915	\N	N92-N2-576	N2
3396	\N	912	\N	N92-N2-567	N2
3397	\N	134	\N	N92-1BBT	N2
3398	\N	10	\N	N92-1BTN	N2
3399	\N	125	\N	N92-1BTU	N2
3400	\N	10	\N	N92-3BTU	N2
3401	\N	123	\N	N92-3BTN	N2
3402	\N	134	\N	N92-3BBT	N2
3403	\N	587	\N	N92-N2-556	N2
3404	\N	500	\N	N91-N2-551	N2
3405	\N	250	\N	N91-N2-548	N2
3406	\N	760	\N	N91-N2-540	N2
3407	\N	10	\N	N91-7ATU	N2
3408	\N	118	\N	N91-7ATN	N2
3409	\N	129	\N	N91-7ABT	N2
3410	\N	591	\N	N91-N2-532	N2
3411	\N	281	\N	N91-N2-529	N2
3412	\N	111	\N	N91-N2-528	N2
3413	\N	308	\N	N91-N2-525	N2
3414	\N	486	\N	N91-N2-520	N2
3415	\N	795	\N	K98-N2-512	N2
3416	\N	932	\N	K98-N2-503	N2
3417	\N	605	\N	K98-N2-497	N2
3418	\N	700	\N	K98-N2-491	N2
3419	\N	10	\N	K98-7T	N2
3420	\N	0	\N	K98-7TR	N2
3487	\N	394	\N	C11-C1-484	C1
3488	\N	560	\N	C11-C1-479	C1
3489	\N	670	\N	C11-C1-472	C1
3490	\N	450	\N	C11-C1-468	C1
3491	\N	593	\N	C11-C1-462	C1
3492	\N	192	\N	C11-C1-454	C1
3493	\N	600	\N	C11-C1-448	C1
3494	\N	136	\N	C11-C1-447	C1
3495	\N	64	\N	C11-1ATU	C1
3496	\N	64	\N	C11-1ATN	C1
3497	\N	64	\N	C11-3ATN	C1
3498	\N	64	\N	C11-3ATU	C1
3499	\N	380	\N	C11-C1-441	C1
3500	\N	578	\N	C11-C1-435	C1
3501	\N	693	\N	C11-C1-428	C1
3502	\N	574	\N	C11-C2-419	C2
3503	\N	310	\N	C11-C2-425	C2
3504	\N	693	\N	C11-C2-428	C2
3505	\N	578	\N	C11-C2-435	C2
3506	\N	373	\N	C11-C2-441	C2
3507	\N	64	\N	C11-1BTU	C2
3508	\N	64	\N	C11-1BTN	C2
3509	\N	64	\N	C11-3BTN	C2
3510	\N	64	\N	C11-3BTU	C2
3511	\N	136	\N	C11-C2-447	C2
3512	\N	600	\N	C11-C2-448	C2
3513	\N	192	\N	C11-C2-454	C2
3514	\N	595	\N	C11-C2-462	C2
3515	\N	450	\N	C11-C2-468	C2
3516	\N	535	\N	C11-C2-472	C2
3517	\N	755	\N	N12-N1-1678	N1
3518	\N	63	\N	N12-5ATU	N1
3519	\N	63	\N	N12-5ATN	N1
3520	\N	125	\N	N12-7ATN	N1
3521	\N	125	\N	N12-7ATU	N1
3522	\N	778	\N	N12-N1-1666	N1
3523	\N	600	\N	N12-N1-1660-63	N1
3524	\N	64	\N	N12-N1-1659	N1
3525	\N	96	\N	N12-1ATU	N1
3526	\N	96	\N	N12-1ATN	N1
3527	\N	110	\N	N12-3ATN	N1
3528	\N	110	\N	N12-3ATU	N1
3529	\N	685	\N	N12-N1-1649	N1
3530	\N	1389	\N	N12-N1-1635	N1
3531	\N	1406	\N	N12-N1-1623	N1
3532	\N	694	\N	N12-N1-1614	N1
3533	\N	1114	\N	N11-N1-1603	N1
3534	\N	1057	\N	N11-N1-1592	N1
3535	\N	570	\N	N11-N1-1587	N1
3536	\N	572	\N	N11-N1-1581	N1
3537	\N	528	\N	N11-N1-1576	N1
3538	\N	128	\N	N11-1ABT	N1
3539	\N	72	\N	N11-3ATN	N1
3540	\N	144	\N	N11-1AAT	N1
3541	\N	72	\N	N11-1ATN	N1
3542	\N	123	\N	N11-1ACT	N1
3543	\N	725	\N	N11-N1-1563	N1
3544	\N	600	\N	N11-N1-1557	N1
3545	\N	274	\N	N11-N1-1554	N1
3546	\N	939	\N	N98B-N1-1545	N1
3547	\N	1065	\N	N98B-N1-1534	N1
3548	\N	65	\N	N98B-1ATU	N1
3549	\N	65	\N	N98B-1ATN	N1
3550	\N	98	\N	N98B-1ABT	N1
3551	\N	533	\N	N98B-N1-1526	N1
3552	\N	378	\N	N98B-N1-1523	N1
3553	\N	383	\N	N98A-N1-1519	N1
3554	\N	964	\N	N98A-N1-1509	N1
3555	\N	396	\N	N98A-N1-1505	N1
3556	\N	81	\N	N98A-5BT	N1
3557	\N	75	\N	N98A-5ATU	N1
3558	\N	75	\N	N98A-1ATN	N1
3559	\N	130	\N	N98A-5CT	N1
3560	\N	822	\N	N98A-N1-1492	N1
3561	\N	757	\N	N98A-N1-1484	N1
3562	\N	815	\N	N97-N1-1476	N1
3563	\N	635	\N	N97-N1-1470	N1
3564	\N	726	\N	N97-N1-1463	N1
3565	\N	65	\N	N97-1ATU	N1
3566	\N	65	\N	N97-1ATN	N1
3567	\N	63	\N	N97-3ATN	N1
3568	\N	63	\N	N97-3ATU	N1
3569	\N	605	\N	N97-N1-1453	N1
3570	\N	851	\N	N97-N1-1446	N1
3571	\N	695	\N	N97-N1-1438	N1
3572	\N	1076	\N	N10-N1-1428	N1
3573	\N	374	\N	N10-N1-1425	N1
3574	\N	506	\N	N10-N1-1420	N1
3575	\N	497	\N	N10-N1-1415	N1
3576	\N	305	\N	N10-N1-1412	N1
3577	\N	600	\N	N10-N1-1406	N1
3578	\N	1351	\N	N10-N1-1393	N1
3579	\N	770	\N	N10-N1-1385	N1
3580	\N	941	\N	N10-N1-1375	N1
3581	\N	1016	\N	N10-N1-1365	N1
3582	\N	656	\N	N10-N1-1359	N1
3583	\N	647	\N	N96-N1-1352	N1
3584	\N	503	\N	N96-N1-1347	N1
3585	\N	528	\N	N96-N1-1342	N1
3586	\N	80	\N	N96-1ATU	N1
3587	\N	80	\N	N96-1ATN	N1
3588	\N	80	\N	N96-3ATN	N1
3589	\N	80	\N	N96-3ATU	N1
3590	\N	1233	\N	N96-N1-1326	N1
3591	\N	971	\N	N96-N1-1316	N1
3592	\N	971	\N	N09-N1-1308	N1
3593	\N	510	\N	N09-N1-1302	N1
3594	\N	600	\N	N09-N1-1296-99	N1
3595	\N	128	\N	N09-N1-1294	N1
3596	\N	100	\N	N09-1ATU	N1
3597	\N	100	\N	N09-1ATN	N1
3598	\N	110	\N	N09-3ATN	N1
3599	\N	110	\N	N09-3ATU	N1
3600	\N	393	\N	N09-N1-1286	N1
3601	\N	751	\N	N09-N1-1278	N1
3602	\N	985	\N	N09-N1-1269	N1
3603	\N	913	\N	N09-N1-1260	N1
3604	\N	915	\N	N09-N1-1251	N1
3605	\N	1480	\N	N09-N1-1240	N1
3606	\N	345	\N	N08-N1-1232	N1
3607	\N	645	\N	N08-N1-1226	N1
3608	\N	425	\N	N08-N1-1220	N1
3609	\N	760	\N	N08-N1-1214	N1
3610	\N	141	\N	N08-N1-1213	N1
3611	\N	202	\N	N08-N1-1211	N1
3612	\N	600	\N	N08-N1-1205	N1
3613	\N	266	\N	N08-N1-1202	N1
3614	\N	369	\N	N08-N1-1198	N1
3615	\N	75	\N	N08-1ATU	N1
3616	\N	75	\N	N08-1ATN	N1
3617	\N	97	\N	N08-1ABT	N1
3618	\N	1091	\N	N08-N1-1185	N1
3619	\N	177	\N	N08-3ABT	N1
3620	\N	75	\N	N08-3ATN	N1
3621	\N	75	\N	N08-3ATU	N1
3622	\N	941	\N	N08-N1-1172	N1
3623	\N	796	\N	N08-N1-1164	N1
3624	\N	1144	\N	N07-N1-1153	N1
3625	\N	894	\N	N07-N1-1144	N1
3626	\N	449	\N	N07-N1-1139	N1
3627	\N	600	\N	N07-N1-1133	N1
3628	\N	817	\N	N07-N1-1125	N1
3629	\N	1064	\N	N07-N1-1114	N1
3630	\N	962	\N	N07-N1-1105	N1
3631	\N	758	\N	N12-N2-1678	N2
3632	\N	63	\N	N12-7BTU	N2
3633	\N	63	\N	N12-7BTN	N2
3634	\N	125	\N	N12-5BTN	N2
3635	\N	125	\N	N12-5BTU	N2
3636	\N	774	\N	N12-N2-1666	N2
3637	\N	600	\N	N12-N2-1660-63	N2
3638	\N	64	\N	N12-N2-1659	N2
3639	\N	95	\N	N12-3BTU	N2
3640	\N	95	\N	N12-3BTN	N2
3641	\N	108	\N	N12-1BTN	N2
3642	\N	108	\N	N12-1BTU	N2
3643	\N	671	\N	N12-N2-1649	N2
3644	\N	1391	\N	N12-N2-1635	N2
3645	\N	1406	\N	N12-N2-1623	N2
3646	\N	694	\N	N11-N2-1614	N2
3647	\N	1114	\N	N11-N2-1603	N2
3648	\N	1043	\N	N11-N2-1592	N2
3649	\N	542	\N	N11-N2-1587	N2
3650	\N	600	\N	N11-N2-1581	N2
3651	\N	530	\N	N11-N2-1576	N2
3652	\N	67	\N	N11-3BTU	N2
3653	\N	67	\N	N11-3BTN	N2
3654	\N	67	\N	N11-1BTN	N2
3655	\N	67	\N	N11-1BTU	N2
3656	\N	741	\N	N11-N2-1563	N2
3657	\N	600	\N	N11-N2-1557	N2
3658	\N	287	\N	N98B-N2-1554	N2
3659	\N	939	\N	N98B-N2-1545	N2
3660	\N	1065	\N	N98B-N2-1534	N2
3661	\N	65	\N	N98B-3ATU	N2
3662	\N	65	\N	N98B-3ATN	N2
3663	\N	98	\N	N98B-3ABT	N2
3664	\N	533	\N	N98B-N2-1526	N2
3665	\N	378	\N	N98A-N2-1523	N2
3666	\N	383	\N	N98A-N2-1519	N2
3667	\N	964	\N	N98A-N2-1509	N2
3668	\N	606	\N	N98A-N2-1503	N2
3669	\N	155	\N	N98A-1BBT	N2
3670	\N	68	\N	N98A-1BTN	N2
3671	\N	68	\N	N98A-1BTU	N2
3672	\N	828	\N	N98A-N2-1492	N2
3673	\N	757	\N	N97-N2-1484	N2
3674	\N	815	\N	N97-N2-1476	N2
3675	\N	635	\N	N97-N2-1470	N2
3676	\N	726	\N	N97-N2-1463	N2
3677	\N	65	\N	N97-3BTU	N2
3678	\N	65	\N	N97-3BTN	N2
3679	\N	63	\N	N97-1BTN	N2
3680	\N	63	\N	N97-1BTU	N2
3681	\N	617	\N	N97-N2-1454	N2
3682	\N	839	\N	N97-N2-1446	N2
3683	\N	695	\N	N10-N2-1438	N2
3684	\N	1076	\N	N10-N2-1428	N2
3685	\N	319	\N	N10-N2-1425	N2
3686	\N	506	\N	N10-N2-1420	N2
3687	\N	497	\N	N10-N2-1415	N2
3688	\N	305	\N	N10-N2-1412	N2
3689	\N	600	\N	N10-N2-1406	N2
3690	\N	1296	\N	N10-N2-1398	N2
3691	\N	792	\N	N10-N2-1385	N2
3692	\N	941	\N	N10-N2-1375	N2
3693	\N	1017	\N	N10-N2-1365	N2
3694	\N	656	\N	N96-N2-1359	N2
3695	\N	647	\N	N96-N2-1352	N2
3696	\N	503	\N	N96-N2-1347	N2
3697	\N	528	\N	N96-N2-1342	N2
3698	\N	80	\N	N96-3BTU	N2
3699	\N	80	\N	N96-3BTN	N2
3700	\N	80	\N	N96-1BTN	N2
3701	\N	80	\N	N96-1BTU	N2
3702	\N	1245	\N	N96-N2-1326	N2
3703	\N	971	\N	N09-N2-1316	N2
3704	\N	971	\N	N09-N2-1308	N2
3705	\N	510	\N	N09-N2-1302	N2
3706	\N	600	\N	N09-N2-1296-99	N2
3707	\N	128	\N	N09-N2-1294	N2
3708	\N	100	\N	N09-3BTU	N2
3709	\N	100	\N	N09-3BTN	N2
3710	\N	100	\N	N09-1BTN	N2
3711	\N	100	\N	N09-1BTU	N2
3712	\N	393	\N	N09-N2-1286	N2
3713	\N	751	\N	N09-N2-1278	N2
3714	\N	985	\N	N09-N2-1269	N2
3715	\N	913	\N	N09-N2-1260	N2
3716	\N	912	\N	N09-N2-1251	N2
3717	\N	1480	\N	N08-N2-1240	N2
3718	\N	345	\N	N08-N2-1232	N2
3719	\N	645	\N	N08-N2-1226	N2
3720	\N	425	\N	N08-N2-1220	N2
3721	\N	755	\N	N08-N2-1214	N2
3722	\N	141	\N	N08-N2-1213	N2
3723	\N	202	\N	N08-N2-1211	N2
3724	\N	600	\N	N08-N2-1205	N2
3725	\N	261	\N	N08-N2-1202	N2
3726	\N	369	\N	N08-N2-1198	N2
3727	\N	123	\N	N08-1BBT	N2
3728	\N	93	\N	N08-1BTU	N2
3729	\N	93	\N	N08-5BTN	N2
3730	\N	228	\N	N08-1BCT	N2
3731	\N	370	\N	N08-N2-1188	N2
3732	\N	254	\N	N08-3BCT	N2
3733	\N	0	\N	N08-7TN	N2
3734	\N	50	\N	N08-3BTN	N2
3735	\N	123	\N	N08-3BBT	N2
3736	\N	379	\N	N08-N2-1174	N2
3737	\N	1346	\N	N07-N2-1164	N2
3738	\N	1144	\N	N07-N2-1153	N2
3739	\N	894	\N	N07-N2-1144	N2
3740	\N	449	\N	N07-N2-1139	N2
3741	\N	600	\N	N07-N2-1133	N2
3742	\N	823	\N	N07-N2-1125	N2
3743	\N	1064	\N	N07-N2-1114	N2
3744	\N	963	\N	N07-N2-1105	N2
\.


--
-- Data for Name: train_car_problem_tweet; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.train_car_problem_tweet (id, date, keywords, line_codes, text, train_car_id, twitter_id, user_id, user_name) FROM stdin;
\.


--
-- Data for Name: train_departure; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.train_departure (departure_station_code, departure_time, direction_number, line_code, departure_station_name, destination_station_code, destination_station_name, direction_name, line_name, num_cars, real_train_id, train_id, trip_id, type) FROM stdin;
\.


--
-- Data for Name: train_departure_info; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.train_departure_info (id, departure_station_code, departure_station_name, direction_name, direction_number, headway_deviation, line_code, line_name, observed_departure_time, observed_destination_station_code, observed_destination_station_name, observed_num_cars, observed_time_since_last_departure, real_train_id, schedule_deviation, scheduled_departure_time, scheduled_destination_station_code, scheduled_destination_station_name, scheduled_time_since_last_departure, train_id) FROM stdin;
\.


--
-- Data for Name: train_disappearance; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.train_disappearance (id, date, destination_station_code, direction_number, line_code, real_train_id, station_code, track_circuit_id, train_id) FROM stdin;
\.


--
-- Data for Name: train_expressed_station_event; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.train_expressed_station_event (id, date, destination_station_code, direction_number, line_code, num_cars, num_seconds_at_station, real_train_id, station_code, track_number, train_id) FROM stdin;
\.


--
-- Data for Name: train_offload; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.train_offload (id, date, destination_station_code, direction_number, line_code, real_train_id, station_code, train_id) FROM stdin;
\.


--
-- Data for Name: train_prediction_accuracy_measurement; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.train_prediction_accuracy_measurement (id, average_prediction_error, destination_station_code, has_corresponding_wmata_measurement, line_code, measurement_end_time, measurement_start_prediction, measurement_start_time, num_prediction_samples, prediction_origin_station, prediction_source) FROM stdin;
\.


--
-- Data for Name: train_problem_tweet; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.train_problem_tweet (id, date, keywords, line_codes, real_train_id, text, train_id, twitter_id, user_id, user_name) FROM stdin;
\.


--
-- Data for Name: train_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.train_status (id, num_cars, destination_station, destination_station_code, destination_station_name, group_number, line_code, location_station_code, location_station_name, eta, previous_station_code, should_render_on_left, are_doors_open, are_doors_open_on_left, are_doors_open_on_right, are_doors_operating_manually, circuit_name, current_station_code, current_station_name, num_times_delayed, destination_id, destination_station_abbreviation, direction, direction_number, distance_from_next_station, estimated_minutes_away, first_observed_train, is_adjusting_on_platform, is_holding_or_slow, is_keyed_down, is_not_on_revenue_track, is_scheduled, last_visited_station, last_visited_station_code, lat, lon, max_minutes_away, minutes_away, num_negative_tags, num_positive_tags, observed_date, original_destination_code, original_line_code, parent_min, previous_station_name, raw_track_circuit_id, real_train_id, seconds_at_last_visited_station, seconds_delayed, num_seconds_off_schedule, seconds_since_last_moved, track_circuit_id, track_number, train_id, train_speed, trip_id, was_keyed_down) FROM stdin;
\.


--
-- Data for Name: train_tag; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.train_tag (id, date, line_code, real_train_id, station_code, train_id, tweet_id, type, user_id) FROM stdin;
\.


--
-- Data for Name: trip_state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trip_state (id, date, expected_ride_time, from_station_code, predicted_ride_time, time_since_last_train, time_until_next_train, to_station_code) FROM stdin;
\.


--
-- Name: api_request_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.api_request_id_seq', 1, false);


--
-- Name: duplicate_train_event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.duplicate_train_event_id_seq', 1, false);


--
-- Name: hibernate_sequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.hibernate_sequence', 1, false);


--
-- Name: speed_restriction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.speed_restriction_id_seq', 1, false);


--
-- Name: station_problem_tweet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.station_problem_tweet_id_seq', 1, false);


--
-- Name: station_tag_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.station_tag_id_seq', 1, false);


--
-- Name: station_to_station_trip_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.station_to_station_trip_id_seq', 1, false);


--
-- Name: train_car_problem_tweet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.train_car_problem_tweet_id_seq', 1, false);


--
-- Name: train_departure_info_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.train_departure_info_id_seq', 1, false);


--
-- Name: train_disappearance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.train_disappearance_id_seq', 1, false);


--
-- Name: train_expressed_station_event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.train_expressed_station_event_id_seq', 1, false);


--
-- Name: train_offload_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.train_offload_id_seq', 1, false);


--
-- Name: train_prediction_accuracy_measurement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.train_prediction_accuracy_measurement_id_seq', 1, false);


--
-- Name: train_problem_tweet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.train_problem_tweet_id_seq', 1, false);


--
-- Name: train_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.train_status_id_seq', 1, false);


--
-- Name: train_tag_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.train_tag_id_seq', 1, false);


--
-- Name: trip_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.trip_state_id_seq', 1, false);


--
-- Name: api_request api_request_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_request
    ADD CONSTRAINT api_request_pkey PRIMARY KEY (id);


--
-- Name: api_user api_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_user
    ADD CONSTRAINT api_user_pkey PRIMARY KEY (api_key);


--
-- Name: daily_service_report daily_service_report_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_service_report
    ADD CONSTRAINT daily_service_report_pkey PRIMARY KEY (date);


--
-- Name: destination_code_mapping destination_code_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.destination_code_mapping
    ADD CONSTRAINT destination_code_mapping_pkey PRIMARY KEY (destination_code, direction_number);


--
-- Name: direction_metrics direction_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.direction_metrics
    ADD CONSTRAINT direction_metrics_pkey PRIMARY KEY (id);


--
-- Name: duplicate_train_event duplicate_train_event_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.duplicate_train_event
    ADD CONSTRAINT duplicate_train_event_pkey PRIMARY KEY (id);


--
-- Name: line_metrics_direction_metrics_by_direction line_metrics_direction_metrics_by_direction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.line_metrics_direction_metrics_by_direction
    ADD CONSTRAINT line_metrics_direction_metrics_by_direction_pkey PRIMARY KEY ("system_metrics$line_metrics_id", direction_metrics_by_direction_key);


--
-- Name: line_metrics line_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.line_metrics
    ADD CONSTRAINT line_metrics_pkey PRIMARY KEY (id);


--
-- Name: rail_incident rail_incident_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rail_incident
    ADD CONSTRAINT rail_incident_pkey PRIMARY KEY (description, incident_id, "timestamp");


--
-- Name: speed_restriction speed_restriction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.speed_restriction
    ADD CONSTRAINT speed_restriction_pkey PRIMARY KEY (id);


--
-- Name: station_problem_tweet station_problem_tweet_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.station_problem_tweet
    ADD CONSTRAINT station_problem_tweet_pkey PRIMARY KEY (id);


--
-- Name: station_tag station_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.station_tag
    ADD CONSTRAINT station_tag_pkey PRIMARY KEY (id);


--
-- Name: station_to_station_travel_time station_to_station_travel_time_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.station_to_station_travel_time
    ADD CONSTRAINT station_to_station_travel_time_pkey PRIMARY KEY (station_codes_key);


--
-- Name: station_to_station_trip station_to_station_trip_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.station_to_station_trip
    ADD CONSTRAINT station_to_station_trip_pkey PRIMARY KEY (id);


--
-- Name: system_metrics system_metrics_date; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_metrics
    ADD CONSTRAINT system_metrics_date UNIQUE (date);


--
-- Name: system_metrics_line_metrics_by_line system_metrics_line_metrics_by_line_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_metrics_line_metrics_by_line
    ADD CONSTRAINT system_metrics_line_metrics_by_line_pkey PRIMARY KEY (system_metrics_id, line_metrics_by_line_key);


--
-- Name: system_metrics system_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_metrics
    ADD CONSTRAINT system_metrics_pkey PRIMARY KEY (id);


--
-- Name: track_circuit track_circuit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.track_circuit
    ADD CONSTRAINT track_circuit_pkey PRIMARY KEY (api_id);


--
-- Name: train_car_problem_tweet train_car_problem_tweet_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_car_problem_tweet
    ADD CONSTRAINT train_car_problem_tweet_pkey PRIMARY KEY (id);


--
-- Name: train_departure_info train_departure_info_observed_departure_index; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_departure_info
    ADD CONSTRAINT train_departure_info_observed_departure_index UNIQUE (departure_station_code, line_code, direction_number, observed_departure_time);


--
-- Name: train_departure_info train_departure_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_departure_info
    ADD CONSTRAINT train_departure_info_pkey PRIMARY KEY (id);


--
-- Name: train_departure_info train_departure_info_scheduled_departure_index; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_departure_info
    ADD CONSTRAINT train_departure_info_scheduled_departure_index UNIQUE (departure_station_code, line_code, direction_number, scheduled_departure_time);


--
-- Name: train_departure train_departure_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_departure
    ADD CONSTRAINT train_departure_pkey PRIMARY KEY (departure_station_code, departure_time, direction_number, line_code);


--
-- Name: train_disappearance train_disappearance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_disappearance
    ADD CONSTRAINT train_disappearance_pkey PRIMARY KEY (id);


--
-- Name: train_expressed_station_event train_expressed_station_event_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_expressed_station_event
    ADD CONSTRAINT train_expressed_station_event_pkey PRIMARY KEY (id);


--
-- Name: train_offload train_offload_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_offload
    ADD CONSTRAINT train_offload_pkey PRIMARY KEY (id);


--
-- Name: train_prediction_accuracy_measurement train_prediction_accuracy_measurement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_prediction_accuracy_measurement
    ADD CONSTRAINT train_prediction_accuracy_measurement_pkey PRIMARY KEY (id);


--
-- Name: train_problem_tweet train_problem_tweet_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_problem_tweet
    ADD CONSTRAINT train_problem_tweet_pkey PRIMARY KEY (id);


--
-- Name: train_status train_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_status
    ADD CONSTRAINT train_status_pkey PRIMARY KEY (id);


--
-- Name: train_tag train_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.train_tag
    ADD CONSTRAINT train_tag_pkey PRIMARY KEY (id);


--
-- Name: trip_state trip_state_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_state
    ADD CONSTRAINT trip_state_pkey PRIMARY KEY (id);


--
-- Name: line_metrics_direction_metrics_by_direction uk_311wewcrbnu4f2darq42b369b; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.line_metrics_direction_metrics_by_direction
    ADD CONSTRAINT uk_311wewcrbnu4f2darq42b369b UNIQUE (direction_metrics_by_direction_id);


--
-- Name: system_metrics_line_metrics_by_line uk_kuwybeie8320rq7c70m831jc9; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_metrics_line_metrics_by_line
    ADD CONSTRAINT uk_kuwybeie8320rq7c70m831jc9 UNIQUE (line_metrics_by_line_id);


--
-- Name: api_request_api_key_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX api_request_api_key_index ON public.api_request USING btree (api_key);


--
-- Name: api_request_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX api_request_date_index ON public.api_request USING btree (date);


--
-- Name: direction_metrics_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX direction_metrics_date ON public.direction_metrics USING btree (date);


--
-- Name: direction_metrics_direction_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX direction_metrics_direction_number ON public.direction_metrics USING btree (direction_number);


--
-- Name: direction_metrics_line_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX direction_metrics_line_code ON public.direction_metrics USING btree (line_code);


--
-- Name: duplicate_train_event_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX duplicate_train_event_date_index ON public.duplicate_train_event USING btree (date);


--
-- Name: line_metrics_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX line_metrics_date ON public.line_metrics USING btree (date);


--
-- Name: line_metrics_line_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX line_metrics_line_code ON public.line_metrics USING btree (line_code);


--
-- Name: rail_incident_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX rail_incident_date_index ON public.rail_incident USING btree (date);


--
-- Name: station_problem_tweet_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX station_problem_tweet_date_index ON public.station_problem_tweet USING btree (date);


--
-- Name: station_problem_tweet_twitter_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX station_problem_tweet_twitter_id_index ON public.station_problem_tweet USING btree (twitter_id);


--
-- Name: station_tag_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX station_tag_date_index ON public.station_tag USING btree (date);


--
-- Name: station_to_station_trip_arriving_time_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX station_to_station_trip_arriving_time_index ON public.station_to_station_trip USING btree (arriving_time);


--
-- Name: station_to_station_trip_departing_time_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX station_to_station_trip_departing_time_index ON public.station_to_station_trip USING btree (departing_time);


--
-- Name: train_car_problem_tweet_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX train_car_problem_tweet_date_index ON public.train_car_problem_tweet USING btree (date);


--
-- Name: train_car_problem_tweet_twitter_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX train_car_problem_tweet_twitter_id_index ON public.train_car_problem_tweet USING btree (twitter_id);


--
-- Name: train_departure_departure_time_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX train_departure_departure_time_type_index ON public.train_departure USING btree (departure_time, type);


--
-- Name: train_departure_info_report_metrics_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX train_departure_info_report_metrics_index ON public.train_departure_info USING btree (observed_departure_time, departure_station_code, line_code, direction_number);


--
-- Name: train_departure_reconciliation_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX train_departure_reconciliation_index ON public.train_departure USING btree (departure_station_code, line_code, direction_number, departure_time, type);


--
-- Name: train_disappearance_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX train_disappearance_date_index ON public.train_disappearance USING btree (date);


--
-- Name: train_expressed_station_event_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX train_expressed_station_event_date_index ON public.train_expressed_station_event USING btree (date);


--
-- Name: train_offload_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX train_offload_date_index ON public.train_offload USING btree (date);


--
-- Name: train_problem_tweet_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX train_problem_tweet_date_index ON public.train_problem_tweet USING btree (date);


--
-- Name: train_problem_tweet_twitter_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX train_problem_tweet_twitter_id_index ON public.train_problem_tweet USING btree (twitter_id);


--
-- Name: train_status_observed_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX train_status_observed_date_index ON public.train_status USING btree (observed_date);


--
-- Name: train_tag_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX train_tag_date_index ON public.train_tag USING btree (date);


--
-- Name: trip_state_from_station_code_to_station_code_date_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX trip_state_from_station_code_to_station_code_date_index ON public.trip_state USING btree (from_station_code, to_station_code, date);


--
-- Name: line_metrics_direction_metrics_by_direction fk27nu1edi9a6dplaoi1muqmd5m; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.line_metrics_direction_metrics_by_direction
    ADD CONSTRAINT fk27nu1edi9a6dplaoi1muqmd5m FOREIGN KEY ("system_metrics$line_metrics_id") REFERENCES public.line_metrics(id);


--
-- Name: system_metrics_line_metrics_by_line fk4mqx14x91cwx8l9w8bvlfvp1p; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_metrics_line_metrics_by_line
    ADD CONSTRAINT fk4mqx14x91cwx8l9w8bvlfvp1p FOREIGN KEY (system_metrics_id) REFERENCES public.system_metrics(id);


--
-- Name: system_metrics_line_metrics_by_line fk82pitn32l240c0p3omkf60hkf; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_metrics_line_metrics_by_line
    ADD CONSTRAINT fk82pitn32l240c0p3omkf60hkf FOREIGN KEY (line_metrics_by_line_id) REFERENCES public.line_metrics(id);


--
-- Name: line_metrics_direction_metrics_by_direction fkn3n9injy2wljd5lt5paa0pwq; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.line_metrics_direction_metrics_by_direction
    ADD CONSTRAINT fkn3n9injy2wljd5lt5paa0pwq FOREIGN KEY (direction_metrics_by_direction_id) REFERENCES public.direction_metrics(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K02_K01', 2086, 'K02', '2016-11-15 08:00:36.595000', 'K01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F04_F03', 3607, 'F04', '2016-12-02 10:14:36.255000', 'F03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F02_F03', 2351, 'F02', '2016-12-07 22:00:38.143000', 'F03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E04_E05', 4139, 'E04', '2016-12-16 13:02:40.266000', 'E05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E10_E09', 12678, 'E10', '2017-03-20 17:14:07.099000', 'E09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D13_D12', 7051, 'D13', '2017-02-11 16:20:54.213000', 'D12') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F11_F10', 8550, 'F11', '2017-04-20 10:54:50.414000', 'F10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('J03_J02', 18092, 'J03', '2017-01-21 00:07:56.644000', 'J02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A12_A13', 5295, 'A12', '2016-12-28 11:38:01.094000', 'A13') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E07_E06', 9808, 'E07', '2017-01-05 09:24:44.252000', 'E06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B06_B07', 9435, 'B06', '2017-01-05 09:25:02.907000', 'B07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C05_C04', 6458, 'C05', '2017-01-05 09:25:15.138000', 'C04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C15_C14', 2189, 'C15', '2017-01-29 16:56:37.331000', 'C14') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K03_K04', 2374, 'K03', '2017-01-11 14:49:47.504000', 'K04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C14_C13', 3125, 'C14', '2016-11-21 13:22:12.246000', 'C13') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A04_A05', 3140, 'A04', '2016-11-16 12:25:06.668000', 'A05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A02_A03', 2105, 'A02', '2016-11-17 00:21:40.166000', 'A03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A01_A02', 3535, 'A01', '2016-11-23 19:00:56.115000', 'A02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A05_A04', 3140, 'A05', '2016-11-15 20:29:11.718000', 'A04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A02_A01', 3535, 'A02', '2016-11-03 15:33:23.635000', 'A01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A07_A06', 5240, 'A07', '2016-11-03 17:06:34.132000', 'A06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A08_A07', 3515, 'A08', '2016-11-03 10:01:04.275000', 'A07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B02_B01', 1365, 'B02', '2016-11-03 16:00:29.337000', 'B01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C05_C06', 4354, 'C05', '2016-11-21 08:06:28.468000', 'C06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C04_C03', 2166, 'C04', '2016-11-03 16:23:41.193000', 'C03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C05_K01', 5148, 'C05', '2016-11-03 16:31:19.368000', 'K01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C07_C08', 2637, 'C07', '2016-11-03 16:37:06.639000', 'C08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C08_C07', 2637, 'C08', '2016-11-03 16:30:48.811000', 'C07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C13_C14', 3125, 'C13', '2016-11-03 16:13:26.879000', 'C14') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D02_D01', 1416, 'D02', '2016-11-07 15:00:24.801000', 'D01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D02_D03', 2044, 'D02', '2016-11-03 15:08:00.787000', 'D03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D05_D04', 2452, 'D05', '2016-11-03 16:23:47.410000', 'D04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E01_E02', 1927, 'E01', '2016-11-03 15:09:57.787000', 'E02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E01_F01', 2385, 'E01', '2016-11-03 13:31:05.125000', 'F01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E07_E08', 6075, 'E07', '2016-11-03 16:31:07.740000', 'E08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F01_E01', 2385, 'F01', '2016-11-03 13:31:05.125000', 'E01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C07_F03', 11612, 'C07', '2016-11-22 21:03:26.446000', 'F03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A10_A09', 4923, 'A10', '2017-04-21 08:41:25.127000', 'A09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D09_D10', 4063, 'D09', '2017-01-18 15:37:03.807000', 'D10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A11_A10', 11242, 'A11', '2017-03-07 08:15:11.379000', 'A10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A14_A13', 9985, 'A14', '2017-05-08 18:20:38.942000', 'A13') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E03_E04', 4115, 'E03', '2016-11-12 19:01:02.004000', 'E04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C08_C09', 3468, 'C08', '2016-11-13 15:00:47.532000', 'C09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B01_A01', 905, 'B01', '2016-11-13 18:00:18.571000', 'A01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D04_D03', 1156, 'D04', '2016-12-08 06:00:24.946000', 'D03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E09_E08', 9432, 'E09', '2016-11-18 21:02:10.952000', 'E08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B05_B06', 6503, 'B05', '2017-07-05 18:27:52.746000', 'B06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A10_A11', 11242, 'A10', '2017-08-27 00:58:19.996000', 'A11') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C07_C06', 6404, 'C07', '2017-06-05 07:15:41.355000', 'C06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K01_K02', 2086, 'K01', '2017-09-23 00:04:39.486000', 'K02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E08_E07', 6075, 'E08', '2017-08-10 18:47:22.631000', 'E07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B11_B10', 8730, 'B11', '2017-06-15 22:55:19.235000', 'B10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C14_C15', 2189, 'C14', '2017-09-17 07:58:06.470000', 'C15') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D12_D13', 7051, 'D12', '2017-09-08 15:58:03.959000', 'D13') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D01_D02', 1416, 'D01', '2017-06-22 14:42:34.821000', 'D02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A08_A09', 8492, 'A08', '2017-09-12 07:42:33.164000', 'A09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A04_A03', 5660, 'A04', '2017-07-04 10:21:06.318000', 'A03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A14_A15', 13555, 'A14', '2017-07-20 18:33:55.310000', 'A15') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A06_A05', 2720, 'A06', '2017-08-14 10:55:25.808000', 'A05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F07_F06', 6236, 'F07', '2017-08-22 08:09:02.769000', 'F06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D11_D12', 9070, 'D11', '2017-08-03 19:28:56.288000', 'D12') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A03_A04', 5660, 'A03', '2017-08-24 16:16:54.658000', 'A04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A12_A11', 6673, 'A12', '2017-09-20 16:26:50.844000', 'A11') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C03_C02', 1401, 'C03', '2017-08-20 22:23:47.535000', 'C02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C09_C08', 3468, 'C09', '2017-08-24 09:40:24.918000', 'C08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D01_C01', 961, 'D01', '2017-08-21 15:16:43.683000', 'C01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A01_B01', 905, 'A01', '2017-08-28 07:01:05.146000', 'B01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A09_A08', 8492, 'A09', '2017-09-01 23:19:02.507000', 'A08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D08_G01', 12795, 'D08', '2017-08-31 15:26:37.365000', 'G01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B10_B11', 8730, 'B10', '2017-08-20 20:01:58.316000', 'B11') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E06_E05', 7981, 'E06', '2017-09-05 07:55:16.797000', 'E05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('G04_G05', 6600, 'G04', '2017-09-12 06:57:41.075000', 'G05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N01_N02', 2840, 'N01', '2017-08-23 12:22:03.651000', 'N02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F05_F06', 5575, 'F05', '2017-09-12 05:44:52.404000', 'F06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E08_E09', 9432, 'E08', '2017-08-17 17:33:40.607000', 'E09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D08_D09', 10424, 'D08', '2017-08-28 06:36:57.835000', 'D09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F01_F02', 1279, 'F01', '2017-09-12 07:00:20.500000', 'F02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B02_B03', 2838, 'B02', '2017-09-17 20:55:25.225000', 'B03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B09_B08', 8332, 'B09', '2017-09-15 18:19:28.955000', 'B08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('J02_J03', 18092, 'J02', '2017-09-18 17:02:15.560000', 'J03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B10_B09', 7950, 'B10', '2017-09-19 18:25:36.035000', 'B09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C02_C03', 1401, 'C02', '2017-08-16 18:42:14.502000', 'C03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K07_K08', 12564, 'K07', '2017-08-16 22:28:37.991000', 'K08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D08_D07', 3150, 'D08', '2017-08-30 19:20:02.587000', 'D07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E09_E10', 12678, 'E09', '2017-09-16 14:09:32.523000', 'E10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B35_B03', 2949, 'B35', '2017-08-20 14:55:52.306000', 'B03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D09_D08', 10424, 'D09', '2017-08-25 10:14:16.328000', 'D08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B03_B35', 2949, 'B03', '2017-08-30 19:11:07.842000', 'B35') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D06_D07', 2689, 'D06', '2017-08-24 12:28:26.179000', 'D07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A06_A07', 5240, 'A06', '2017-08-24 12:28:51.520000', 'A07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A09_A10', 4923, 'A09', '2017-08-24 12:28:57.779000', 'A10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C06_C07', 6404, 'C06', '2017-08-24 12:29:16.485000', 'C07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D03_D04', 1156, 'D03', '2017-08-24 13:47:26.770000', 'D04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E05_E06', 7981, 'E05', '2017-08-24 17:48:49.892000', 'E06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A03_A02', 2105, 'A03', '2017-09-09 16:47:52.530000', 'A02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C09_C10', 2509, 'C09', '2017-09-09 17:49:16.294000', 'C10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F02_F01', 1279, 'F02', '2017-08-29 18:16:38.460000', 'F01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A07_A08', 3515, 'A07', '2017-08-30 12:08:08.850000', 'A08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C03_C04', 2166, 'C03', '2017-09-02 12:48:14.468000', 'C04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E06_E07', 9808, 'E06', '2017-09-07 11:23:11.460000', 'E07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B01_B02', 1365, 'B01', '2017-09-13 07:56:54.342000', 'B02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D07_D08', 3150, 'D07', '2017-09-22 13:49:05.208000', 'D08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N04_N06', 30257, 'N04', '2017-09-26 20:29:57.858000', 'N06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E02_E01', 1927, 'E02', '2016-11-23 18:51:15.143000', 'E01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E03_E02', 1956, 'E03', '2016-12-05 07:00:32.333000', 'E02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D06_D05', 2103, 'D06', '2016-11-09 00:00:32.439000', 'D05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C13_C12', 2845, 'C13', '2016-12-07 11:00:37.661000', 'C12') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C06_C05', 4354, 'C06', '2016-11-17 19:01:05.377000', 'C05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F03_F02', 2351, 'F03', '2016-11-03 16:23:47.410000', 'F02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F03_F04', 3607, 'F03', '2016-11-03 14:01:00.732000', 'F04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F04_F05', 2726, 'F04', '2016-11-03 16:30:42.405000', 'F05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F06_F05', 5575, 'F06', '2016-11-03 16:31:29.631000', 'F05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F07_F08', 4945, 'F07', '2016-11-03 13:31:51.270000', 'F08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K06_K05', 10339, 'K06', '2016-11-03 10:02:22.038000', 'K05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N04_N03', 3034, 'N04', '2016-11-03 16:18:46.065000', 'N03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('G05_G04', 6600, 'G05', '2016-11-10 17:51:48.229000', 'G04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K01_C05', 5148, 'K01', '2016-11-23 11:01:23.621000', 'C05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F03_C07', 11612, 'F03', '2016-11-11 22:03:34.308000', 'C07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K03_K02', 1872, 'K03', '2016-11-14 00:00:33.572000', 'K02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K02_K03', 1872, 'K02', '2016-11-29 06:00:28.910000', 'K03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F06_F07', 6236, 'F06', '2016-11-10 16:01:14.354000', 'F07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N02_N03', 3302, 'N02', '2016-11-30 13:00:56.563000', 'N03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B08_B09', 8332, 'B08', '2017-01-05 09:44:05.092000', 'B09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C01_C02', 1825, 'C01', '2016-12-13 14:47:02.983000', 'C02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B35_B04', 5163, 'B35', '2017-02-27 08:01:24.424000', 'B04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('G04_G03', 7565, 'G04', '2017-05-04 00:19:36.849000', 'G03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F08_F09', 6000, 'F08', '2017-01-25 11:28:52.783000', 'F09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('G03_G02', 4615, 'G03', '2017-04-12 18:30:23.435000', 'G02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A11_A12', 6673, 'A11', '2017-03-08 11:28:52.486000', 'A12') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B04_B35', 5163, 'B04', '2017-04-02 14:40:19.722000', 'B35') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C10_C09', 2509, 'C10', '2017-02-14 19:25:29.931000', 'C09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A13_A14', 9985, 'A13', '2017-02-18 06:52:14.382000', 'A14') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A13_A12', 5295, 'A13', '2017-03-11 08:06:48.134000', 'A12') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('G01_D08', 12795, 'G01', '2017-04-25 08:51:58.801000', 'D08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B09_B10', 7950, 'B09', '2017-09-07 18:20:35.327000', 'B10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K06_K07', 12081, 'K06', '2017-09-25 18:55:57.898000', 'K07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D10_D11', 5196, 'D10', '2017-08-17 06:38:55.764000', 'D11') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A15_A14', 13555, 'A15', '2017-05-22 22:18:52.212000', 'A14') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B07_B06', 9435, 'B07', '2017-08-30 23:18:01.277000', 'B06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B05_B04', 3953, 'B05', '2017-06-01 19:50:40.573000', 'B04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K05_K06', 10339, 'K05', '2017-09-14 16:01:01.040000', 'K06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K08_K07', 12564, 'K08', '2017-06-06 13:33:04.311000', 'K07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C04_C05', 6458, 'C04', '2017-06-07 12:10:06.737000', 'C05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C01_D01', 961, 'C01', '2017-08-31 16:50:35.578000', 'D01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F09_F10', 7035, 'F09', '2017-06-16 19:28:34.739000', 'F10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C10_C12', 15483, 'C10', '2017-06-16 19:28:41.066000', 'C12') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N02_N01', 2840, 'N02', '2017-09-14 16:44:52.019000', 'N01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('G02_G03', 4615, 'G02', '2017-06-23 10:17:32.819000', 'G03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D12_D11', 9070, 'D12', '2017-08-12 21:43:03.087000', 'D11') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N06_N04', 30257, 'N06', '2017-06-30 22:01:58.630000', 'N04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C13_J02', 19765, 'C13', '2017-09-14 16:59:13.858000', 'J02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B08_B07', 6889, 'B08', '2017-08-25 17:51:05.482000', 'B07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D04_D05', 2452, 'D04', '2017-07-15 23:46:55.251000', 'D05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D10_D09', 4063, 'D10', '2017-07-21 17:55:37.296000', 'D09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D11_D10', 5196, 'D11', '2017-07-27 17:21:03.652000', 'D10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('G02_G01', 7179, 'G02', '2017-08-31 17:08:37.744000', 'G01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E04_E03', 4115, 'E04', '2017-08-17 14:15:14.749000', 'E03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B03_B02', 2838, 'B03', '2017-08-31 22:46:04.338000', 'B02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F10_F11', 8550, 'F10', '2017-09-09 01:14:39.954000', 'F11') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('G01_G02', 7179, 'G01', '2017-08-16 08:33:47.641000', 'G02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K07_K06', 12081, 'K07', '2017-08-23 16:23:33.158000', 'K06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F05_F04', 2726, 'F05', '2017-08-27 20:36:28.854000', 'F04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D03_D02', 2044, 'D03', '2017-09-09 21:20:33.681000', 'D02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F10_F09', 7035, 'F10', '2017-09-10 01:03:09.919000', 'F09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C12_C10', 15483, 'C12', '2017-09-16 10:07:13.434000', 'C10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F09_F08', 6000, 'F09', '2017-09-11 16:06:15.140000', 'F08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E02_E03', 1956, 'E02', '2017-08-16 14:52:07.525000', 'E03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('J02_C13', 19765, 'J02', '2017-08-13 17:23:02.631000', 'C13') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('A05_A06', 2720, 'A05', '2017-09-17 00:45:28.653000', 'A06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C02_C01', 1825, 'C02', '2017-08-28 08:17:45.776000', 'C01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B04_B05', 3953, 'B04', '2017-08-18 17:25:10.872000', 'B05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N01_K05', 24031, 'N01', '2017-09-12 15:27:15.659000', 'K05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D07_D06', 2689, 'D07', '2017-09-17 11:33:37.268000', 'D06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('F08_F07', 4945, 'F08', '2017-08-24 09:40:56.395000', 'F07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('E05_E04', 4139, 'E05', '2017-08-24 12:28:51.520000', 'E04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B06_B05', 6503, 'B06', '2017-08-24 12:29:16.485000', 'B05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K05_K04', 12549, 'K05', '2017-08-24 12:30:19.963000', 'K04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N03_N04', 3034, 'N03', '2017-09-18 20:25:53.062000', 'N04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K04_K05', 12549, 'K04', '2017-09-13 19:19:57.948000', 'K05') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K05_N01', 24031, 'K05', '2017-09-20 09:07:57.220000', 'N01') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('D05_D06', 2103, 'D05', '2017-08-29 10:33:30.255000', 'D06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N03_N02', 3302, 'N03', '2017-09-21 17:05:44.908000', 'N02') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('C12_C13', 2845, 'C12', '2017-09-05 06:08:49.855000', 'C13') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('G03_G04', 7565, 'G03', '2017-09-05 22:18:24.674000', 'G04') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('K04_K03', 2374, 'K04', '2017-09-13 20:12:43.346000', 'K03') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('B07_B08', 6889, 'B07', '2017-09-25 08:51:09.185000', 'B08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N06_N07', 7355, 'N06', '2022-11-15 20:21:00.000000', 'N07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N07_N08', 6176, 'N07', '2022-11-15 20:21:00.000000', 'N08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N08_N09', 8475, 'N08', '2022-11-15 20:21:00.000000', 'N09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N09_N10', 10397, 'N09', '2022-11-15 20:21:00.000000', 'N10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N10_N11', 14545, 'N10', '2022-11-15 20:21:00.000000', 'N11') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N11_N12', 9470, 'N11', '2022-11-15 20:21:00.000000', 'N12') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N12_N11', 9470, 'N12', '2022-11-15 20:21:00.000000', 'N11') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N11_N10', 14545, 'N11', '2022-11-15 20:21:00.000000', 'N10') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N10_N09', 10397, 'N10', '2022-11-15 20:21:00.000000', 'N09') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N09_N08', 8475, 'N09', '2022-11-15 20:21:00.000000', 'N08') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N08_N07', 6176, 'N08', '2022-11-15 20:21:00.000000', 'N07') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;
   INSERT INTO public.station_to_station_travel_time (station_codes_key, distance, from_station_code, last_updated, to_station_code) VALUES ('N07_N06', 7355, 'N07', '2022-11-15 20:21:00.000000', 'N06') ON CONFLICT (station_codes_key) DO UPDATE SET distance = EXCLUDED.distance;