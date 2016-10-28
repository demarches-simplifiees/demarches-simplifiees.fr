--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.4
-- Dumped by pg_dump version 9.5.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: administrateurs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE administrateurs (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    api_token character varying
);


--
-- Name: administrateurs_gestionnaires; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE administrateurs_gestionnaires (
    administrateur_id integer,
    gestionnaire_id integer
);


--
-- Name: administrateurs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE administrateurs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: administrateurs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE administrateurs_id_seq OWNED BY administrateurs.id;


--
-- Name: administrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE administrations (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: administrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE administrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: administrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE administrations_id_seq OWNED BY administrations.id;


--
-- Name: assign_tos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE assign_tos (
    gestionnaire_id integer,
    procedure_id integer
);


--
-- Name: cadastres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cadastres (
    id integer NOT NULL,
    surface_intersection character varying,
    surface_parcelle double precision,
    numero character varying,
    feuille integer,
    section character varying,
    code_dep character varying,
    nom_com character varying,
    code_com character varying,
    code_arr character varying,
    geometry text,
    dossier_id integer
);


--
-- Name: cadastres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cadastres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cadastres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cadastres_id_seq OWNED BY cadastres.id;


--
-- Name: cerfas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cerfas (
    id integer NOT NULL,
    content character varying,
    dossier_id integer,
    created_at timestamp without time zone,
    user_id integer,
    original_filename character varying,
    content_secure_token character varying
);


--
-- Name: cerfas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cerfas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cerfas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cerfas_id_seq OWNED BY cerfas.id;


--
-- Name: champs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE champs (
    id integer NOT NULL,
    value character varying,
    type_de_champ_id integer,
    dossier_id integer,
    type character varying
);


--
-- Name: champs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE champs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: champs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE champs_id_seq OWNED BY champs.id;


--
-- Name: commentaires; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE commentaires (
    id integer NOT NULL,
    email character varying,
    created_at timestamp without time zone NOT NULL,
    body character varying,
    dossier_id integer,
    updated_at timestamp without time zone NOT NULL,
    piece_justificative_id integer
);


--
-- Name: commentaires_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE commentaires_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: commentaires_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE commentaires_id_seq OWNED BY commentaires.id;


--
-- Name: dossiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE dossiers (
    id integer NOT NULL,
    autorisation_donnees boolean,
    nom_projet character varying,
    procedure_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    state character varying,
    user_id integer,
    json_latlngs text,
    archived boolean DEFAULT false,
    mandataire_social boolean DEFAULT false,
    deposit_datetime timestamp without time zone
);


--
-- Name: dossiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE dossiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dossiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE dossiers_id_seq OWNED BY dossiers.id;


--
-- Name: drop_down_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE drop_down_lists (
    id integer NOT NULL,
    value character varying,
    type_de_champ_id integer
);


--
-- Name: drop_down_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE drop_down_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: drop_down_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE drop_down_lists_id_seq OWNED BY drop_down_lists.id;


--
-- Name: entreprises; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE entreprises (
    id integer NOT NULL,
    siren character varying,
    capital_social integer,
    numero_tva_intracommunautaire character varying,
    forme_juridique character varying,
    forme_juridique_code character varying,
    nom_commercial character varying,
    raison_sociale character varying,
    siret_siege_social character varying,
    code_effectif_entreprise character varying,
    date_creation timestamp without time zone,
    nom character varying,
    prenom character varying,
    dossier_id integer
);


--
-- Name: entreprises_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE entreprises_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entreprises_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE entreprises_id_seq OWNED BY entreprises.id;


--
-- Name: etablissements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE etablissements (
    id integer NOT NULL,
    siret character varying,
    siege_social boolean,
    naf character varying,
    libelle_naf character varying,
    adresse character varying,
    numero_voie character varying,
    type_voie character varying,
    nom_voie character varying,
    complement_adresse character varying,
    code_postal character varying,
    localite character varying,
    code_insee_localite character varying,
    dossier_id integer,
    entreprise_id integer
);


--
-- Name: etablissements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE etablissements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: etablissements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE etablissements_id_seq OWNED BY etablissements.id;


--
-- Name: exercices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE exercices (
    id integer NOT NULL,
    ca character varying,
    "dateFinExercice" timestamp without time zone,
    date_fin_exercice_timestamp integer,
    etablissement_id integer
);


--
-- Name: exercices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE exercices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exercices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE exercices_id_seq OWNED BY exercices.id;


--
-- Name: follows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE follows (
    id integer NOT NULL,
    gestionnaire_id integer,
    dossier_id integer
);


--
-- Name: follows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE follows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: follows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE follows_id_seq OWNED BY follows.id;


--
-- Name: france_connect_informations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE france_connect_informations (
    id integer NOT NULL,
    gender character varying,
    given_name character varying,
    family_name character varying,
    birthdate date,
    birthplace character varying,
    france_connect_particulier_id character varying,
    user_id integer,
    email_france_connect character varying
);


--
-- Name: france_connect_informations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE france_connect_informations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: france_connect_informations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE france_connect_informations_id_seq OWNED BY france_connect_informations.id;


--
-- Name: gestionnaires; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gestionnaires (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    procedure_filter integer
);


--
-- Name: gestionnaires_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gestionnaires_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gestionnaires_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gestionnaires_id_seq OWNED BY gestionnaires.id;


--
-- Name: individuals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE individuals (
    id integer NOT NULL,
    nom character varying,
    prenom character varying,
    birthdate character varying,
    dossier_id integer,
    gender character varying
);


--
-- Name: individuals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE individuals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: individuals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE individuals_id_seq OWNED BY individuals.id;


--
-- Name: invites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE invites (
    id integer NOT NULL,
    email character varying,
    email_sender character varying,
    dossier_id integer,
    user_id integer,
    type character varying DEFAULT 'InviteGestionnaire'::character varying
);


--
-- Name: invites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invites_id_seq OWNED BY invites.id;


--
-- Name: mail_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mail_templates (
    id integer NOT NULL,
    object character varying,
    body text,
    type character varying,
    procedure_id integer
);


--
-- Name: mail_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mail_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mail_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mail_templates_id_seq OWNED BY mail_templates.id;


--
-- Name: module_api_cartos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE module_api_cartos (
    id integer NOT NULL,
    procedure_id integer,
    use_api_carto boolean DEFAULT false,
    quartiers_prioritaires boolean DEFAULT false,
    cadastre boolean DEFAULT false
);


--
-- Name: module_api_cartos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE module_api_cartos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: module_api_cartos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE module_api_cartos_id_seq OWNED BY module_api_cartos.id;


--
-- Name: pieces_justificatives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pieces_justificatives (
    id integer NOT NULL,
    content character varying,
    dossier_id integer,
    type_de_piece_justificative_id integer,
    created_at timestamp without time zone,
    user_id integer,
    original_filename character varying,
    content_secure_token character varying
);


--
-- Name: pieces_justificatives_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pieces_justificatives_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pieces_justificatives_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pieces_justificatives_id_seq OWNED BY pieces_justificatives.id;


--
-- Name: preference_list_dossiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE preference_list_dossiers (
    id integer NOT NULL,
    libelle character varying,
    "table" character varying,
    attr character varying,
    attr_decorate character varying,
    bootstrap_lg character varying,
    "order" character varying,
    filter character varying,
    gestionnaire_id integer,
    procedure_id integer
);


--
-- Name: preference_list_dossiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE preference_list_dossiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: preference_list_dossiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE preference_list_dossiers_id_seq OWNED BY preference_list_dossiers.id;


--
-- Name: preference_smart_listing_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE preference_smart_listing_pages (
    id integer NOT NULL,
    liste character varying,
    page integer,
    procedure_id integer,
    gestionnaire_id integer
);


--
-- Name: preference_smart_listing_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE preference_smart_listing_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: preference_smart_listing_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE preference_smart_listing_pages_id_seq OWNED BY preference_smart_listing_pages.id;


--
-- Name: procedure_paths; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE procedure_paths (
    id integer NOT NULL,
    path character varying(30),
    procedure_id integer,
    administrateur_id integer
);


--
-- Name: procedure_paths_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE procedure_paths_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: procedure_paths_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE procedure_paths_id_seq OWNED BY procedure_paths.id;


--
-- Name: procedures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE procedures (
    id integer NOT NULL,
    libelle character varying,
    description character varying,
    organisation character varying,
    direction character varying,
    lien_demarche character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    test boolean,
    administrateur_id integer,
    archived boolean DEFAULT false,
    euro_flag boolean DEFAULT false,
    logo character varying,
    cerfa_flag boolean DEFAULT false,
    logo_secure_token character varying,
    published boolean DEFAULT false NOT NULL,
    lien_site_web character varying,
    lien_notice character varying,
    for_individual boolean DEFAULT false,
    individual_with_siret boolean DEFAULT false
);


--
-- Name: procedures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE procedures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: procedures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE procedures_id_seq OWNED BY procedures.id;


--
-- Name: quartier_prioritaires; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quartier_prioritaires (
    id integer NOT NULL,
    code character varying,
    nom character varying,
    commune character varying,
    geometry text,
    dossier_id integer
);


--
-- Name: quartier_prioritaires_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE quartier_prioritaires_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quartier_prioritaires_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE quartier_prioritaires_id_seq OWNED BY quartier_prioritaires.id;


--
-- Name: rna_informations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE rna_informations (
    id integer NOT NULL,
    association_id character varying,
    titre character varying,
    objet text,
    date_creation date,
    date_declaration date,
    date_publication date,
    entreprise_id integer
);


--
-- Name: rna_informations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE rna_informations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rna_informations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rna_informations_id_seq OWNED BY rna_informations.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    siret character varying,
    loged_in_with_france_connect character varying DEFAULT false
);


