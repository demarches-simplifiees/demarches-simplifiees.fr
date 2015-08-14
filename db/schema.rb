# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150814090717) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "commentaires", force: :cascade do |t|
    t.string   "email"
    t.datetime "created_at", null: false
    t.string   "body"
    t.integer  "dossier_id"
    t.datetime "updated_at", null: false
  end

  add_index "commentaires", ["dossier_id"], name: "index_commentaires_on_dossier_id", using: :btree

  create_table "dossiers", force: :cascade do |t|
    t.string  "description"
    t.boolean "autorisation_donnees"
    t.string  "position_lat"
    t.string  "position_lon"
    t.string  "ref_dossier"
    t.string  "nom_projet"
    t.string  "montant_projet"
    t.string  "montant_aide_demande"
    t.string  "date_previsionnelle"
    t.string  "lien_plus_infos"
    t.string  "mail_contact"
    t.boolean "dossier_termine"
    t.integer "ref_formulaire_id"
  end

  add_index "dossiers", ["ref_formulaire_id"], name: "index_dossiers_on_ref_formulaire_id", using: :btree

  create_table "entreprises", force: :cascade do |t|
    t.string  "siren"
    t.integer "capital_social"
    t.string  "numero_tva_intracommunautaire"
    t.string  "forme_juridique"
    t.string  "forme_juridique_code"
    t.string  "nom_commercial"
    t.string  "raison_sociale"
    t.string  "siret_siege_social"
    t.string  "code_effectif_entreprise"
    t.integer "date_creation"
    t.string  "nom"
    t.string  "prenom"
    t.integer "dossier_id"
  end

  create_table "etablissements", force: :cascade do |t|
    t.string  "siret"
    t.boolean "siege_social"
    t.string  "naf"
    t.string  "libelle_naf"
    t.string  "adresse"
    t.string  "numero_voie"
    t.string  "type_voie"
    t.string  "nom_voie"
    t.string  "complement_adresse"
    t.string  "code_postal"
    t.string  "localite"
    t.string  "code_insee_localite"
    t.integer "dossier_id"
    t.integer "entreprise_id"
  end

  create_table "evenement_vies", force: :cascade do |t|
    t.string   "nom"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.boolean  "use_admi_facile"
  end

  create_table "pieces_jointes", force: :cascade do |t|
    t.string  "content"
    t.integer "dossier_id"
    t.integer "type_piece_jointe_id"
  end

  add_index "pieces_jointes", ["type_piece_jointe_id"], name: "index_pieces_jointes_on_type_piece_jointe_id", using: :btree

  create_table "pros", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pros", ["email"], name: "index_pros_on_email", unique: true, using: :btree
  add_index "pros", ["reset_password_token"], name: "index_pros_on_reset_password_token", unique: true, using: :btree

  create_table "ref_formulaires", force: :cascade do |t|
    t.string   "ref_demarche"
    t.string   "nom"
    t.string   "objet"
    t.string   "ministere"
    t.string   "cigle_ministere"
    t.string   "direction"
    t.string   "evenement_vie"
    t.string   "publics"
    t.string   "lien_demarche"
    t.string   "lien_fiche_signaletique"
    t.string   "lien_notice"
    t.string   "categorie"
    t.boolean  "mail_pj"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.boolean  "use_admi_facile"
  end

  create_table "types_piece_jointe", force: :cascade do |t|
    t.string   "CERFA"
    t.string   "nature"
    t.string   "libelle_complet"
    t.string   "etablissement"
    t.string   "libelle"
    t.string   "description"
    t.string   "demarche"
    t.string   "administration_emetrice"
    t.boolean  "api_entreprise"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "commentaires", "dossiers"
end
