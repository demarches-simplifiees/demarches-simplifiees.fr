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

ActiveRecord::Schema.define(version: 2019_08_28_073736) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

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
    t.boolean "active", default: false
    t.jsonb "features", default: {}, null: false
    t.string "encrypted_token"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.index ["email"], name: "index_administrateurs_on_email", unique: true
    t.index ["reset_password_token"], name: "index_administrateurs_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_administrateurs_on_unlock_token", unique: true
  end

  create_table "administrateurs_instructeurs", id: false, force: :cascade do |t|
    t.integer "administrateur_id"
    t.integer "instructeur_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["administrateur_id"], name: "index_administrateurs_instructeurs_on_administrateur_id"
    t.index ["instructeur_id", "administrateur_id"], name: "unique_couple_administrateur_instructeur", unique: true
    t.index ["instructeur_id"], name: "index_administrateurs_instructeurs_on_instructeur_id"
  end

  create_table "administrateurs_procedures", id: false, force: :cascade do |t|
    t.bigint "administrateur_id", null: false
    t.bigint "procedure_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["administrateur_id", "procedure_id"], name: "index_unique_admin_proc_couple", unique: true
    t.index ["administrateur_id"], name: "index_administrateurs_procedures_on_administrateur_id"
    t.index ["procedure_id"], name: "index_administrateurs_procedures_on_procedure_id"
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
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.index ["email"], name: "index_administrations_on_email", unique: true
    t.index ["reset_password_token"], name: "index_administrations_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_administrations_on_unlock_token", unique: true
  end

  create_table "assign_tos", id: :serial, force: :cascade do |t|
    t.integer "instructeur_id"
    t.integer "procedure_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "email_notifications_enabled", default: false, null: false
    t.bigint "groupe_instructeur_id"
    t.index ["groupe_instructeur_id", "instructeur_id"], name: "unique_couple_groupe_instructeur_instructeur", unique: true
    t.index ["groupe_instructeur_id"], name: "index_assign_tos_on_groupe_instructeur_id"
    t.index ["instructeur_id", "procedure_id"], name: "index_assign_tos_on_instructeur_id_and_procedure_id", unique: true
    t.index ["instructeur_id"], name: "index_assign_tos_on_instructeur_id"
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
    t.integer "instructeur_id"
    t.integer "dossier_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "claimant_id", null: false
    t.boolean "confidentiel", default: false, null: false
    t.index ["claimant_id"], name: "index_avis_on_claimant_id"
    t.index ["dossier_id"], name: "index_avis_on_dossier_id"
    t.index ["instructeur_id"], name: "index_avis_on_instructeur_id"
  end

  create_table "bill_signatures", force: :cascade do |t|
    t.string "digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "champs", id: :serial, force: :cascade do |t|
    t.string "value"
    t.integer "type_de_champ_id"
    t.integer "dossier_id"
    t.string "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "private", default: false, null: false
    t.integer "etablissement_id"
    t.bigint "parent_id"
    t.integer "row"
    t.index ["dossier_id"], name: "index_champs_on_dossier_id"
    t.index ["parent_id"], name: "index_champs_on_parent_id"
    t.index ["private"], name: "index_champs_on_private"
    t.index ["row"], name: "index_champs_on_row"
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
    t.string "file"
    t.bigint "user_id"
    t.bigint "instructeur_id"
    t.index ["dossier_id"], name: "index_commentaires_on_dossier_id"
    t.index ["instructeur_id"], name: "index_commentaires_on_instructeur_id"
    t.index ["user_id"], name: "index_commentaires_on_user_id"
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

  create_table "deleted_dossiers", force: :cascade do |t|
    t.bigint "procedure_id"
    t.bigint "dossier_id"
    t.datetime "deleted_at"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_deleted_dossiers_on_procedure_id"
  end

  create_table "dossier_operation_logs", force: :cascade do |t|
    t.string "operation", null: false
    t.bigint "dossier_id"
    t.bigint "instructeur_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "automatic_operation", default: false, null: false
    t.bigint "administration_id"
    t.datetime "keep_until"
    t.datetime "executed_at"
    t.text "digest"
    t.bigint "bill_signature_id"
    t.index ["administration_id"], name: "index_dossier_operation_logs_on_administration_id"
    t.index ["bill_signature_id"], name: "index_dossier_operation_logs_on_bill_signature_id"
    t.index ["dossier_id"], name: "index_dossier_operation_logs_on_dossier_id"
    t.index ["instructeur_id"], name: "index_dossier_operation_logs_on_instructeur_id"
    t.index ["keep_until"], name: "index_dossier_operation_logs_on_keep_until"
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
    t.datetime "en_construction_at"
    t.datetime "en_instruction_at"
    t.datetime "processed_at"
    t.text "motivation"
    t.datetime "hidden_at"
    t.text "search_terms"
    t.text "private_search_terms"
    t.bigint "groupe_instructeur_id"
    t.index "to_tsvector('french'::regconfig, (search_terms || private_search_terms))", name: "index_dossiers_on_search_terms_private_search_terms", using: :gin
    t.index "to_tsvector('french'::regconfig, search_terms)", name: "index_dossiers_on_search_terms", using: :gin
    t.index ["groupe_instructeur_id"], name: "index_dossiers_on_groupe_instructeur_id"
    t.index ["hidden_at"], name: "index_dossiers_on_hidden_at"
    t.index ["procedure_id"], name: "index_dossiers_on_procedure_id"
    t.index ["user_id"], name: "index_dossiers_on_user_id"
  end

  create_table "drop_down_lists", id: :serial, force: :cascade do |t|
    t.string "value"
    t.integer "type_de_champ_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["type_de_champ_id"], name: "index_drop_down_lists_on_type_de_champ_id"
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
    t.string "entreprise_siren"
    t.bigint "entreprise_capital_social"
    t.string "entreprise_numero_tva_intracommunautaire"
    t.string "entreprise_forme_juridique"
    t.string "entreprise_forme_juridique_code"
    t.string "entreprise_nom_commercial"
    t.string "entreprise_raison_sociale"
    t.string "entreprise_siret_siege_social"
    t.string "entreprise_code_effectif_entreprise"
    t.date "entreprise_date_creation"
    t.string "entreprise_nom"
    t.string "entreprise_prenom"
    t.string "association_rna"
    t.string "association_titre"
    t.text "association_objet"
    t.date "association_date_creation"
    t.date "association_date_declaration"
    t.date "association_date_publication"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["dossier_id"], name: "index_etablissements_on_dossier_id"
  end

  create_table "exercices", id: :serial, force: :cascade do |t|
    t.string "ca"
    t.datetime "dateFinExercice"
    t.integer "date_fin_exercice_timestamp"
    t.integer "etablissement_id"
    t.datetime "date_fin_exercice"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rating", null: false
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "flipflop_features", force: :cascade do |t|
    t.string "key", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "follows", id: :serial, force: :cascade do |t|
    t.integer "instructeur_id", null: false
    t.integer "dossier_id", null: false
    t.datetime "demande_seen_at", null: false
    t.datetime "annotations_privees_seen_at", null: false
    t.datetime "avis_seen_at", null: false
    t.datetime "messagerie_seen_at", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "unfollowed_at"
    t.index ["dossier_id"], name: "index_follows_on_dossier_id"
    t.index ["instructeur_id", "dossier_id", "unfollowed_at"], name: "uniqueness_index", unique: true
    t.index ["instructeur_id"], name: "index_follows_on_instructeur_id"
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_france_connect_informations_on_user_id"
  end

  create_table "geo_areas", force: :cascade do |t|
    t.string "source"
    t.jsonb "geometry"
    t.jsonb "properties"
    t.bigint "champ_id"
    t.string "geo_reference_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["champ_id"], name: "index_geo_areas_on_champ_id"
    t.index ["source"], name: "index_geo_areas_on_source"
  end

  create_table "groupe_instructeurs", force: :cascade do |t|
    t.bigint "procedure_id", null: false
    t.text "label", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["procedure_id", "label"], name: "index_groupe_instructeurs_on_procedure_id_and_label", unique: true
    t.index ["procedure_id"], name: "index_groupe_instructeurs_on_procedure_id"
  end

  create_table "individuals", id: :serial, force: :cascade do |t|
    t.string "nom"
    t.string "prenom"
    t.integer "dossier_id"
    t.string "gender"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "birthdate"
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

  create_table "instructeurs", id: :serial, force: :cascade do |t|
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
    t.text "encrypted_login_token"
    t.datetime "login_token_created_at"
    t.jsonb "features", default: {"enable_email_login_token"=>true}, null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.index ["email"], name: "index_instructeurs_on_email", unique: true
    t.index ["reset_password_token"], name: "index_instructeurs_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_instructeurs_on_unlock_token", unique: true
  end

  create_table "invites", id: :serial, force: :cascade do |t|
    t.string "email"
    t.string "email_sender"
    t.integer "dossier_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "message"
  end

  create_table "module_api_cartos", id: :serial, force: :cascade do |t|
    t.integer "procedure_id"
    t.boolean "use_api_carto", default: false
    t.boolean "quartiers_prioritaires", default: false
    t.boolean "cadastre", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "migrated"
    t.index ["procedure_id"], name: "index_module_api_cartos_on_procedure_id", unique: true
  end

  create_table "procedure_presentations", id: :serial, force: :cascade do |t|
    t.integer "assign_to_id"
    t.jsonb "sort", default: {"order"=>"desc", "table"=>"notifications", "column"=>"notifications"}, null: false
    t.jsonb "filters", default: {"tous"=>[], "suivis"=>[], "traites"=>[], "a-suivre"=>[], "archives"=>[]}, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.jsonb "displayed_fields", default: [{"label"=>"Demandeur", "table"=>"user", "column"=>"email"}], null: false
    t.index ["assign_to_id"], name: "index_procedure_presentations_on_assign_to_id", unique: true
  end

  create_table "procedures", id: :serial, force: :cascade do |t|
    t.string "libelle"
    t.string "description"
    t.string "organisation"
    t.string "direction"
    t.string "lien_demarche"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "euro_flag", default: false
    t.string "logo"
    t.boolean "cerfa_flag", default: false
    t.string "logo_secure_token"
    t.string "lien_site_web"
    t.string "lien_notice"
    t.boolean "for_individual", default: false
    t.date "auto_archive_on"
    t.datetime "published_at"
    t.datetime "hidden_at"
    t.datetime "archived_at"
    t.datetime "whitelisted_at"
    t.boolean "ask_birthday", default: false, null: false
    t.string "web_hook_url"
    t.boolean "cloned_from_library", default: false
    t.bigint "parent_procedure_id"
    t.datetime "test_started_at"
    t.string "aasm_state", default: "brouillon"
    t.bigint "service_id"
    t.integer "duree_conservation_dossiers_dans_ds"
    t.integer "duree_conservation_dossiers_hors_ds"
    t.string "cadre_juridique"
    t.boolean "juridique_required", default: true
    t.boolean "durees_conservation_required", default: true
    t.string "path"
    t.string "declarative_with_state"
    t.text "monavis"
    t.text "monavis_embed"
    t.index ["declarative_with_state"], name: "index_procedures_on_declarative_with_state"
    t.index ["hidden_at"], name: "index_procedures_on_hidden_at"
    t.index ["parent_procedure_id"], name: "index_procedures_on_parent_procedure_id"
    t.index ["service_id"], name: "index_procedures_on_service_id"
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

  create_table "services", force: :cascade do |t|
    t.string "type_organisme", null: false
    t.string "nom", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "administrateur_id"
    t.string "organisme"
    t.string "email"
    t.string "telephone"
    t.text "horaires"
    t.text "adresse"
    t.string "siret"
    t.index ["administrateur_id", "nom"], name: "index_services_on_administrateur_id_and_nom", unique: true
    t.index ["administrateur_id"], name: "index_services_on_administrateur_id"
  end

  create_table "task_records", id: false, force: :cascade do |t|
    t.string "version", null: false
  end

  create_table "trusted_device_tokens", force: :cascade do |t|
    t.string "token", null: false
    t.bigint "instructeur_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["instructeur_id"], name: "index_trusted_device_tokens_on_instructeur_id"
    t.index ["token"], name: "index_trusted_device_tokens_on_token", unique: true
  end

  create_table "types_de_champ", id: :serial, force: :cascade do |t|
    t.string "libelle"
    t.string "type_champ"
    t.integer "order_place"
    t.integer "procedure_id"
    t.text "description"
    t.boolean "mandatory", default: false
    t.boolean "private", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.jsonb "options"
    t.bigint "stable_id"
    t.bigint "parent_id"
    t.index ["parent_id"], name: "index_types_de_champ_on_parent_id"
    t.index ["private"], name: "index_types_de_champ_on_private"
    t.index ["procedure_id"], name: "index_types_de_champ_on_procedure_id"
    t.index ["stable_id"], name: "index_types_de_champ_on_stable_id"
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
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.text "unconfirmed_email"
    t.bigint "instructeur_id"
    t.bigint "administrateur_id"
    t.index ["administrateur_id"], name: "index_users_on_administrateur_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["instructeur_id"], name: "index_users_on_instructeur_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "virus_scans", force: :cascade do |t|
    t.datetime "scanned_at"
    t.string "status"
    t.bigint "champ_id"
    t.string "blob_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["champ_id"], name: "index_virus_scans_on_champ_id"
  end

  create_table "without_continuation_mails", id: :serial, force: :cascade do |t|
    t.text "body"
    t.string "subject"
    t.integer "procedure_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_without_continuation_mails_on_procedure_id"
  end

  add_foreign_key "assign_tos", "groupe_instructeurs"
  add_foreign_key "attestation_templates", "procedures"
  add_foreign_key "attestations", "dossiers"
  add_foreign_key "avis", "instructeurs", column: "claimant_id"
  add_foreign_key "champs", "champs", column: "parent_id"
  add_foreign_key "closed_mails", "procedures"
  add_foreign_key "commentaires", "dossiers"
  add_foreign_key "dossier_operation_logs", "administrations"
  add_foreign_key "dossier_operation_logs", "bill_signatures"
  add_foreign_key "dossier_operation_logs", "dossiers"
  add_foreign_key "dossier_operation_logs", "instructeurs"
  add_foreign_key "dossiers", "groupe_instructeurs"
  add_foreign_key "dossiers", "users"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "geo_areas", "champs"
  add_foreign_key "groupe_instructeurs", "procedures"
  add_foreign_key "initiated_mails", "procedures"
  add_foreign_key "procedure_presentations", "assign_tos"
  add_foreign_key "procedures", "services"
  add_foreign_key "received_mails", "procedures"
  add_foreign_key "refused_mails", "procedures"
  add_foreign_key "services", "administrateurs"
  add_foreign_key "trusted_device_tokens", "instructeurs"
  add_foreign_key "types_de_champ", "types_de_champ", column: "parent_id"
  add_foreign_key "users", "administrateurs"
  add_foreign_key "users", "instructeurs"
  add_foreign_key "without_continuation_mails", "procedures"
end
