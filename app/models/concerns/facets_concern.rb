module FacetsConcern
  extend ActiveSupport::Concern

  included do
    TYPE_DE_CHAMP = 'type_de_champ'

    def find_facet(id:)
      facets.find { |f| f.id == id }
    end

    def facets
      facets = dossier_facets

      facets.push(
        Facet.new(table: 'user', column: 'email', type: :text),
        Facet.new(table: 'followers_instructeurs', column: 'email', type: :text),
        Facet.new(table: 'groupe_instructeur', column: 'id', type: :enum),
        Facet.new(table: 'avis', column: 'question_answer', filterable: false)
      )

      if for_individual
        facets.push(
          Facet.new(table: "individual", column: "prenom", type: :text),
          Facet.new(table: "individual", column: "nom", type: :text),
          Facet.new(table: "individual", column: "gender", type: :text)
        )
      end

      if !for_individual
        facets.push(
          Facet.new(table: 'etablissement', column: 'entreprise_siren', type: :text),
          Facet.new(table: 'etablissement', column: 'entreprise_forme_juridique', type: :text),
          Facet.new(table: 'etablissement', column: 'entreprise_nom_commercial', type: :text),
          Facet.new(table: 'etablissement', column: 'entreprise_raison_sociale', type: :text),
          Facet.new(table: 'etablissement', column: 'entreprise_siret_siege_social', type: :text),
          Facet.new(table: 'etablissement', column: 'entreprise_date_creation', type: :date),
          Facet.new(table: 'etablissement', column: 'siret', type: :text),
          Facet.new(table: 'etablissement', column: 'libelle_naf', type: :text),
          Facet.new(table: 'etablissement', column: 'code_postal', type: :text)
        )
      end

      facets.concat(types_de_champ_facets)

      facets
    end

    def dossier_facets
      [
        Facet.new(table: 'self', column: 'created_at', type: :date),
        Facet.new(table: 'self', column: 'updated_at', type: :date),
        Facet.new(table: 'self', column: 'depose_at', type: :date),
        Facet.new(table: 'self', column: 'en_construction_at', type: :date),
        Facet.new(table: 'self', column: 'en_instruction_at', type: :date),
        Facet.new(table: 'self', column: 'processed_at', type: :date),
        *sva_svr_facets(for_filters: true),
        Facet.new(table: 'self', column: 'updated_since', type: :date, virtual: true),
        Facet.new(table: 'self', column: 'depose_since', type: :date, virtual: true),
        Facet.new(table: 'self', column: 'en_construction_since', type: :date, virtual: true),
        Facet.new(table: 'self', column: 'en_instruction_since', type: :date, virtual: true),
        Facet.new(table: 'self', column: 'processed_since', type: :date, virtual: true),
        Facet.new(table: 'self', column: 'state', type: :enum, scope: 'instructeurs.dossiers.filterable_state', virtual: true)
      ].compact_blank
    end

    def sva_svr_facets(for_filters: false)
      return if !sva_svr_enabled?

      i18n_scope = [:activerecord, :attributes, :procedure_presentation, :fields, :self]

      facets = []
      facets << Facet.new(table: 'self', column: 'sva_svr_decision_on',
                    type: :date,
                    label: I18n.t("#{sva_svr_decision}_decision_on", scope: i18n_scope),
                    classname: for_filters ? '' : 'sva-col')

      if for_filters
        facets << Facet.new(table: 'self', column: 'sva_svr_decision_before',
                      label: I18n.t("#{sva_svr_decision}_decision_before", scope: i18n_scope),
                      type: :date, virtual: true)
      end

      facets
    end

    private

    def types_de_champ_facets
      types_de_champ_for_procedure_presentation
        .pluck(:type_champ, :libelle, :stable_id)
        .reject { |(type_champ)| type_champ == TypeDeChamp.type_champs.fetch(:repetition) }
        .flat_map do |(type_champ, libelle, stable_id)|
          tdc = TypeDeChamp.new(type_champ:, libelle:, stable_id:)

          tdc.dynamic_type.search_paths.map do |path_struct|
            Facet.new(
              table: TYPE_DE_CHAMP,
              column: tdc.stable_id.to_s,
              label: path_struct[:libelle],
              type: TypeDeChamp.filter_hash_type(tdc.type_champ),
              value_column: path_struct[:path]
            )
          end
        end
    end
  end
end
