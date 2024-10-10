# frozen_string_literal: true

module ColumnsConcern
  extend ActiveSupport::Concern

  included do
    # we cannot use column.id ( == { procedure_id, column_id }.to_json)
    # as the order of the keys is not guaranteed
    # instead, we are using h_id == { procedure_id:, column_id: }
    # another way to find a column is to look for its label
    def find_column(h_id: nil, label: nil)
      column = columns.find { _1.h_id == h_id } if h_id.present?
      column = columns.find { _1.label == label } if label.present?

      raise ActiveRecord::RecordNotFound if column.nil?

      column
    end

    def columns
      Current.procedure_columns ||= {}

      Current.procedure_columns[id] ||= begin
        columns = dossier_columns
        columns.concat(standard_columns)
        columns.concat(individual_columns) if for_individual
        columns.concat(moral_columns) if !for_individual
        columns.concat(types_de_champ_columns)
      end
    end

    def dossier_id_column
      Column.new(procedure_id: id, table: 'self', column: 'id', type: :number)
    end

    def dossier_state_column
      Column.new(procedure_id: id, table: 'self', column: 'state', type: :enum, scope: 'instructeurs.dossiers.filterable_state', displayable: false)
    end

    def notifications_column
      Column.new(procedure_id: id, table: 'notifications', column: 'notifications', label: "notifications", filterable: false)
    end

    def dossier_columns
      common = [dossier_id_column, notifications_column]

      dates = ['created_at', 'updated_at', 'depose_at', 'en_construction_at', 'en_instruction_at', 'processed_at']
        .map { |column| Column.new(procedure_id: id, table: 'self', column:, type: :date) }

      non_displayable_dates = ['updated_since', 'depose_since', 'en_construction_since', 'en_instruction_since', 'processed_since']
        .map { |column| Column.new(procedure_id: id, table: 'self', column:, type: :date, displayable: false) }

      states = [dossier_state_column]

      [common, dates, sva_svr_columns, non_displayable_dates, states].flatten.compact
    end

    def sva_svr_columns
      return if !sva_svr_enabled?

      scope = [:activerecord, :attributes, :procedure_presentation, :fields, :self]

      columns = [
        Column.new(procedure_id: id, table: 'self', column: 'sva_svr_decision_on', type: :date,
                  label: I18n.t("#{sva_svr_decision}_decision_on", scope:))
      ]

      columns << Column.new(procedure_id: id, table: 'self', column: 'sva_svr_decision_before', type: :date, displayable: false,
                    label: I18n.t("#{sva_svr_decision}_decision_before", scope:))

      columns
    end

    def default_sorted_column
      SortedColumn.new(column: notifications_column, order: 'desc')
    end

    def default_displayed_columns = [email_column]

    private

    def email_column
      Column.new(procedure_id: id, table: 'user', column: 'email')
    end

    def standard_columns
      [
        email_column,
        Column.new(procedure_id: id, table: 'followers_instructeurs', column: 'email'),
        Column.new(procedure_id: id, table: 'groupe_instructeur', column: 'id', type: :enum),
        Column.new(procedure_id: id, table: 'avis', column: 'question_answer', filterable: false) # not filterable ?
      ]
    end

    def individual_columns
      ['nom', 'prenom', 'gender'].map { |column| Column.new(procedure_id: id, table: 'individual', column:) }
    end

    def moral_columns
      etablissements = ['entreprise_siren', 'entreprise_forme_juridique', 'entreprise_nom_commercial', 'entreprise_raison_sociale', 'entreprise_siret_siege_social']
        .map { |column| Column.new(procedure_id: id, table: 'etablissement', column:) }

      etablissement_dates = ['entreprise_date_creation'].map { |column| Column.new(procedure_id: id, table: 'etablissement', column:, type: :date) }

      other = ['siret', 'libelle_naf', 'code_postal'].map { |column| Column.new(procedure_id: id, table: 'etablissement', column:) }

      [etablissements, etablissement_dates, other].flatten
    end

    def types_de_champ_columns
      all_revisions_types_de_champ.flat_map { _1.columns(procedure_id: id) }
    end
  end
end
