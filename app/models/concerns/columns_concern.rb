module ColumnsConcern
  extend ActiveSupport::Concern

  included do
    TYPE_DE_CHAMP = 'type_de_champ'

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

      virtual_dates = ['updated_since', 'depose_since', 'en_construction_since', 'en_instruction_since', 'processed_since']
        .map { |column| Column.new(table: 'self', column:, type: :date, virtual: true) }

      states = [Column.new(table: 'self', column: 'state', type: :enum, scope: 'instructeurs.dossiers.filterable_state', virtual: true)]

      [common, dates, sva_svr_columns(for_filters: true), virtual_dates, states].flatten.compact
    end

    def sva_svr_columns(for_filters: false)
      return if !sva_svr_enabled?

      scope = [:activerecord, :attributes, :procedure_presentation, :fields, :self]

      columns = [
        Column.new(table: 'self', column: 'sva_svr_decision_on', type: :date,
                  label: I18n.t("#{sva_svr_decision}_decision_on", scope:), classname: for_filters ? '' : 'sva-col')
      ]

      if for_filters
        columns << Column.new(table: 'self', column: 'sva_svr_decision_before', type: :date, virtual: true,
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
      types_de_champ_for_procedure_presentation
        .pluck(:type_champ, :libelle, :stable_id)
        .reject { |(type_champ)| type_champ == TypeDeChamp.type_champs.fetch(:repetition) }
        .flat_map do |(type_champ, libelle, stable_id)|
          tdc = TypeDeChamp.new(type_champ:, libelle:, stable_id:)
          tdc.dynamic_type.columns(table: TYPE_DE_CHAMP)
        end
    end
  end
end
