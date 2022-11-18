# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_11_30_113745) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.integer "lock_version"
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "administrateurs", id: :serial, force: :cascade do |t|
    t.boolean "active", default: false
    t.datetime "created_at"
    t.string "encrypted_token"
    t.datetime "updated_at"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_administrateurs_on_user_id"
  end

  create_table "administrateurs_instructeurs", id: false, force: :cascade do |t|
    t.integer "administrateur_id", null: false
    t.datetime "created_at"
    t.integer "instructeur_id", null: false
    t.datetime "updated_at"
    t.index ["administrateur_id"], name: "index_administrateurs_instructeurs_on_administrateur_id"
    t.index ["instructeur_id", "administrateur_id"], name: "unique_couple_administrateur_instructeur", unique: true
    t.index ["instructeur_id"], name: "index_administrateurs_instructeurs_on_instructeur_id"
  end

  create_table "administrateurs_procedures", id: false, force: :cascade do |t|
    t.bigint "administrateur_id", null: false
    t.datetime "created_at", null: false
    t.boolean "manager"
    t.bigint "procedure_id", null: false
    t.datetime "updated_at", null: false
    t.index ["administrateur_id", "procedure_id"], name: "index_unique_admin_proc_couple", unique: true
    t.index ["administrateur_id"], name: "index_administrateurs_procedures_on_administrateur_id"
    t.index ["procedure_id"], name: "index_administrateurs_procedures_on_procedure_id"
  end

  create_table "archives", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.string "job_status", null: false
    t.text "key", null: false
    t.date "month"
    t.string "time_span_type", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["key", "time_span_type", "month"], name: "index_archives_on_key_and_time_span_type_and_month", unique: true
  end

  create_table "archives_groupe_instructeurs", force: :cascade do |t|
    t.bigint "archive_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.bigint "groupe_instructeur_id", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["archive_id"], name: "index_archives_groupe_instructeurs_on_archive_id"
    t.index ["groupe_instructeur_id"], name: "index_archives_groupe_instructeurs_on_groupe_instructeur_id"
  end

  create_table "assign_tos", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.boolean "daily_email_notifications_enabled", default: false, null: false
    t.bigint "groupe_instructeur_id"
    t.boolean "instant_email_dossier_notifications_enabled", default: false, null: false
    t.boolean "instant_email_message_notifications_enabled", default: false, null: false
    t.boolean "instant_expert_avis_email_notifications_enabled", default: false
    t.integer "instructeur_id"
    t.boolean "manager", default: false
    t.datetime "updated_at"
    t.boolean "weekly_email_notifications_enabled", default: true, null: false
    t.index ["groupe_instructeur_id", "instructeur_id"], name: "unique_couple_groupe_instructeur_instructeur", unique: true
    t.index ["groupe_instructeur_id"], name: "index_assign_tos_on_groupe_instructeur_id"
    t.index ["instructeur_id"], name: "index_assign_tos_on_instructeur_id"
    t.check_constraint "instant_expert_avis_email_notifications_enabled IS NOT NULL", name: "assign_tos_instant_expert_avis_email_notifications_enabled_null"
  end

  create_table "attestation_templates", id: :serial, force: :cascade do |t|
    t.boolean "activated"
    t.text "body"
    t.datetime "created_at", null: false
    t.text "footer"
    t.integer "procedure_id"
    t.text "title"
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_attestation_templates_on_procedure_id", unique: true
  end

  create_table "attestations", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "dossier_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["dossier_id"], name: "index_attestations_on_dossier_id", unique: true
  end

  create_table "avis", id: :serial, force: :cascade do |t|
    t.text "answer"
    t.integer "claimant_id", null: false
    t.string "claimant_type"
    t.boolean "confidentiel", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "dossier_id"
    t.string "email"
    t.bigint "experts_procedure_id"
    t.text "introduction"
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.index ["claimant_id"], name: "index_avis_on_claimant_id"
    t.index ["dossier_id"], name: "index_avis_on_dossier_id"
    t.index ["experts_procedure_id"], name: "index_avis_on_experts_procedure_id"
  end

  create_table "batch_operations", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.bigint "failed_dossier_ids", default: [], null: false, array: true
    t.datetime "finished_at"
    t.bigint "instructeur_id", null: false
    t.string "operation", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "run_at"
    t.bigint "success_dossier_ids", default: [], null: false, array: true
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "bill_signatures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "digest"
    t.datetime "updated_at", null: false
  end

  create_table "bulk_messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", precision: 6, null: false
    t.integer "dossier_count"
    t.string "dossier_state"
    t.bigint "instructeur_id", null: false
    t.datetime "sent_at", null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "bulk_messages_groupe_instructeurs", id: false, force: :cascade do |t|
    t.bigint "bulk_message_id"
    t.bigint "groupe_instructeur_id"
    t.index ["bulk_message_id", "groupe_instructeur_id"], name: "index_bulk_msg_gi_on_bulk_msg_id_and_gi_id", unique: true
    t.index ["bulk_message_id"], name: "index_bulk_messages_groupe_instructeurs_on_bulk_message_id"
    t.index ["groupe_instructeur_id"], name: "index_bulk_messages_groupe_instructeurs_on_gi_id"
  end

  create_table "champs", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.jsonb "data"
    t.integer "dossier_id", null: false
    t.integer "etablissement_id"
    t.string "external_id"
    t.string "fetch_external_data_exceptions", array: true
    t.bigint "parent_id"
    t.boolean "private", default: false, null: false
    t.datetime "rebased_at"
    t.integer "row"
    t.string "type"
    t.integer "type_de_champ_id", null: false
    t.datetime "updated_at"
    t.string "value"
    t.jsonb "value_json"
    t.index ["dossier_id"], name: "index_champs_on_dossier_id"
    t.index ["etablissement_id"], name: "index_champs_on_etablissement_id"
    t.index ["parent_id"], name: "index_champs_on_parent_id"
    t.index ["private"], name: "index_champs_on_private"
    t.index ["row"], name: "index_champs_on_row"
    t.index ["type"], name: "index_champs_on_type"
    t.index ["type_de_champ_id", "dossier_id", "row"], name: "index_champs_on_type_de_champ_id_and_dossier_id_and_row", unique: true
    t.index ["type_de_champ_id"], name: "index_champs_on_type_de_champ_id"
  end

  create_table "closed_mails", id: :serial, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "procedure_id"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_closed_mails_on_procedure_id"
  end

  create_table "commentaires", id: :serial, force: :cascade do |t|
    t.string "body"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.integer "dossier_id"
    t.string "email"
    t.bigint "expert_id"
    t.bigint "instructeur_id"
    t.datetime "updated_at", null: false
    t.index ["dossier_id"], name: "index_commentaires_on_dossier_id"
    t.index ["expert_id"], name: "index_commentaires_on_expert_id"
    t.index ["instructeur_id"], name: "index_commentaires_on_instructeur_id"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at"
    t.string "cron"
    t.datetime "failed_at"
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "locked_at"
    t.string "locked_by"
    t.integer "priority", default: 0, null: false
    t.string "queue"
    t.datetime "run_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "deleted_dossiers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.bigint "dossier_id"
    t.bigint "groupe_instructeur_id"
    t.bigint "procedure_id"
    t.string "reason"
    t.bigint "revision_id"
    t.string "state"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["deleted_at"], name: "index_deleted_dossiers_on_deleted_at"
    t.index ["dossier_id"], name: "index_deleted_dossiers_on_dossier_id", unique: true
    t.index ["procedure_id"], name: "index_deleted_dossiers_on_procedure_id"
  end

  create_table "dossier_operation_logs", force: :cascade do |t|
    t.boolean "automatic_operation", default: false, null: false
    t.bigint "bill_signature_id"
    t.datetime "created_at", null: false
    t.text "digest"
    t.bigint "dossier_id"
    t.datetime "executed_at"
    t.datetime "keep_until"
    t.string "operation", null: false
    t.datetime "updated_at", null: false
    t.jsonb "data"
    t.index ["bill_signature_id"], name: "index_dossier_operation_logs_on_bill_signature_id"
    t.index ["dossier_id"], name: "index_dossier_operation_logs_on_dossier_id"
    t.index ["keep_until"], name: "index_dossier_operation_logs_on_keep_until"
  end

  create_table "dossier_submitted_messages", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.string "message_on_submit_by_usager"
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "dossier_transfer_logs", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.bigint "dossier_id", null: false
    t.string "from", null: false
    t.string "to", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["dossier_id"], name: "index_dossier_transfer_logs_on_dossier_id"
  end

  create_table "dossier_transfers", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.string "email", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_dossier_transfers_on_email"
  end

  create_table "dossiers", id: :serial, force: :cascade do |t|
    t.string "api_entreprise_job_exceptions", array: true
    t.boolean "archived", default: false
    t.datetime "archived_at"
    t.string "archived_by"
    t.boolean "autorisation_donnees"
    t.bigint "batch_operation_id"
    t.datetime "brouillon_close_to_expiration_notice_sent_at"
    t.interval "conservation_extension", default: "PT0S"
    t.datetime "created_at"
    t.datetime "declarative_triggered_at"
    t.string "deleted_user_email_never_send"
    t.datetime "depose_at"
    t.bigint "dossier_transfer_id"
    t.datetime "en_construction_at"
    t.datetime "en_construction_close_to_expiration_notice_sent_at"
    t.datetime "en_instruction_at"
    t.boolean "for_procedure_preview", default: false
    t.bigint "groupe_instructeur_id"
    t.datetime "groupe_instructeur_updated_at"
    t.datetime "hidden_at"
    t.datetime "hidden_by_administration_at"
    t.string "hidden_by_reason"
    t.datetime "hidden_by_user_at"
    t.datetime "identity_updated_at"
    t.datetime "last_avis_updated_at"
    t.datetime "last_champ_private_updated_at"
    t.datetime "last_champ_updated_at"
    t.datetime "last_commentaire_updated_at"
    t.text "motivation"
    t.bigint "parent_dossier_id"
    t.string "private_search_terms"
    t.datetime "processed_at"
    t.bigint "revision_id"
    t.text "search_terms"
    t.string "state"
    t.datetime "termine_close_to_expiration_notice_sent_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["archived"], name: "index_dossiers_on_archived"
    t.index ["batch_operation_id"], name: "index_dossiers_on_batch_operation_id"
    t.index ["dossier_transfer_id"], name: "index_dossiers_on_dossier_transfer_id"
    t.index ["groupe_instructeur_id"], name: "index_dossiers_on_groupe_instructeur_id"
    t.index ["hidden_at"], name: "index_dossiers_on_hidden_at"
    t.index ["revision_id"], name: "index_dossiers_on_revision_id"
    t.index ["state"], name: "index_dossiers_on_state"
    t.index ["user_id"], name: "index_dossiers_on_user_id"
  end

  create_table "drop_down_lists", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.integer "type_de_champ_id"
    t.datetime "updated_at"
    t.string "value"
    t.index ["type_de_champ_id"], name: "index_drop_down_lists_on_type_de_champ_id"
  end

  create_table "etablissements", id: :serial, force: :cascade do |t|
    t.string "adresse"
    t.date "association_date_creation"
    t.date "association_date_declaration"
    t.date "association_date_publication"
    t.text "association_objet"
    t.string "association_rna"
    t.string "association_titre"
    t.string "code_insee_localite"
    t.string "code_postal"
    t.string "complement_adresse"
    t.datetime "created_at"
    t.boolean "diffusable_commercialement"
    t.integer "dossier_id"
    t.string "enseigne"
    t.jsonb "entreprise_bilans_bdf"
    t.string "entreprise_bilans_bdf_monnaie"
    t.bigint "entreprise_capital_social"
    t.string "entreprise_code_effectif_entreprise"
    t.date "entreprise_date_creation"
    t.string "entreprise_effectif_annee"
    t.decimal "entreprise_effectif_annuel"
    t.string "entreprise_effectif_annuel_annee"
    t.decimal "entreprise_effectif_mensuel"
    t.string "entreprise_effectif_mois"
    t.string "entreprise_etat_administratif"
    t.string "entreprise_forme_juridique"
    t.string "entreprise_forme_juridique_code"
    t.string "entreprise_nom"
    t.string "entreprise_nom_commercial"
    t.string "entreprise_numero_tva_intracommunautaire"
    t.string "entreprise_prenom"
    t.string "entreprise_raison_sociale"
    t.string "entreprise_siren"
    t.string "entreprise_siret_siege_social"
    t.string "libelle_naf"
    t.string "localite"
    t.string "naf"
    t.string "nom_voie"
    t.string "numero_voie"
    t.boolean "siege_social"
    t.string "siret"
    t.string "type_voie"
    t.datetime "updated_at"
    t.index ["dossier_id"], name: "index_etablissements_on_dossier_id", unique: true
  end

  create_table "exercices", id: :serial, force: :cascade do |t|
    t.string "ca"
    t.datetime "created_at"
    t.datetime "dateFinExercice"
    t.datetime "date_fin_exercice"
    t.integer "date_fin_exercice_timestamp"
    t.integer "etablissement_id"
    t.datetime "updated_at"
    t.index ["etablissement_id"], name: "index_exercices_on_etablissement_id"
  end

  create_table "experts", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_experts_on_user_id"
  end

  create_table "experts_procedures", force: :cascade do |t|
    t.boolean "allow_decision_access", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.bigint "expert_id", null: false
    t.bigint "procedure_id", null: false
    t.datetime "revoked_at"
    t.datetime "updated_at", precision: 6, null: false
    t.index ["expert_id", "procedure_id"], name: "index_experts_procedures_on_expert_id_and_procedure_id", unique: true
    t.index ["expert_id"], name: "index_experts_procedures_on_expert_id"
    t.index ["procedure_id"], name: "index_experts_procedures_on_procedure_id"
  end

  create_table "exports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "format", null: false
    t.string "job_status", default: "pending", null: false
    t.text "key", null: false
    t.bigint "procedure_presentation_id"
    t.jsonb "procedure_presentation_snapshot"
    t.string "statut", default: "tous"
    t.string "time_span_type", default: "everything", null: false
    t.datetime "updated_at", null: false
    t.index ["format", "time_span_type", "statut", "key"], name: "index_exports_on_format_and_time_span_type_and_statut_and_key", unique: true
    t.index ["procedure_presentation_id"], name: "index_exports_on_procedure_presentation_id"
  end

  create_table "exports_groupe_instructeurs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "export_id", null: false
    t.bigint "groupe_instructeur_id", null: false
    t.datetime "updated_at", null: false
  end

  create_table "flipper_features", id: false, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigserial "id", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "follows", id: :serial, force: :cascade do |t|
    t.datetime "annotations_privees_seen_at", null: false
    t.datetime "avis_seen_at", null: false
    t.datetime "created_at"
    t.datetime "demande_seen_at", null: false
    t.integer "dossier_id", null: false
    t.integer "instructeur_id", null: false
    t.datetime "messagerie_seen_at", null: false
    t.datetime "unfollowed_at"
    t.datetime "updated_at"
    t.index ["dossier_id"], name: "index_follows_on_dossier_id"
    t.index ["instructeur_id", "dossier_id", "unfollowed_at"], name: "uniqueness_index", unique: true
    t.index ["instructeur_id"], name: "index_follows_on_instructeur_id"
    t.index ["unfollowed_at"], name: "index_follows_on_unfollowed_at"
  end

  create_table "france_connect_informations", id: :serial, force: :cascade do |t|
    t.date "birthdate"
    t.string "birthplace"
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.string "email_france_connect"
    t.string "family_name"
    t.string "france_connect_particulier_id"
    t.string "gender"
    t.string "given_name"
    t.string "merge_token"
    t.datetime "merge_token_created_at"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["merge_token"], name: "index_france_connect_informations_on_merge_token"
    t.index ["user_id"], name: "index_france_connect_informations_on_user_id"
  end

  create_table "geo_areas", force: :cascade do |t|
    t.bigint "champ_id"
    t.datetime "created_at"
    t.string "geo_reference_id"
    t.jsonb "geometry"
    t.jsonb "properties"
    t.string "source"
    t.datetime "updated_at"
    t.index ["champ_id"], name: "index_geo_areas_on_champ_id"
    t.index ["source"], name: "index_geo_areas_on_source"
  end

  create_table "groupe_instructeurs", force: :cascade do |t|
    t.boolean "closed", default: false
    t.datetime "created_at", null: false
    t.text "label", null: false
    t.bigint "procedure_id", null: false
    t.datetime "updated_at", null: false
    t.index ["closed", "procedure_id"], name: "index_groupe_instructeurs_on_closed_and_procedure_id"
    t.index ["procedure_id", "label"], name: "index_groupe_instructeurs_on_procedure_id_and_label", unique: true
    t.index ["procedure_id"], name: "index_groupe_instructeurs_on_procedure_id"
  end

  create_table "individuals", id: :serial, force: :cascade do |t|
    t.date "birthdate"
    t.datetime "created_at"
    t.integer "dossier_id"
    t.string "gender"
    t.string "nom"
    t.string "prenom"
    t.datetime "updated_at"
    t.index ["dossier_id"], name: "index_individuals_on_dossier_id", unique: true
  end

  create_table "initiated_mails", id: :serial, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "procedure_id"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_initiated_mails_on_procedure_id"
  end

  create_table "instructeurs", id: :serial, force: :cascade do |t|
    t.string "agent_connect_id"
    t.boolean "bypass_email_login_token", default: false, null: false
    t.datetime "created_at"
    t.text "encrypted_login_token"
    t.datetime "login_token_created_at"
    t.datetime "updated_at"
    t.bigint "user_id", null: false
    t.index ["agent_connect_id"], name: "index_instructeurs_on_agent_connect_id", unique: true
    t.index ["user_id"], name: "index_instructeurs_on_user_id"
  end

  create_table "invites", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.integer "dossier_id"
    t.string "email"
    t.string "email_sender"
    t.text "message"
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["dossier_id"], name: "index_invites_on_dossier_id"
    t.index ["email", "dossier_id"], name: "index_invites_on_email_and_dossier_id", unique: true
  end

  create_table "merge_logs", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.string "from_user_email", null: false
    t.bigint "from_user_id", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_merge_logs_on_user_id"
  end

  create_table "module_api_cartos", id: :serial, force: :cascade do |t|
    t.boolean "cadastre", default: false
    t.datetime "created_at"
    t.boolean "migrated"
    t.integer "procedure_id"
    t.boolean "quartiers_prioritaires", default: false
    t.datetime "updated_at"
    t.boolean "use_api_carto", default: false
    t.index ["procedure_id"], name: "index_module_api_cartos_on_procedure_id", unique: true
  end

  create_table "procedure_presentations", id: :serial, force: :cascade do |t|
    t.integer "assign_to_id"
    t.datetime "created_at"
    t.jsonb "displayed_fields", default: [{"label"=>"Demandeur", "table"=>"user", "column"=>"email"}], null: false
    t.jsonb "filters", default: {"tous"=>[], "suivis"=>[], "traites"=>[], "a-suivre"=>[], "archives"=>[], "expirant"=>[], "supprimes_recemment"=>[]}, null: false
    t.jsonb "sort", default: {"order"=>"desc", "table"=>"notifications", "column"=>"notifications"}, null: false
    t.datetime "updated_at"
    t.index ["assign_to_id"], name: "index_procedure_presentations_on_assign_to_id", unique: true
  end

  create_table "procedure_revision_types_de_champ", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "parent_id"
    t.integer "position", null: false
    t.bigint "revision_id", null: false
    t.bigint "type_de_champ_id", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_procedure_revision_types_de_champ_on_parent_id"
    t.index ["revision_id"], name: "index_procedure_revision_types_de_champ_on_revision_id"
    t.index ["type_de_champ_id"], name: "index_procedure_revision_types_de_champ_on_type_de_champ_id"
  end

  create_table "procedure_revisions", force: :cascade do |t|
    t.bigint "attestation_template_id"
    t.datetime "created_at", null: false
    t.bigint "dossier_submitted_message_id"
    t.bigint "procedure_id", null: false
    t.datetime "published_at"
    t.datetime "updated_at", null: false
    t.index ["attestation_template_id"], name: "index_procedure_revisions_on_attestation_template_id"
    t.index ["dossier_submitted_message_id"], name: "index_procedure_revisions_on_dossier_submitted_message_id"
    t.index ["procedure_id"], name: "index_procedure_revisions_on_procedure_id"
  end

  create_table "procedures", id: :serial, force: :cascade do |t|
    t.string "aasm_state", default: "brouillon"
    t.boolean "allow_expert_review", default: true, null: false
    t.string "api_entreprise_token"
    t.text "api_particulier_scopes", default: [], array: true
    t.jsonb "api_particulier_sources", default: {}
    t.boolean "ask_birthday", default: false, null: false
    t.date "auto_archive_on"
    t.string "cadre_juridique"
    t.bigint "canonical_procedure_id"
    t.boolean "cerfa_flag", default: false
    t.boolean "cloned_from_library", default: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.string "declarative_with_state"
    t.string "description"
    t.string "direction"
    t.bigint "draft_revision_id"
    t.integer "duree_conservation_dossiers_dans_ds"
    t.boolean "duree_conservation_etendue_par_ds", default: false
    t.boolean "durees_conservation_required", default: true
    t.string "encrypted_api_particulier_token"
    t.boolean "euro_flag", default: false
    t.boolean "experts_require_administrateur_invitation", default: false
    t.boolean "for_individual", default: false
    t.datetime "hidden_at"
    t.boolean "instructeurs_self_management_enabled"
    t.boolean "juridique_required", default: true
    t.string "libelle"
    t.string "lien_demarche"
    t.string "lien_dpo"
    t.string "lien_notice"
    t.string "lien_site_web"
    t.integer "max_duree_conservation_dossiers_dans_ds", default: 12
    t.text "monavis_embed"
    t.boolean "opendata", default: true
    t.string "organisation"
    t.bigint "parent_procedure_id"
    t.string "path", null: false
    t.boolean "piece_justificative_multiple", default: true, null: false
    t.boolean "procedure_expires_when_termine_enabled", default: true
    t.datetime "published_at"
    t.bigint "published_revision_id"
    t.bigint "replaced_by_procedure_id"
    t.text "routing_criteria_name", default: "Votre ville"
    t.boolean "routing_enabled"
    t.bigint "service_id"
    t.text "tags", default: [], array: true
    t.datetime "test_started_at"
    t.datetime "unpublished_at"
    t.datetime "updated_at", null: false
    t.string "web_hook_url"
    t.datetime "whitelisted_at"
    t.bigint "zone_id"
    t.index ["api_particulier_sources"], name: "index_procedures_on_api_particulier_sources", using: :gin
    t.index ["declarative_with_state"], name: "index_procedures_on_declarative_with_state"
    t.index ["draft_revision_id"], name: "index_procedures_on_draft_revision_id"
    t.index ["hidden_at"], name: "index_procedures_on_hidden_at"
    t.index ["libelle"], name: "index_procedures_on_libelle"
    t.index ["parent_procedure_id"], name: "index_procedures_on_parent_procedure_id"
    t.index ["path", "closed_at", "hidden_at", "unpublished_at"], name: "procedure_path_uniqueness", unique: true
    t.index ["path", "closed_at", "hidden_at"], name: "index_procedures_on_path_and_closed_at_and_hidden_at", unique: true
    t.index ["procedure_expires_when_termine_enabled"], name: "index_procedures_on_procedure_expires_when_termine_enabled"
    t.index ["published_revision_id"], name: "index_procedures_on_published_revision_id"
    t.index ["service_id"], name: "index_procedures_on_service_id"
    t.index ["tags"], name: "index_procedures_on_tags", using: :gin
    t.index ["zone_id"], name: "index_procedures_on_zone_id"
  end

  create_table "procedures_zones", id: false, force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.bigint "procedure_id"
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "zone_id"
    t.index ["procedure_id"], name: "index_procedures_zones_on_procedure_id"
    t.index ["zone_id"], name: "index_procedures_zones_on_zone_id"
  end

  create_table "received_mails", id: :serial, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "procedure_id"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_received_mails_on_procedure_id"
  end

  create_table "refused_mails", id: :serial, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "procedure_id"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_refused_mails_on_procedure_id"
  end

  create_table "services", force: :cascade do |t|
    t.bigint "administrateur_id"
    t.text "adresse"
    t.datetime "created_at", null: false
    t.string "email"
    t.jsonb "etablissement_infos", default: {}
    t.decimal "etablissement_lat", precision: 10, scale: 6
    t.decimal "etablissement_lng", precision: 10, scale: 6
    t.text "horaires"
    t.string "nom", null: false
    t.string "organisme"
    t.string "siret"
    t.string "telephone"
    t.string "type_organisme", null: false
    t.datetime "updated_at", null: false
    t.index ["administrateur_id", "nom"], name: "index_services_on_administrateur_id_and_nom", unique: true
    t.index ["administrateur_id"], name: "index_services_on_administrateur_id"
  end

  create_table "stats", force: :cascade do |t|
    t.bigint "administrations_partenaires", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.bigint "dossiers_brouillon", default: 0
    t.jsonb "dossiers_cumulative", default: "{}", null: false
    t.bigint "dossiers_depose_avant_30_jours", default: 0
    t.bigint "dossiers_deposes_entre_60_et_30_jours", default: 0
    t.bigint "dossiers_en_construction", default: 0
    t.bigint "dossiers_en_instruction", default: 0
    t.jsonb "dossiers_in_the_last_4_months", default: "{}", null: false
    t.bigint "dossiers_not_brouillon", default: 0
    t.bigint "dossiers_termines", default: 0
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "super_admins", id: :serial, force: :cascade do |t|
    t.integer "consumed_timestep"
    t.datetime "created_at"
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.boolean "otp_required_for_login"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unlock_token"
    t.datetime "updated_at"
    t.boolean "team_account", default: false
    t.index ["email"], name: "index_super_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_super_admins_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_super_admins_on_unlock_token", unique: true
  end

  create_table "targeted_user_links", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.string "target_context", null: false
    t.bigint "target_model_id", null: false
    t.string "target_model_type", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.index ["target_model_id"], name: "index_targeted_user_links_on_target_model_id"
    t.index ["user_id"], name: "index_targeted_user_links_on_user_id"
  end

  create_table "task_records", id: false, force: :cascade do |t|
    t.string "version", null: false
  end

  create_table "traitements", force: :cascade do |t|
    t.bigint "dossier_id"
    t.string "instructeur_email"
    t.string "motivation"
    t.boolean "process_expired"
    t.boolean "process_expired_migrated", default: false
    t.datetime "processed_at"
    t.string "state"
    t.index ["dossier_id"], name: "index_traitements_on_dossier_id"
    t.index ["process_expired"], name: "index_traitements_on_process_expired"
  end

  create_table "trusted_device_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "instructeur_id"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["instructeur_id"], name: "index_trusted_device_tokens_on_instructeur_id"
  end

  create_table "types_de_champ", id: :serial, force: :cascade do |t|
    t.jsonb "condition"
    t.datetime "created_at"
    t.text "description"
    t.string "libelle"
    t.boolean "mandatory", default: false
    t.jsonb "options"
    t.boolean "private", default: false, null: false
    t.bigint "stable_id"
    t.string "type_champ"
    t.datetime "updated_at"
    t.index ["private"], name: "index_types_de_champ_on_private"
    t.index ["stable_id"], name: "index_types_de_champ_on_stable_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at"
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "locale"
    t.datetime "locked_at"
    t.string "loged_in_with_france_connect", default: "false"
    t.datetime "remember_created_at"
    t.bigint "requested_merge_into_id"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "siret"
    t.text "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["requested_merge_into_id"], name: "index_users_on_requested_merge_into_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "virus_scans", force: :cascade do |t|
    t.string "blob_key"
    t.bigint "champ_id"
    t.datetime "created_at", null: false
    t.datetime "scanned_at"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["champ_id"], name: "index_virus_scans_on_champ_id"
  end

  create_table "without_continuation_mails", id: :serial, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "procedure_id"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["procedure_id"], name: "index_without_continuation_mails_on_procedure_id"
  end

  create_table "zone_labels", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.date "designated_on", null: false
    t.string "name", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "zone_id", null: false
    t.index ["zone_id"], name: "index_zone_labels_on_zone_id"
  end

  create_table "zones", force: :cascade do |t|
    t.string "acronym", null: false
    t.datetime "created_at", precision: 6, null: false
    t.string "label"
    t.datetime "updated_at", precision: 6, null: false
    t.index ["acronym"], name: "index_zones_on_acronym", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "administrateurs", "users"
  add_foreign_key "administrateurs_instructeurs", "administrateurs"
  add_foreign_key "administrateurs_instructeurs", "instructeurs"
  add_foreign_key "administrateurs_procedures", "administrateurs"
  add_foreign_key "administrateurs_procedures", "procedures"
  add_foreign_key "archives_groupe_instructeurs", "archives"
  add_foreign_key "archives_groupe_instructeurs", "groupe_instructeurs"
  add_foreign_key "assign_tos", "groupe_instructeurs"
  add_foreign_key "attestation_templates", "procedures"
  add_foreign_key "attestations", "dossiers"
  add_foreign_key "avis", "dossiers"
  add_foreign_key "avis", "experts_procedures"
  add_foreign_key "batch_operations", "instructeurs"
  add_foreign_key "bulk_messages_groupe_instructeurs", "bulk_messages"
  add_foreign_key "bulk_messages_groupe_instructeurs", "groupe_instructeurs"
  add_foreign_key "champs", "champs", column: "parent_id"
  add_foreign_key "champs", "dossiers"
  add_foreign_key "champs", "etablissements"
  add_foreign_key "champs", "types_de_champ"
  add_foreign_key "closed_mails", "procedures"
  add_foreign_key "commentaires", "dossiers"
  add_foreign_key "commentaires", "experts"
  add_foreign_key "commentaires", "instructeurs"
  add_foreign_key "dossier_operation_logs", "bill_signatures"
  add_foreign_key "dossier_transfer_logs", "dossiers"
  add_foreign_key "dossiers", "batch_operations"
  add_foreign_key "dossiers", "dossier_transfers"
  add_foreign_key "dossiers", "dossiers", column: "parent_dossier_id"
  add_foreign_key "dossiers", "groupe_instructeurs"
  add_foreign_key "dossiers", "procedure_revisions", column: "revision_id"
  add_foreign_key "dossiers", "users"
  add_foreign_key "etablissements", "dossiers"
  add_foreign_key "experts", "users"
  add_foreign_key "experts_procedures", "experts"
  add_foreign_key "experts_procedures", "procedures"
  add_foreign_key "france_connect_informations", "users"
  add_foreign_key "geo_areas", "champs"
  add_foreign_key "groupe_instructeurs", "procedures"
  add_foreign_key "initiated_mails", "procedures"
  add_foreign_key "instructeurs", "users"
  add_foreign_key "merge_logs", "users"
  add_foreign_key "procedure_presentations", "assign_tos"
  add_foreign_key "procedure_revision_types_de_champ", "procedure_revision_types_de_champ", column: "parent_id"
  add_foreign_key "procedure_revision_types_de_champ", "procedure_revisions", column: "revision_id"
  add_foreign_key "procedure_revision_types_de_champ", "types_de_champ"
  add_foreign_key "procedure_revisions", "attestation_templates"
  add_foreign_key "procedure_revisions", "dossier_submitted_messages"
  add_foreign_key "procedure_revisions", "procedures"
  add_foreign_key "procedures", "procedure_revisions", column: "draft_revision_id"
  add_foreign_key "procedures", "procedure_revisions", column: "published_revision_id"
  add_foreign_key "procedures", "services"
  add_foreign_key "procedures", "zones"
  add_foreign_key "received_mails", "procedures"
  add_foreign_key "refused_mails", "procedures"
  add_foreign_key "services", "administrateurs"
  add_foreign_key "targeted_user_links", "users"
  add_foreign_key "traitements", "dossiers"
  add_foreign_key "trusted_device_tokens", "instructeurs"
  add_foreign_key "users", "users", column: "requested_merge_into_id"
  add_foreign_key "without_continuation_mails", "procedures"
  add_foreign_key "zone_labels", "zones"
end
