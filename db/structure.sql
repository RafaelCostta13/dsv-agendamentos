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
-- Name: prevent_audit_event_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_audit_event_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'audit_events is append-only' USING ERRCODE = '23514';
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audit_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_events (
    id bigint NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    previous_values jsonb,
    new_values jsonb,
    reason text,
    created_at timestamp(6) without time zone NOT NULL,
    actor_user_id bigint,
    actor_name character varying(100),
    actor_role character varying(30),
    origin character varying(30),
    CONSTRAINT audit_events_actor_role_allowed CHECK (((actor_role IS NULL) OR ((actor_role)::text = ANY (ARRAY[('admin'::character varying)::text, ('operator'::character varying)::text, ('viewer'::character varying)::text])))),
    CONSTRAINT audit_events_actor_snapshot_complete CHECK ((((actor_user_id IS NULL) AND (actor_name IS NULL) AND (actor_role IS NULL)) OR ((actor_user_id IS NOT NULL) AND (actor_name IS NOT NULL) AND (actor_role IS NOT NULL)))),
    CONSTRAINT audit_events_entity_type_allowed CHECK (((entity_type)::text = ANY (ARRAY[('Booking'::character varying)::text, ('SlotBlock'::character varying)::text, ('User'::character varying)::text]))),
    CONSTRAINT audit_events_origin_allowed CHECK (((origin IS NULL) OR ((origin)::text = ANY (ARRAY[('public_form'::character varying)::text, ('authenticated_user'::character varying)::text, ('system'::character varying)::text, ('bootstrap'::character varying)::text, ('unknown'::character varying)::text]))))
);


--
-- Name: audit_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_events_id_seq OWNED BY public.audit_events.id;


--
-- Name: bookings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookings (
    id bigint NOT NULL,
    protocol character varying(50) NOT NULL,
    request_id uuid NOT NULL,
    booking_date date NOT NULL,
    dock_number smallint NOT NULL,
    slot_number smallint NOT NULL,
    operation character varying(20) NOT NULL,
    status character varying(30) DEFAULT 'agendado'::character varying NOT NULL,
    contact_name character varying(80) NOT NULL,
    company character varying(100) NOT NULL,
    invoice character varying(44) NOT NULL,
    plate character varying(7) NOT NULL,
    vehicle_model character varying(80) NOT NULL,
    checkin_at timestamp(6) without time zone,
    released_at timestamp(6) without time zone,
    release_remark text,
    change_reason text,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT bookings_dock_range CHECK (((dock_number >= 1) AND (dock_number <= 8))),
    CONSTRAINT bookings_invoice_digits CHECK (((invoice)::text ~ '^[0-9]{1,44}$'::text)),
    CONSTRAINT bookings_lock_version_nonnegative CHECK ((lock_version >= 0)),
    CONSTRAINT bookings_operation_allowed CHECK (((operation)::text = ANY (ARRAY[('entrega'::character varying)::text, ('coleta'::character varying)::text]))),
    CONSTRAINT bookings_operation_checkin CHECK ((((status)::text <> 'em_operacao'::text) OR (checkin_at IS NOT NULL))),
    CONSTRAINT bookings_release_chronology CHECK (((released_at IS NULL) OR ((checkin_at IS NOT NULL) AND (released_at >= checkin_at)))),
    CONSTRAINT bookings_released_details CHECK ((((status)::text <> 'liberado'::text) OR ((checkin_at IS NOT NULL) AND (released_at IS NOT NULL) AND (release_remark IS NOT NULL) AND (char_length(regexp_replace(release_remark, '^[[:space:]]+|[[:space:]]+$'::text, ''::text, 'g'::text)) >= 3) AND (char_length(regexp_replace(release_remark, '^[[:space:]]+|[[:space:]]+$'::text, ''::text, 'g'::text)) <= 500)))),
    CONSTRAINT bookings_slot_range CHECK (((slot_number >= 1) AND (slot_number <= 10))),
    CONSTRAINT bookings_status_allowed CHECK (((status)::text = ANY (ARRAY[('agendado'::character varying)::text, ('em_operacao'::character varying)::text, ('liberado'::character varying)::text, ('cancelado'::character varying)::text, ('reagendamento'::character varying)::text])))
);


--
-- Name: bookings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bookings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bookings_id_seq OWNED BY public.bookings.id;


--
-- Name: login_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login_attempts (
    id bigint NOT NULL,
    key_kind character varying(10) NOT NULL,
    key_digest character varying(64) NOT NULL,
    occurred_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT login_attempts_digest_length CHECK ((char_length((key_digest)::text) = 64)),
    CONSTRAINT login_attempts_kind_allowed CHECK (((key_kind)::text = ANY (ARRAY[('email'::character varying)::text, ('ip'::character varying)::text])))
);


