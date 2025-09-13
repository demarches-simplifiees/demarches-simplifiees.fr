# frozen_string_literal: true

class DubiousProcedure
  extend ActiveModel::Naming
  extend ActiveModel::Translation

  attr_accessor :id, :libelle, :dubious_champs, :aasm_state, :hidden_at_as_template

  FORBIDDEN_KEYWORDS = [
    'NIR', 'RNIPP', 'race', 'religion',
    'carte bancaire', 'carte bleue', 'sécurité sociale',
    'agdref', 'syndicat', 'syndical',
    'parti politique', 'opinion politique', 'bord politique', 'courant politique',
    'médical', 'handicap', 'maladie', 'allergie', 'hospitalisé', 'RQTH', 'vaccin'
  ]

  def persisted?
    false
  end

  def self.all
    procedures_with_forbidden_tdcs_sql = ProcedureRevisionTypeDeChamp
      .unscope(:eager_load)
      .joins(:procedure, :type_de_champ)
      .select("string_agg(types_de_champ.libelle, ' - ') as dubious_champs, procedures.id as procedure_id, procedures.libelle as procedure_libelle, procedures.aasm_state as procedure_aasm_state, procedures.hidden_at_as_template as procedure_hidden_at_as_template")
      .where("unaccent(types_de_champ.libelle) ~* unaccent(?)", forbidden_regexp)
      .where(types_de_champ: { type_champ: [TypeDeChamp.type_champs.fetch(:text), TypeDeChamp.type_champs.fetch(:textarea)] })
      .where(procedures: { closed_at: nil, whitelisted_at: nil })
      .group("procedures.id")
      .order("procedures.id asc")
      .to_sql

    ActiveRecord::Base.connection.execute(procedures_with_forbidden_tdcs_sql).map do |procedure|
      p = DubiousProcedure.new
      p.id = procedure["procedure_id"]
      p.dubious_champs = procedure["dubious_champs"]
      p.libelle = procedure["procedure_libelle"]
      p.aasm_state = procedure["procedure_aasm_state"]
      p.hidden_at_as_template = procedure["procedure_hidden_at_as_template"]
      p
    end
  end

  # \\y is a word boundary
  def self.forbidden_regexp
    FORBIDDEN_KEYWORDS.map { |keyword| "\\y#{keyword}\\y" }
      .join('|')
  end
end
