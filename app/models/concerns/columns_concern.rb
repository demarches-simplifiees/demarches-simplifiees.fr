# frozen_string_literal: true

module ColumnsConcern
  extend ActiveSupport::Concern

  included do
    def find_column(id:) = columns.find { |f| f.id == id }

    def columns
      columns = dossier_columns
      columns.concat(standard_columns)
      columns.concat(individual_columns) if for_individual
      columns.concat(moral_columns) if !for_individual
      columns.concat(types_de_champ_columns)
    end

    def dossier_columns
      common = [Column.new(table: 'self', column: 'id', classname: 'number-col'), Column.new(table: 'notifications', column: 'notifications', label: "notifications", filterable: false)]

      dates = ['created_at', 'updated_at', 'depose_at', 'en_construction_at', 'en_instruction_at', 'processed_at']
        .map { |column| Column.new(table: 'self', column:, type: :date) }

      non_displayable_dates = ['updated_since', 'depose_since', 'en_construction_since', 'en_instruction_since', 'processed_since']
        .map { |column| Column.new(table: 'self', column:, type: :date, displayable: false) }

      states = [Column.new(table: 'self', column: 'state', type: :enum, scope: 'instructeurs.dossiers.filterable_state', displayable: false)]

      [common, dates, sva_svr_columns(for_filters: true), non_displayable_dates, states].flatten.compact
    end

    def sva_svr_columns(for_filters: false)
      return if !sva_svr_enabled?

      scope = [:activerecord, :attributes, :procedure_presentation, :fields, :self]

      columns = [
        Column.new(table: 'self', column: 'sva_svr_decision_on', type: :date,
                  label: I18n.t("#{sva_svr_decision}_decision_on", scope:), classname: for_filters ? '' : 'sva-col')
      ]

      if for_filters
        columns << Column.new(table: 'self', column: 'sva_svr_decision_before', type: :date, displayable: false,
                      label: I18n.t("#{sva_svr_decision}_decision_before", scope:))
      end

      columns
    end

    private

    def standard_columns
      [
        Column.new(table: 'user', column: 'email'),
        Column.new(table: 'followers_instructeurs', column: 'email'),
        Column.new(table: 'groupe_instructeur', column: 'id', type: :enum),
        Column.new(table: 'avis', column: 'question_answer', filterable: false)
      ]
    end

    def individual_columns
      ['nom', 'prenom', 'gender'].map { |column| Column.new(table: 'individual', column:) }
    end

    def moral_columns
      etablissements = ['entreprise_siren', 'entreprise_forme_juridique', 'entreprise_nom_commercial', 'entreprise_raison_sociale', 'entreprise_siret_siege_social']
        .map { |column| Column.new(table: 'etablissement', column:) }

      etablissement_dates = ['entreprise_date_creation'].map { |column| Column.new(table: 'etablissement', column:, type: :date) }

      other = ['siret', 'libelle_naf', 'code_postal'].map { |column| Column.new(table: 'etablissement', column:) }

      [etablissements, etablissement_dates, other].flatten
    end

    def types_de_champ_columns
      all_revisions_types_de_champ.flat_map(&:columns)
    end
  end
end
