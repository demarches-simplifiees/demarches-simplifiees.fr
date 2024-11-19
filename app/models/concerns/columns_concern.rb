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

      # TODO: to remove after linked_drop_down column column_id migration
      if column.nil? && h_id.is_a?(Hash) && h_id[:column_id].present?
        h_id[:column_id].gsub!('->', '.')

        column = columns.find { _1.h_id == h_id }
      end

      raise ActiveRecord::RecordNotFound.new("Column: unable to find h_id: #{h_id} or label: #{label} for procedure_id #{id}") if column.nil?

      column
    end

    def columns
      Current.procedure_columns ||= {}

      Current.procedure_columns[id] ||= begin
        columns = dossier_columns
        columns.concat(standard_columns)
        columns.concat(individual_columns) if for_individual
        columns.concat(moral_columns) if !for_individual
        columns.concat(procedure_chorus_columns) if chorusable? && chorus_configuration.complete?
        columns.concat(types_de_champ_columns)
      end
    end

    def usager_columns_for_export
      columns = [dossier_id_column, user_email_for_display_column, user_france_connected_column]
      columns.concat(individual_columns) if for_individual
      columns.concat(moral_columns) if !for_individual
      columns.concat(procedure_chorus_columns) if chorusable? && chorus_configuration.complete?

      # ensure the columns exist in main list
      # otherwise, they will be found by the find_column method
      columns.filter { _1.id.in?(self.columns.map(&:id)) }
    end

    def dossier_columns_for_export
      columns = [dossier_state_column, dossier_archived_column]
      columns.concat(dossier_dates_columns)
      columns.concat([dossier_motivation_column])
      columns.concat(sva_svr_columns(for_export: true)) if sva_svr_enabled?
      columns.concat([groupe_instructeurs_id_column, followers_instructeurs_email_column])

      # ensure the columns exist in main list
      # otherwise, they will be found by the find_column method
      columns.filter { _1.id.in?(self.columns.map(&:id)) }
    end

    def dossier_id_column = dossier_col(table: 'self', column: 'id', type: :integer)

    def dossier_state_column
      options_for_select = I18n.t('instructeurs.dossiers.filterable_state').map(&:to_a).map(&:reverse)

      dossier_col(table: 'self', column: 'state', type: :enum, options_for_select:, displayable: false)
    end

    def notifications_column = dossier_col(table: 'notifications', column: 'notifications', label: "notifications", filterable: false)

    def sva_svr_columns(for_export: false)
      scope = [:activerecord, :attributes, :procedure_presentation, :fields, :self]

      columns = [
        dossier_col(table: 'self', column: 'sva_svr_decision_on', type: :date,
                  label: I18n.t("#{sva_svr_decision}_decision_on", scope:, type: sva_svr_configuration.human_decision))
      ]
      if !for_export
        columns << dossier_col(table: 'self', column: 'sva_svr_decision_before', type: :date, displayable: false,
                      label: I18n.t("#{sva_svr_decision}_decision_before", scope:))
      end
      columns
    end

    def default_sorted_column
      SortedColumn.new(column: notifications_column, order: 'desc')
    end

    def default_displayed_columns = [email_column]

    private

    def groupe_instructeurs_id_column = dossier_col(table: 'groupe_instructeur', column: 'id', type: :enum)

    def followers_instructeurs_email_column = dossier_col(table: 'followers_instructeurs', column: 'email')

    def dossier_archived_column = dossier_col(table: 'self', column: 'archived', type: :boolean, displayable: false, filterable: false);

    def dossier_motivation_column = dossier_col(table: 'self', column: 'motivation', type: :text, displayable: false, filterable: false);

    def user_email_for_display_column = dossier_col(table: 'self', column: 'user_email_for_display', filterable: false, displayable: false)

    def user_france_connected_column = dossier_col(table: 'self', column: 'user_from_france_connect?', type: :boolean, filterable: false, displayable: false)

    def dossier_labels_column = dossier_col(table: 'dossier_labels', column: 'label_id', type: :enum, options_for_select: labels.map { [_1.name, _1.id] })

    def procedure_chorus_columns
      ['domaine_fonctionnel', 'referentiel_prog', 'centre_de_cout']
        .map { |column| dossier_col(table: 'procedure', column:, displayable: false, filterable: false) }
    end

    def dossier_non_displayable_dates_columns
      ['updated_since', 'depose_since', 'en_construction_since', 'en_instruction_since', 'processed_since']
        .map { |column| dossier_col(table: 'self', column:, type: :date, displayable: false) }
    end

    def dossier_dates_columns
      ['created_at', 'updated_at', 'last_champ_updated_at', 'depose_at', 'en_construction_at', 'en_instruction_at', 'processed_at']
        .map { |column| dossier_col(table: 'self', column:, type: :datetime) }
    end

    def email_column
      dossier_col(table: 'user', column: 'email')
    end

    def dossier_columns
      columns = [dossier_id_column, notifications_column]
      columns.concat([dossier_state_column])
      columns.concat([dossier_archived_column])
      columns.concat(dossier_dates_columns)
      columns.concat([dossier_motivation_column])
      columns.concat(sva_svr_columns(for_export: false)) if sva_svr_enabled?
      columns.concat(dossier_non_displayable_dates_columns)
    end

    def standard_columns
      [
        email_column,
        user_email_for_display_column,
        followers_instructeurs_email_column,
        groupe_instructeurs_id_column,
        dossier_col(table: 'avis', column: 'question_answer', filterable: false),
        user_france_connected_column,
        dossier_labels_column
      ]
    end

    def individual_columns
      ['gender', 'nom', 'prenom'].map { |column| dossier_col(table: 'individual', column:) }
        .concat ['mandataire_last_name', 'mandataire_first_name'].map { |column| dossier_col(table: 'self', column:) }
        .concat ['for_tiers'].map { |column| dossier_col(table: 'self', column:, type: :boolean) }
    end

    def moral_columns
      etablissements = ['entreprise_forme_juridique', 'entreprise_siren', 'entreprise_nom_commercial', 'entreprise_raison_sociale', 'entreprise_siret_siege_social']
        .map { |column| dossier_col(table: 'etablissement', column:) }

      etablissement_dates = ['entreprise_date_creation'].map { |column| dossier_col(table: 'etablissement', column:, type: :date) }

      for_export = ["siege_social", "naf", "adresse", "numero_voie", "type_voie", "nom_voie", "complement_adresse", "localite", "code_insee_localite", "entreprise_siren", "entreprise_capital_social", "entreprise_numero_tva_intracommunautaire", "entreprise_forme_juridique_code", "entreprise_code_effectif_entreprise", "entreprise_etat_administratif", "entreprise_nom", "entreprise_prenom", "association_rna", "association_titre", "association_objet", "association_date_creation", "association_date_declaration", "association_date_publication"]
        .map { |column| dossier_col(table: 'etablissement', column:, displayable: false, filterable: false) }

      other = ['siret', 'libelle_naf', 'code_postal'].map { |column| dossier_col(table: 'etablissement', column:) }

      [etablissements, etablissement_dates, other, for_export].flatten
    end

    def types_de_champ_columns
      all_revisions_types_de_champ.flat_map { _1.columns(procedure: self) }
    end

    def dossier_col(**args) = Columns::DossierColumn.new(**(args.merge(procedure_id: id)))
  end
end
