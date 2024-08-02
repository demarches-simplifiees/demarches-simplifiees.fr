module FacetsConcern
  extend ActiveSupport::Concern

  included do
    TYPE_DE_CHAMP = 'type_de_champ'

    def find_facet(id:) = facets.find { |f| f.id == id }

    def facets
      facets = dossier_facets
      facets.concat(standard_facets)
      facets.concat(individual_facets) if for_individual
      facets.concat(moral_facets) if !for_individual
      facets.concat(types_de_champ_facets)
    end

    def dossier_facets
      common = [Facet.new(table: 'self', column: 'id', classname: 'number-col'), Facet.new(table: 'notifications', column: 'notifications', label: "notifications", filterable: false)]

      dates = ['created_at', 'updated_at', 'depose_at', 'en_construction_at', 'en_instruction_at', 'processed_at']
        .map { |column| Facet.new(table: 'self', column:, type: :date) }

      virtual_dates = ['updated_since', 'depose_since', 'en_construction_since', 'en_instruction_since', 'processed_since']
        .map { |column| Facet.new(table: 'self', column:, type: :date, virtual: true) }

      states = [Facet.new(table: 'self', column: 'state', type: :enum, scope: 'instructeurs.dossiers.filterable_state', virtual: true)]

      [common, dates, sva_svr_facets(for_filters: true), virtual_dates, states].flatten.compact
    end

    def sva_svr_facets(for_filters: false)
      return if !sva_svr_enabled?

      scope = [:activerecord, :attributes, :procedure_presentation, :fields, :self]

      facets = [
        Facet.new(table: 'self', column: 'sva_svr_decision_on', type: :date,
                  label: I18n.t("#{sva_svr_decision}_decision_on", scope:), classname: for_filters ? '' : 'sva-col')
      ]

      if for_filters
        facets << Facet.new(table: 'self', column: 'sva_svr_decision_before', type: :date, virtual: true,
                      label: I18n.t("#{sva_svr_decision}_decision_before", scope:))
      end

      facets
    end

    private

    def standard_facets
      [
        Facet.new(table: 'user', column: 'email'),
        Facet.new(table: 'followers_instructeurs', column: 'email'),
        Facet.new(table: 'groupe_instructeur', column: 'id', type: :enum),
        Facet.new(table: 'avis', column: 'question_answer', filterable: false)
      ]
    end

    def individual_facets
      ['nom', 'prenom', 'gender'].map { |column| Facet.new(table: 'individual', column:) }
    end

    def moral_facets
      etablissements = ['entreprise_siren', 'entreprise_forme_juridique', 'entreprise_nom_commercial', 'entreprise_raison_sociale', 'entreprise_siret_siege_social']
        .map { |column| Facet.new(table: 'etablissement', column:) }

      etablissement_dates = ['entreprise_date_creation'].map { |column| Facet.new(table: 'etablissement', column:, type: :date) }

      other = ['siret', 'libelle_naf', 'code_postal'].map { |column| Facet.new(table: 'etablissement', column:) }

      [etablissements, etablissement_dates, other].flatten
    end

    def types_de_champ_facets
      types_de_champ_for_procedure_presentation
        .pluck(:type_champ, :libelle, :stable_id)
        .reject { |(type_champ)| type_champ == TypeDeChamp.type_champs.fetch(:repetition) }
        .flat_map do |(type_champ, libelle, stable_id)|
          tdc = TypeDeChamp.new(type_champ:, libelle:, stable_id:)
          tdc.dynamic_type.facets(table: TYPE_DE_CHAMP)
        end
    end
  end
end