--
-- Name: searches; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW searches AS
 SELECT dossiers.id AS dossier_id,
    (((dossiers.id)::text || ' '::text) || (COALESCE(users.email, ''::character varying))::text) AS term
   FROM (dossiers
     JOIN users ON ((users.id = dossiers.user_id)))
UNION
 SELECT cerfas.dossier_id,
    COALESCE(cerfas.content, ''::character varying) AS term
   FROM cerfas
UNION
 SELECT champs.dossier_id,
    (((COALESCE(champs.value, ''::character varying))::text || ' '::text) || (COALESCE(drop_down_lists.value, ''::character varying))::text) AS term
   FROM (champs
     JOIN drop_down_lists ON ((drop_down_lists.type_de_champ_id = champs.type_de_champ_id)))
UNION
 SELECT entreprises.dossier_id,
    (((((((((((((((((((((((COALESCE(entreprises.siren, ''::character varying))::text || ' '::text) || (COALESCE(entreprises.numero_tva_intracommunautaire, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.forme_juridique, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.forme_juridique_code, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.nom_commercial, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.raison_sociale, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.siret_siege_social, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.nom, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.prenom, ''::character varying))::text) || ' '::text) || (COALESCE(rna_informations.association_id, ''::character varying))::text) || ' '::text) || (COALESCE(rna_informations.titre, ''::character varying))::text) || ' '::text) || COALESCE(rna_informations.objet, ''::text)) AS term
   FROM (entreprises
     LEFT JOIN rna_informations ON ((rna_informations.entreprise_id = entreprises.id)))
UNION
 SELECT etablissements.dossier_id,
    (((((((((((((COALESCE(etablissements.siret, ''::character varying))::text || ' '::text) || (COALESCE(etablissements.naf, ''::character varying))::text) || ' '::text) || (COALESCE(etablissements.libelle_naf, ''::character varying))::text) || ' '::text) || (COALESCE(etablissements.adresse, ''::character varying))::text) || ' '::text) || (COALESCE(etablissements.code_postal, ''::character varying))::text) || ' '::text) || (COALESCE(etablissements.localite, ''::character varying))::text) || ' '::text) || (COALESCE(etablissements.code_insee_localite, ''::character varying))::text) AS term
   FROM etablissements
UNION
 SELECT individuals.dossier_id,
    (((COALESCE(individuals.nom, ''::character varying))::text || ' '::text) || (COALESCE(individuals.prenom, ''::character varying))::text) AS term
   FROM individuals
UNION
 SELECT pieces_justificatives.dossier_id,
    COALESCE(pieces_justificatives.content, ''::character varying) AS term
   FROM pieces_justificatives
UNION
 SELECT dossiers.id AS dossier_id,
    (((COALESCE(france_connect_informations.given_name, ''::character varying))::text || ' '::text) || (COALESCE(france_connect_informations.family_name, ''::character varying))::text) AS term
   FROM (france_connect_informations
     JOIN dossiers ON ((dossiers.user_id = france_connect_informations.user_id)));


--
-- Name: types_de_champ; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE types_de_champ (
    id integer NOT NULL,
    libelle character varying,
    type_champ character varying,
    order_place integer,
    procedure_id integer,
    description text,
    mandatory boolean DEFAULT false,
    type character varying
);


--
-- Name: types_de_champ_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE types_de_champ_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: types_de_champ_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE types_de_champ_id_seq OWNED BY types_de_champ.id;


--
-- Name: types_de_piece_justificative; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE types_de_piece_justificative (
    id integer NOT NULL,
    libelle character varying,
    description character varying,
    api_entreprise boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    procedure_id integer,
    order_place integer
);


--
-- Name: types_de_piece_justificative_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE types_de_piece_justificative_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: types_de_piece_justificative_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE types_de_piece_justificative_id_seq OWNED BY types_de_piece_justificative.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY administrateurs ALTER COLUMN id SET DEFAULT nextval('administrateurs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY administrations ALTER COLUMN id SET DEFAULT nextval('administrations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cadastres ALTER COLUMN id SET DEFAULT nextval('cadastres_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cerfas ALTER COLUMN id SET DEFAULT nextval('cerfas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY champs ALTER COLUMN id SET DEFAULT nextval('champs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY commentaires ALTER COLUMN id SET DEFAULT nextval('commentaires_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY dossiers ALTER COLUMN id SET DEFAULT nextval('dossiers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY drop_down_lists ALTER COLUMN id SET DEFAULT nextval('drop_down_lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY entreprises ALTER COLUMN id SET DEFAULT nextval('entreprises_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY etablissements ALTER COLUMN id SET DEFAULT nextval('etablissements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY exercices ALTER COLUMN id SET DEFAULT nextval('exercices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY follows ALTER COLUMN id SET DEFAULT nextval('follows_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY france_connect_informations ALTER COLUMN id SET DEFAULT nextval('france_connect_informations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gestionnaires ALTER COLUMN id SET DEFAULT nextval('gestionnaires_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY individuals ALTER COLUMN id SET DEFAULT nextval('individuals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY invites ALTER COLUMN id SET DEFAULT nextval('invites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_templates ALTER COLUMN id SET DEFAULT nextval('mail_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY module_api_cartos ALTER COLUMN id SET DEFAULT nextval('module_api_cartos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pieces_justificatives ALTER COLUMN id SET DEFAULT nextval('pieces_justificatives_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY preference_list_dossiers ALTER COLUMN id SET DEFAULT nextval('preference_list_dossiers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY preference_smart_listing_pages ALTER COLUMN id SET DEFAULT nextval('preference_smart_listing_pages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY procedure_paths ALTER COLUMN id SET DEFAULT nextval('procedure_paths_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY procedures ALTER COLUMN id SET DEFAULT nextval('procedures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY quartier_prioritaires ALTER COLUMN id SET DEFAULT nextval('quartier_prioritaires_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY rna_informations ALTER COLUMN id SET DEFAULT nextval('rna_informations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY types_de_champ ALTER COLUMN id SET DEFAULT nextval('types_de_champ_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY types_de_piece_justificative ALTER COLUMN id SET DEFAULT nextval('types_de_piece_justificative_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: administrateurs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY administrateurs
    ADD CONSTRAINT administrateurs_pkey PRIMARY KEY (id);


--
-- Name: administrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY administrations
    ADD CONSTRAINT administrations_pkey PRIMARY KEY (id);


--
-- Name: cadastres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cadastres
    ADD CONSTRAINT cadastres_pkey PRIMARY KEY (id);


--
-- Name: cerfas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cerfas
    ADD CONSTRAINT cerfas_pkey PRIMARY KEY (id);


--
-- Name: champs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY champs
    ADD CONSTRAINT champs_pkey PRIMARY KEY (id);


--
-- Name: commentaires_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY commentaires
    ADD CONSTRAINT commentaires_pkey PRIMARY KEY (id);


--
-- Name: dossiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dossiers
    ADD CONSTRAINT dossiers_pkey PRIMARY KEY (id);


--
-- Name: drop_down_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY drop_down_lists
    ADD CONSTRAINT drop_down_lists_pkey PRIMARY KEY (id);


--
-- Name: entreprises_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entreprises
    ADD CONSTRAINT entreprises_pkey PRIMARY KEY (id);


--
-- Name: etablissements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY etablissements
    ADD CONSTRAINT etablissements_pkey PRIMARY KEY (id);


--
-- Name: exercices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY exercices
    ADD CONSTRAINT exercices_pkey PRIMARY KEY (id);


--
-- Name: follows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY follows
    ADD CONSTRAINT follows_pkey PRIMARY KEY (id);


--
-- Name: france_connect_informations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY france_connect_informations
    ADD CONSTRAINT france_connect_informations_pkey PRIMARY KEY (id);


--
-- Name: gestionnaires_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gestionnaires
    ADD CONSTRAINT gestionnaires_pkey PRIMARY KEY (id);


--
-- Name: individuals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY individuals
    ADD CONSTRAINT individuals_pkey PRIMARY KEY (id);


--
-- Name: invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invites
    ADD CONSTRAINT invites_pkey PRIMARY KEY (id);


--
-- Name: mail_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_templates
    ADD CONSTRAINT mail_templates_pkey PRIMARY KEY (id);


--
-- Name: module_api_cartos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY module_api_cartos
    ADD CONSTRAINT module_api_cartos_pkey PRIMARY KEY (id);


--
-- Name: pieces_justificatives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pieces_justificatives
    ADD CONSTRAINT pieces_justificatives_pkey PRIMARY KEY (id);


--
-- Name: preference_list_dossiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY preference_list_dossiers
    ADD CONSTRAINT preference_list_dossiers_pkey PRIMARY KEY (id);


--
-- Name: preference_smart_listing_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY preference_smart_listing_pages
    ADD CONSTRAINT preference_smart_listing_pages_pkey PRIMARY KEY (id);


--
-- Name: procedure_paths_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY procedure_paths
    ADD CONSTRAINT procedure_paths_pkey PRIMARY KEY (id);


--
-- Name: procedures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY procedures
    ADD CONSTRAINT procedures_pkey PRIMARY KEY (id);


--
-- Name: quartier_prioritaires_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quartier_prioritaires
    ADD CONSTRAINT quartier_prioritaires_pkey PRIMARY KEY (id);


--
-- Name: rna_informations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rna_informations
    ADD CONSTRAINT rna_informations_pkey PRIMARY KEY (id);


--
-- Name: types_de_champ_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY types_de_champ
    ADD CONSTRAINT types_de_champ_pkey PRIMARY KEY (id);


--
-- Name: types_de_piece_justificative_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY types_de_piece_justificative
    ADD CONSTRAINT types_de_piece_justificative_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_administrateurs_gestionnaires_on_administrateur_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_administrateurs_gestionnaires_on_administrateur_id ON administrateurs_gestionnaires USING btree (administrateur_id);


--
-- Name: index_administrateurs_gestionnaires_on_gestionnaire_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_administrateurs_gestionnaires_on_gestionnaire_id ON administrateurs_gestionnaires USING btree (gestionnaire_id);


--
-- Name: index_administrateurs_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_administrateurs_on_email ON administrateurs USING btree (email);


--
-- Name: index_administrateurs_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_administrateurs_on_reset_password_token ON administrateurs USING btree (reset_password_token);


--
-- Name: index_administrations_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_administrations_on_email ON administrations USING btree (email);


--
-- Name: index_administrations_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_administrations_on_reset_password_token ON administrations USING btree (reset_password_token);


--
-- Name: index_assign_tos_on_gestionnaire_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assign_tos_on_gestionnaire_id ON assign_tos USING btree (gestionnaire_id);


--
-- Name: index_assign_tos_on_procedure_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assign_tos_on_procedure_id ON assign_tos USING btree (procedure_id);


--
-- Name: index_cerfas_on_dossier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cerfas_on_dossier_id ON cerfas USING btree (dossier_id);


--
-- Name: index_champs_on_dossier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_champs_on_dossier_id ON champs USING btree (dossier_id);


--
-- Name: index_champs_on_type_de_champ_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_champs_on_type_de_champ_id ON champs USING btree (type_de_champ_id);


--
-- Name: index_commentaires_on_dossier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_commentaires_on_dossier_id ON commentaires USING btree (dossier_id);


--
-- Name: index_dossiers_on_procedure_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dossiers_on_procedure_id ON dossiers USING btree (procedure_id);


--
-- Name: index_dossiers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dossiers_on_user_id ON dossiers USING btree (user_id);


--
-- Name: index_drop_down_lists_on_type_de_champ_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drop_down_lists_on_type_de_champ_id ON drop_down_lists USING btree (type_de_champ_id);


--
-- Name: index_entreprises_on_dossier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entreprises_on_dossier_id ON entreprises USING btree (dossier_id);


--
-- Name: index_etablissements_on_dossier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_etablissements_on_dossier_id ON etablissements USING btree (dossier_id);


--
-- Name: index_follows_on_dossier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follows_on_dossier_id ON follows USING btree (dossier_id);


--
-- Name: index_follows_on_gestionnaire_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follows_on_gestionnaire_id ON follows USING btree (gestionnaire_id);


--
-- Name: index_france_connect_informations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_france_connect_informations_on_user_id ON france_connect_informations USING btree (user_id);


--
-- Name: index_gestionnaires_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_gestionnaires_on_email ON gestionnaires USING btree (email);


--
-- Name: index_gestionnaires_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_gestionnaires_on_reset_password_token ON gestionnaires USING btree (reset_password_token);


--
-- Name: index_individuals_on_dossier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_individuals_on_dossier_id ON individuals USING btree (dossier_id);


--
-- Name: index_module_api_cartos_on_procedure_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_module_api_cartos_on_procedure_id ON module_api_cartos USING btree (procedure_id);


--
-- Name: index_pieces_justificatives_on_dossier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pieces_justificatives_on_dossier_id ON pieces_justificatives USING btree (dossier_id);


--
-- Name: index_pieces_justificatives_on_type_de_piece_justificative_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pieces_justificatives_on_type_de_piece_justificative_id ON pieces_justificatives USING btree (type_de_piece_justificative_id);


--
-- Name: index_procedure_paths_on_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_procedure_paths_on_path ON procedure_paths USING btree (path);


--
-- Name: index_rna_informations_on_entreprise_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rna_informations_on_entreprise_id ON rna_informations USING btree (entreprise_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: unique_couple_administrateur_gestionnaire; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_couple_administrateur_gestionnaire ON administrateurs_gestionnaires USING btree (gestionnaire_id, administrateur_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: fk_rails_2692c11f42; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cerfas
    ADD CONSTRAINT fk_rails_2692c11f42 FOREIGN KEY (dossier_id) REFERENCES dossiers(id);


--
-- Name: fk_rails_3ba5f624df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY procedure_paths
    ADD CONSTRAINT fk_rails_3ba5f624df FOREIGN KEY (administrateur_id) REFERENCES administrateurs(id);


--
-- Name: fk_rails_7238f4c1f2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY procedure_paths
    ADD CONSTRAINT fk_rails_7238f4c1f2 FOREIGN KEY (procedure_id) REFERENCES procedures(id);


--
-- Name: fk_rails_7a18851d0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dossiers
    ADD CONSTRAINT fk_rails_7a18851d0c FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_e74708c22b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY commentaires
    ADD CONSTRAINT fk_rails_e74708c22b FOREIGN KEY (dossier_id) REFERENCES dossiers(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20150623121437');

INSERT INTO schema_migrations (version) VALUES ('20150623122513');

INSERT INTO schema_migrations (version) VALUES ('20150623123033');

INSERT INTO schema_migrations (version) VALUES ('20150624134202');

INSERT INTO schema_migrations (version) VALUES ('20150624145400');

INSERT INTO schema_migrations (version) VALUES ('20150625130851');

INSERT INTO schema_migrations (version) VALUES ('20150626081655');

INSERT INTO schema_migrations (version) VALUES ('20150630123827');

INSERT INTO schema_migrations (version) VALUES ('20150728140340');

INSERT INTO schema_migrations (version) VALUES ('20150731121101');

INSERT INTO schema_migrations (version) VALUES ('20150804131511');

INSERT INTO schema_migrations (version) VALUES ('20150805081131');

INSERT INTO schema_migrations (version) VALUES ('20150806071130');

INSERT INTO schema_migrations (version) VALUES ('20150806072031');

INSERT INTO schema_migrations (version) VALUES ('20150806075144');

INSERT INTO schema_migrations (version) VALUES ('20150806132417');

INSERT INTO schema_migrations (version) VALUES ('20150806155734');

INSERT INTO schema_migrations (version) VALUES ('20150806162353');

INSERT INTO schema_migrations (version) VALUES ('20150810130957');

INSERT INTO schema_migrations (version) VALUES ('20150812091703');

INSERT INTO schema_migrations (version) VALUES ('20150813095218');

INSERT INTO schema_migrations (version) VALUES ('20150813095939');

INSERT INTO schema_migrations (version) VALUES ('20150814090717');

INSERT INTO schema_migrations (version) VALUES ('20150814101012');

INSERT INTO schema_migrations (version) VALUES ('20150814120635');

INSERT INTO schema_migrations (version) VALUES ('20150814121848');

INSERT INTO schema_migrations (version) VALUES ('20150814122208');

INSERT INTO schema_migrations (version) VALUES ('20150814124735');

INSERT INTO schema_migrations (version) VALUES ('20150818113123');

INSERT INTO schema_migrations (version) VALUES ('20150824134012');

INSERT INTO schema_migrations (version) VALUES ('20150825083550');

INSERT INTO schema_migrations (version) VALUES ('20150918163159');

INSERT INTO schema_migrations (version) VALUES ('20150921085540');

INSERT INTO schema_migrations (version) VALUES ('20150921085754');

INSERT INTO schema_migrations (version) VALUES ('20150921092320');

INSERT INTO schema_migrations (version) VALUES ('20150921092536');

INSERT INTO schema_migrations (version) VALUES ('20150921101240');

INSERT INTO schema_migrations (version) VALUES ('20150922082053');

INSERT INTO schema_migrations (version) VALUES ('20150922082416');

INSERT INTO schema_migrations (version) VALUES ('20150922085811');

INSERT INTO schema_migrations (version) VALUES ('20150922110719');

INSERT INTO schema_migrations (version) VALUES ('20150922113504');

INSERT INTO schema_migrations (version) VALUES ('20150922141000');

INSERT INTO schema_migrations (version) VALUES ('20150922141232');

INSERT INTO schema_migrations (version) VALUES ('20150923101000');

INSERT INTO schema_migrations (version) VALUES ('20150928141512');

INSERT INTO schema_migrations (version) VALUES ('20151006155256');

INSERT INTO schema_migrations (version) VALUES ('20151007085022');

INSERT INTO schema_migrations (version) VALUES ('20151008090835');

INSERT INTO schema_migrations (version) VALUES ('20151023132121');

INSERT INTO schema_migrations (version) VALUES ('20151026155158');

INSERT INTO schema_migrations (version) VALUES ('20151027150850');

INSERT INTO schema_migrations (version) VALUES ('20151102101616');

INSERT INTO schema_migrations (version) VALUES ('20151102102747');

INSERT INTO schema_migrations (version) VALUES ('20151102104309');

INSERT INTO schema_migrations (version) VALUES ('20151102105011');

INSERT INTO schema_migrations (version) VALUES ('20151102135824');

INSERT INTO schema_migrations (version) VALUES ('20151102142940');

INSERT INTO schema_migrations (version) VALUES ('20151102143908');

INSERT INTO schema_migrations (version) VALUES ('20151102163051');

INSERT INTO schema_migrations (version) VALUES ('20151103091603');

INSERT INTO schema_migrations (version) VALUES ('20151105093644');

INSERT INTO schema_migrations (version) VALUES ('20151105095431');

INSERT INTO schema_migrations (version) VALUES ('20151110091159');

INSERT INTO schema_migrations (version) VALUES ('20151110091451');

INSERT INTO schema_migrations (version) VALUES ('20151112151918');

INSERT INTO schema_migrations (version) VALUES ('20151113171605');

INSERT INTO schema_migrations (version) VALUES ('20151116175817');

INSERT INTO schema_migrations (version) VALUES ('20151124085333');

INSERT INTO schema_migrations (version) VALUES ('20151126153425');

INSERT INTO schema_migrations (version) VALUES ('20151127103412');

INSERT INTO schema_migrations (version) VALUES ('20151207095904');

INSERT INTO schema_migrations (version) VALUES ('20151207140202');

INSERT INTO schema_migrations (version) VALUES ('20151210134135');

INSERT INTO schema_migrations (version) VALUES ('20151210150958');

INSERT INTO schema_migrations (version) VALUES ('20151211093833');

INSERT INTO schema_migrations (version) VALUES ('20151214133426');

INSERT INTO schema_migrations (version) VALUES ('20151221164041');

INSERT INTO schema_migrations (version) VALUES ('20151222105558');

INSERT INTO schema_migrations (version) VALUES ('20151223101322');

INSERT INTO schema_migrations (version) VALUES ('20160106100227');

INSERT INTO schema_migrations (version) VALUES ('20160115135025');

INSERT INTO schema_migrations (version) VALUES ('20160120094750');

INSERT INTO schema_migrations (version) VALUES ('20160120141602');

INSERT INTO schema_migrations (version) VALUES ('20160121110603');

INSERT INTO schema_migrations (version) VALUES ('20160127162841');

INSERT INTO schema_migrations (version) VALUES ('20160127170437');

INSERT INTO schema_migrations (version) VALUES ('20160204155519');

INSERT INTO schema_migrations (version) VALUES ('20160223134354');

INSERT INTO schema_migrations (version) VALUES ('20160314102523');

INSERT INTO schema_migrations (version) VALUES ('20160314160801');

INSERT INTO schema_migrations (version) VALUES ('20160314161959');

INSERT INTO schema_migrations (version) VALUES ('20160315101245');

INSERT INTO schema_migrations (version) VALUES ('20160317135217');

INSERT INTO schema_migrations (version) VALUES ('20160317144949');

INSERT INTO schema_migrations (version) VALUES ('20160317153115');

INSERT INTO schema_migrations (version) VALUES ('20160419142017');

INSERT INTO schema_migrations (version) VALUES ('20160512160602');

INSERT INTO schema_migrations (version) VALUES ('20160512160658');

INSERT INTO schema_migrations (version) VALUES ('20160512160824');

INSERT INTO schema_migrations (version) VALUES ('20160512160836');

INSERT INTO schema_migrations (version) VALUES ('20160513093425');

INSERT INTO schema_migrations (version) VALUES ('20160519100904');

INSERT INTO schema_migrations (version) VALUES ('20160519101018');

INSERT INTO schema_migrations (version) VALUES ('20160523163054');

INSERT INTO schema_migrations (version) VALUES ('20160524093540');

INSERT INTO schema_migrations (version) VALUES ('20160607150440');

INSERT INTO schema_migrations (version) VALUES ('20160609125949');

INSERT INTO schema_migrations (version) VALUES ('20160609145737');

INSERT INTO schema_migrations (version) VALUES ('20160622081321');

INSERT INTO schema_migrations (version) VALUES ('20160622081322');

INSERT INTO schema_migrations (version) VALUES ('20160718124741');

INSERT INTO schema_migrations (version) VALUES ('20160722135927');

INSERT INTO schema_migrations (version) VALUES ('20160802113112');

INSERT INTO schema_migrations (version) VALUES ('20160802131031');

INSERT INTO schema_migrations (version) VALUES ('20160802161734');

INSERT INTO schema_migrations (version) VALUES ('20160803081304');

INSERT INTO schema_migrations (version) VALUES ('20160804130638');

INSERT INTO schema_migrations (version) VALUES ('20160808115924');

INSERT INTO schema_migrations (version) VALUES ('20160809083606');

INSERT INTO schema_migrations (version) VALUES ('20160822142045');

INSERT INTO schema_migrations (version) VALUES ('20160824094151');

INSERT INTO schema_migrations (version) VALUES ('20160824094451');

INSERT INTO schema_migrations (version) VALUES ('20160829094658');

INSERT INTO schema_migrations (version) VALUES ('20160829114646');

INSERT INTO schema_migrations (version) VALUES ('20160830142653');

INSERT INTO schema_migrations (version) VALUES ('20160901082824');

INSERT INTO schema_migrations (version) VALUES ('20160906123255');

INSERT INTO schema_migrations (version) VALUES ('20160906134155');

INSERT INTO schema_migrations (version) VALUES ('20160913093948');

INSERT INTO schema_migrations (version) VALUES ('20160926160051');

INSERT INTO schema_migrations (version) VALUES ('20160927154248');

INSERT INTO schema_migrations (version) VALUES ('20161004175442');

INSERT INTO schema_migrations (version) VALUES ('20161005082113');

INSERT INTO schema_migrations (version) VALUES ('20161005144657');

INSERT INTO schema_migrations (version) VALUES ('20161006085422');

INSERT INTO schema_migrations (version) VALUES ('20161007095443');

INSERT INTO schema_migrations (version) VALUES ('20161011125345');

INSERT INTO schema_migrations (version) VALUES ('20161025150900');