--
-- Name: login_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.login_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: login_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.login_attempts_id_seq OWNED BY public.login_attempts.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token_digest character varying(64) NOT NULL,
    last_seen_at timestamp(6) without time zone NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone,
    user_agent character varying(500),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT sessions_token_digest_length CHECK ((char_length((token_digest)::text) = 64)),
    CONSTRAINT sessions_valid_times CHECK ((expires_at > created_at))
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: slot_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.slot_blocks (
    id bigint NOT NULL,
    blocked_date date NOT NULL,
    dock_number smallint NOT NULL,
    slot_number smallint NOT NULL,
    reason character varying(250),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT slot_blocks_dock_range CHECK (((dock_number >= 1) AND (dock_number <= 8))),
    CONSTRAINT slot_blocks_slot_range CHECK (((slot_number >= 1) AND (slot_number <= 10)))
);


--
-- Name: slot_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.slot_blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: slot_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.slot_blocks_id_seq OWNED BY public.slot_blocks.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(254) NOT NULL,
    password_digest character varying NOT NULL,
    role character varying(30) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    must_change_password boolean DEFAULT true NOT NULL,
    password_changed_at timestamp(6) without time zone,
    deactivated_at timestamp(6) without time zone,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT users_active_consistent CHECK (((active AND (deactivated_at IS NULL)) OR ((NOT active) AND (deactivated_at IS NOT NULL)))),
    CONSTRAINT users_identity_present CHECK (((char_length(btrim((name)::text)) >= 2) AND (char_length(btrim((email)::text)) > 0))),
    CONSTRAINT users_lock_version_nonnegative CHECK ((lock_version >= 0)),
    CONSTRAINT users_role_allowed CHECK (((role)::text = ANY (ARRAY[('admin'::character varying)::text, ('operator'::character varying)::text, ('viewer'::character varying)::text])))
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: audit_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events ALTER COLUMN id SET DEFAULT nextval('public.audit_events_id_seq'::regclass);


--
-- Name: bookings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings ALTER COLUMN id SET DEFAULT nextval('public.bookings_id_seq'::regclass);


--
-- Name: login_attempts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_attempts ALTER COLUMN id SET DEFAULT nextval('public.login_attempts_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: slot_blocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slot_blocks ALTER COLUMN id SET DEFAULT nextval('public.slot_blocks_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: audit_events audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);


--
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: login_attempts login_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_attempts
    ADD CONSTRAINT login_attempts_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: slot_blocks slot_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slot_blocks
    ADD CONSTRAINT slot_blocks_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: bookings_active_slot_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bookings_active_slot_unique ON public.bookings USING btree (booking_date, dock_number, slot_number) WHERE ((status)::text = ANY (ARRAY[('agendado'::character varying)::text, ('em_operacao'::character varying)::text, ('liberado'::character varying)::text]));


--
-- Name: bookings_dock_occupation_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bookings_dock_occupation_unique ON public.bookings USING btree (dock_number) WHERE ((status)::text = 'em_operacao'::text);


--
-- Name: index_audit_events_on_actor_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_actor_user_id ON public.audit_events USING btree (actor_user_id);


--
-- Name: index_audit_events_on_entity_type_and_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_entity_type_and_entity_id ON public.audit_events USING btree (entity_type, entity_id);


--
-- Name: index_audit_events_on_origin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_origin ON public.audit_events USING btree (origin);


--
-- Name: index_bookings_on_booking_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookings_on_booking_date ON public.bookings USING btree (booking_date);


--
-- Name: index_bookings_on_protocol; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bookings_on_protocol ON public.bookings USING btree (protocol);


--
-- Name: index_bookings_on_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bookings_on_request_id ON public.bookings USING btree (request_id);


--
-- Name: index_login_attempts_on_occurred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_login_attempts_on_occurred_at ON public.login_attempts USING btree (occurred_at);


--
-- Name: index_sessions_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_expires_at ON public.sessions USING btree (expires_at);


--
-- Name: index_sessions_on_revoked_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_revoked_at ON public.sessions USING btree (revoked_at);


--
-- Name: index_sessions_on_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_token_digest ON public.sessions USING btree (token_digest);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: login_attempts_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX login_attempts_lookup ON public.login_attempts USING btree (key_kind, key_digest, occurred_at);


--
-- Name: slot_blocks_position_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX slot_blocks_position_unique ON public.slot_blocks USING btree (blocked_date, dock_number, slot_number);


--
-- Name: users_email_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_unique ON public.users USING btree (lower((email)::text));


--
-- Name: audit_events audit_events_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_events_append_only BEFORE DELETE OR UPDATE ON public.audit_events FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_event_mutation();


--
-- Name: audit_events fk_rails_2e3720791c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT fk_rails_2e3720791c FOREIGN KEY (actor_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: sessions fk_rails_758836b4f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261125160200'),
('20261125160100'),
('20261125160000'),
('20261125150000'),
('20261125140000'),
('20261125130200'),
('20261125130100'),
('20261125130000');

