# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_02_06_153121) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "administrateurs", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "api_token"
    t.boolean "active", default: false
    t.index ["email"], name: "index_administrateurs_on_email", unique: true
    t.index ["reset_password_token"], name: "index_administrateurs_on_reset_password_token", unique: true
  end

  create_table "administrateurs_gestionnaires", id: false, force: :cascade do |t|
    t.integer "administrateur_id"
    t.integer "gestionnaire_id"
    t.index ["administrateur_id"], name: "index_administrateurs_gestionnaires_on_administrateur_id"
    t.index ["gestionnaire_id", "administrateur_id"], name: "unique_couple_administrateur_gestionnaire", unique: true
    t.index ["gestionnaire_id"], name: "index_administrateurs_gestionnaires_on_gestionnaire_id"
  end

  create_table "administrations", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["email"], name: "index_administrations_on_email", unique: true
    t.index ["reset_password_token"], name: "index_administrations_on_reset_password_token", unique: true
  end

  create_table "assign_tos", id: :serial, force: :cascade do |t|
    t.integer "gestionnaire_id"
    t.integer "procedure_id"
    t.index ["gestionnaire_id"], name: "index_assign_tos_on_gestionnaire_id"
    t.index ["procedure_id"], name: "index_assign_tos_on_procedure_id"
  end

  create_table "attestation_templates", id: :serial, force: :cascade do |t|
    t.text "title"
    t.text "body"
    t.text "footer"
    t.string "logo"
    t.string "signature"
    t.boolean "activated"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "procedure_id"
    t.string "logo_secure_token"
    t.string "signature_secure_token"
    t.index ["procedure_id"], name: "index_attestation_templates_on_procedure_id", unique: true
  end

  create_table "attestations", id: :serial, force: :cascade do |t|
    t.string "pdf"
    t.string "title"
    t.integer "dossier_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "content_secure_token"
    t.index ["dossier_id"], name: "index_attestations_on_dossier_id"
  end

  create_table "avis", id: :serial, force: :cascade do |t|
    t.string "email"
    t.text "introduction"
    t.text "answer"
    t.integer "gestionnaire_id"
    t.integer "dossier_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "claimant_id", null: false
    t.boolean "confidentiel", default: false, null: false
    t.index ["claimant_id"], name: "index_avis_on_claimant_id"
    t.index ["dossier_id"], name: "index_avis_on_dossier_id"
    t.index ["gestionnaire_id"], name: "index_avis_on_gestionnaire_id"
  end

  create_table "cadastres", id: :serial, force: :cascade do |t|
    t.string "surface_intersection"
    t.float "surface_parcelle"
    t.string "numero"
    t.integer "feuille"
    t.string "section"
    t.string "code_dep"
    t.string "nom_com"
    t.string "code_com"
    t.string "code_arr"
    t.text "geometry"
    t.integer "dossier_id"
  end

  create_table "cerfas", id: :serial, force: :cascade do |t|
    t.string "content"
    t.integer "dossier_id"
    t.datetime "created_at"
    t.integer "user_id"
    t.string "original_filename"
    t.string "content_secure_token"
    t.index ["dossier_id"], name: "index_cerfas_on_dossier_id"
  end

  create_table "champs", id: :serial, force: :cascade do |t|
    t.string "value"
    t.integer "type_de_champ_id"
    t.integer "dossier_id"
    t.string "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["dossier_id"], name: "index_champs_on_dossier_id"
    t.index ["type_de_champ_id"], name: "index_champs_on_type_de_champ_id"
  end

  create_table "closed_mails", id: :serial, force: :cascade do |t|
    t.text "body"
    t.string "subject"
    t.integer "procedure_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_closed_mails_on_procedure_id"
  end

  create_table "commentaires", id: :serial, force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.string "body"
    t.integer "dossier_id"
    t.datetime "updated_at", null: false
    t.integer "piece_justificative_id"
    t.integer "champ_id"
    t.string "file"
    t.index ["champ_id"], name: "index_commentaires_on_champ_id"
    t.index ["dossier_id"], name: "index_commentaires_on_dossier_id"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "cron"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "dossiers", id: :serial, force: :cascade do |t|
    t.boolean "autorisation_donnees"
    t.integer "procedure_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "state"
    t.integer "user_id"
    t.text "json_latlngs"
    t.boolean "archived", default: false
    t.boolean "mandataire_social", default: false
    t.datetime "en_construction_at"
    t.datetime "en_instruction_at"
    t.datetime "processed_at"
    t.text "motivation"
    t.datetime "hidden_at"
    t.index ["hidden_at"], name: "index_dossiers_on_hidden_at"
    t.index ["procedure_id"], name: "index_dossiers_on_procedure_id"
    t.index ["user_id"], name: "index_dossiers_on_user_id"
  end

  create_table "drop_down_lists", id: :serial, force: :cascade do |t|
    t.string "value"
    t.integer "type_de_champ_id"
    t.index ["type_de_champ_id"], name: "index_drop_down_lists_on_type_de_champ_id"
  end

  create_table "entreprises", id: :serial, force: :cascade do |t|
    t.string "siren"
    t.integer "capital_social"
    t.string "numero_tva_intracommunautaire"
    t.string "forme_juridique"
    t.string "forme_juridique_code"
    t.string "nom_commercial"
    t.string "raison_sociale"
    t.string "siret_siege_social"
    t.string "code_effectif_entreprise"
    t.datetime "date_creation"
    t.string "nom"
    t.string "prenom"
    t.integer "dossier_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["dossier_id"], name: "index_entreprises_on_dossier_id"
  end

  create_table "etablissements", id: :serial, force: :cascade do |t|
    t.string "siret"
    t.boolean "siege_social"
    t.string "naf"
    t.string "libelle_naf"
    t.string "adresse"
    t.string "numero_voie"
    t.string "type_voie"
    t.string "nom_voie"
    t.string "complement_adresse"
    t.string "code_postal"
    t.string "localite"
    t.string "code_insee_localite"
    t.integer "dossier_id"
    t.integer "entreprise_id"
    t.index ["dossier_id"], name: "index_etablissements_on_dossier_id"
  end

  create_table "exercices", id: :serial, force: :cascade do |t|
    t.string "ca"
    t.datetime "dateFinExercice"
    t.integer "date_fin_exercice_timestamp"
    t.integer "etablissement_id"
  end

  create_table "follows", id: :serial, force: :cascade do |t|
    t.integer "gestionnaire_id", null: false
    t.integer "dossier_id", null: false
    t.datetime "demande_seen_at"
    t.datetime "annotations_privees_seen_at"
    t.datetime "avis_seen_at"
    t.datetime "messagerie_seen_at"
    t.index ["dossier_id"], name: "index_follows_on_dossier_id"
    t.index ["gestionnaire_id", "dossier_id"], name: "index_follows_on_gestionnaire_id_and_dossier_id", unique: true
    t.index ["gestionnaire_id"], name: "index_follows_on_gestionnaire_id"
  end

  create_table "france_connect_informations", id: :serial, force: :cascade do |t|
    t.string "gender"
    t.string "given_name"
    t.string "family_name"
    t.date "birthdate"
    t.string "birthplace"
    t.string "france_connect_particulier_id"
    t.integer "user_id"
    t.string "email_france_connect"
    t.index ["user_id"], name: "index_france_connect_informations_on_user_id"
  end

  create_table "gestionnaires", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "procedure_filter"
    t.index ["email"], name: "index_gestionnaires_on_email", unique: true
    t.index ["reset_password_token"], name: "index_gestionnaires_on_reset_password_token", unique: true
  end

  create_table "individuals", id: :serial, force: :cascade do |t|
    t.string "nom"
    t.string "prenom"
    t.string "birthdate"
    t.integer "dossier_id"
    t.string "gender"
    t.index ["dossier_id"], name: "index_individuals_on_dossier_id"
  end

  create_table "initiated_mails", id: :serial, force: :cascade do |t|
    t.string "subject"
    t.text "body"
    t.integer "procedure_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_initiated_mails_on_procedure_id"
  end

  create_table "invites", id: :serial, force: :cascade do |t|
    t.string "email"
    t.string "email_sender"
    t.integer "dossier_id"
    t.integer "user_id"
    t.string "type", default: "InviteGestionnaire"
  end

  create_table "module_api_cartos", id: :serial, force: :cascade do |t|
    t.integer "procedure_id"
    t.boolean "use_api_carto", default: false
    t.boolean "quartiers_prioritaires", default: false
    t.boolean "cadastre", default: false
    t.index ["procedure_id"], name: "index_module_api_cartos_on_procedure_id", unique: true
  end

  create_table "pieces_justificatives", id: :serial, force: :cascade do |t|
    t.string "content"
    t.integer "dossier_id"
    t.integer "type_de_piece_justificative_id"
    t.datetime "created_at"
    t.integer "user_id"
    t.string "original_filename"
    t.string "content_secure_token"
    t.datetime "updated_at"
    t.index ["dossier_id"], name: "index_pieces_justificatives_on_dossier_id"
    t.index ["type_de_piece_justificative_id"], name: "index_pieces_justificatives_on_type_de_piece_justificative_id"
  end

  create_table "procedure_paths", id: :serial, force: :cascade do |t|
    t.string "path"
    t.integer "procedure_id"
    t.integer "administrateur_id"
    t.index ["path"], name: "index_procedure_paths_on_path"
  end

  create_table "procedure_presentations", id: :serial, force: :cascade do |t|
    t.integer "assign_to_id"
    t.text "displayed_fields", default: ["{\"label\":\"Demandeur\",\"table\":\"user\",\"column\":\"email\"}"], null: false, array: true
    t.json "sort", default: "{\"table\":\"notifications\",\"column\":\"notifications\",\"order\":\"desc\"}", null: false
    t.json "filters", default: "{\"a-suivre\":[],\"suivis\":[],\"traites\":[],\"tous\":[],\"archives\":[]}", null: false
    t.index ["assign_to_id"], name: "index_procedure_presentations_on_assign_to_id", unique: true
  end

  create_table "procedures", id: :serial, force: :cascade do |t|
    t.string "libelle"
    t.string "description"
    t.string "organisation", null: false
    t.string "direction"
    t.string "lien_demarche"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "administrateur_id"
    t.boolean "euro_flag", default: false
    t.string "logo"
    t.boolean "cerfa_flag", default: false
    t.string "logo_secure_token"
    t.string "lien_site_web"
    t.string "lien_notice"
    t.boolean "for_individual", default: false
    t.boolean "individual_with_siret", default: false
    t.date "auto_archive_on"
    t.datetime "published_at"
    t.datetime "hidden_at"
    t.datetime "archived_at"
    t.datetime "whitelisted_at"
    t.boolean "ask_birthday", default: false, null: false
    t.index ["hidden_at"], name: "index_procedures_on_hidden_at"
  end

  create_table "quartier_prioritaires", id: :serial, force: :cascade do |t|
    t.string "code"
    t.string "nom"
    t.string "commune"
    t.text "geometry"
    t.integer "dossier_id"
  end

  create_table "received_mails", id: :serial, force: :cascade do |t|
    t.text "body"
    t.string "subject"
    t.integer "procedure_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_received_mails_on_procedure_id"
  end

  create_table "refused_mails", id: :serial, force: :cascade do |t|
    t.text "body"
    t.string "subject"
    t.integer "procedure_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_refused_mails_on_procedure_id"
  end

  create_table "rna_informations", id: :serial, force: :cascade do |t|
    t.string "association_id"
    t.string "titre"
    t.text "objet"
    t.date "date_creation"
    t.date "date_declaration"
    t.date "date_publication"
    t.integer "entreprise_id"
    t.index ["entreprise_id"], name: "index_rna_informations_on_entreprise_id"
  end

  create_table "types_de_champ", id: :serial, force: :cascade do |t|
    t.string "libelle"
    t.string "type_champ"
    t.integer "order_place"
    t.integer "procedure_id"
    t.text "description"
    t.boolean "mandatory", default: false
    t.string "type"
  end

  create_table "types_de_piece_justificative", id: :serial, force: :cascade do |t|
    t.string "libelle"
    t.string "description"
    t.boolean "api_entreprise", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "procedure_id"
    t.integer "order_place"
    t.string "lien_demarche"
    t.boolean "mandatory", default: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "siret"
    t.string "loged_in_with_france_connect", default: "false"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "without_continuation_mails", id: :serial, force: :cascade do |t|
    t.text "body"
    t.string "subject"
    t.integer "procedure_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_without_continuation_mails_on_procedure_id"
  end

  add_foreign_key "attestation_templates", "procedures"
  add_foreign_key "attestations", "dossiers"
  add_foreign_key "avis", "gestionnaires", column: "claimant_id"
  add_foreign_key "cerfas", "dossiers"
  add_foreign_key "closed_mails", "procedures"
  add_foreign_key "commentaires", "dossiers"
  add_foreign_key "dossiers", "users"
  add_foreign_key "initiated_mails", "procedures"
  add_foreign_key "procedure_paths", "administrateurs"
  add_foreign_key "procedure_paths", "procedures"
  add_foreign_key "procedure_presentations", "assign_tos"
  add_foreign_key "received_mails", "procedures"
  add_foreign_key "refused_mails", "procedures"
  add_foreign_key "without_continuation_mails", "procedures"

  create_view "searches",  sql_definition: <<-SQL
      SELECT dossiers.id AS dossier_id,
      (((((((((((((((((((((((((((((((((((((((((((((((((((((((COALESCE(users.email, ''::character varying))::text || ' '::text) || (COALESCE(france_connect_informations.given_name, ''::character varying))::text) || ' '::text) || (COALESCE(france_connect_informations.family_name, ''::character varying))::text) || ' '::text) || (COALESCE(cerfas.content, ''::character varying))::text) || ' '::text) || (COALESCE(champs.value, ''::character varying))::text) || ' '::text) || (COALESCE(drop_down_lists.value, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.siren, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.numero_tva_intracommunautaire, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.forme_juridique, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.forme_juridique_code, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.nom_commercial, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.raison_sociale, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.siret_siege_social, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.nom, ''::character varying))::text) || ' '::text) || (COALESCE(entreprises.prenom, ''::character varying))::text) || ' '::text) || (COALESCE(rna_informations.association_id, ''::character varying))::text) || ' '::text) || (COALESCE(rna_informations.titre, ''::character varying))::text) || ' '::text) || COALESCE(rna_informations.objet, ''::text)) || ' '::text) || (COALESCE(etablissements.siret, ''::character varying))::text) || ' '::text) || (COALESCE(etablissements.naf, ''::character varying))::text) || ' '::text) || (COALESCE(etablissements.libelle_naf, ''::character varying))::text) || ' '::text) || (COALESCE(etablissements.adresse, ''::character varying))::text) || ' '::text) || (COALESCE(etablissements.code_postal, ''::character varying))::text) || ' '::text) || (COALESCE(etablissements.localite, ''::character varying))::text) || ' '::text) || (COALESCE(etablissements.code_insee_localite, ''::character varying))::text) || ' '::text) || (COALESCE(individuals.nom, ''::character varying))::text) || ' '::text) || (COALESCE(individuals.prenom, ''::character varying))::text) || ' '::text) || (COALESCE(pieces_justificatives.content, ''::character varying))::text) AS term
     FROM ((((((((((dossiers
       JOIN users ON ((users.id = dossiers.user_id)))
       LEFT JOIN france_connect_informations ON ((france_connect_informations.user_id = dossiers.user_id)))
       LEFT JOIN cerfas ON ((cerfas.dossier_id = dossiers.id)))
       LEFT JOIN champs ON ((champs.dossier_id = dossiers.id)))
       LEFT JOIN drop_down_lists ON ((drop_down_lists.type_de_champ_id = champs.type_de_champ_id)))
       LEFT JOIN entreprises ON ((entreprises.dossier_id = dossiers.id)))
       LEFT JOIN rna_informations ON ((rna_informations.entreprise_id = entreprises.id)))
       LEFT JOIN etablissements ON ((etablissements.dossier_id = dossiers.id)))
       LEFT JOIN individuals ON ((individuals.dossier_id = dossiers.id)))
       LEFT JOIN pieces_justificatives ON ((pieces_justificatives.dossier_id = dossiers.id)));
  SQL

end
