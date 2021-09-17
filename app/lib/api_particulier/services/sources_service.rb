module APIParticulier
  module Services
    class SourcesService
      def initialize(procedure)
        @procedure = procedure
      end

      def available_sources
        @procedure.api_particulier_scopes
          .map { |provider_and_scope| raw_scopes[provider_and_scope] }
          .map { |provider, scope| extract_sources(provider, scope) }
          .reduce({}) { |acc, el| acc.deep_merge(el) }
      end

      private

      def extract_sources(provider, scope)
        { provider => { scope => providers[provider][scope] } }
      end

      def raw_scopes
        {
          'cnaf_allocataires' => ['cnaf', 'allocataires'],
          'cnaf_enfants' => ['cnaf', 'enfants'],
          'cnaf_adresse' => ['cnaf', 'adresse'],
          'cnaf_quotient_familial' => ['cnaf', 'quotient_familial']
        }
      end

      def providers
        {
          'cnaf' => {
            'allocataires' => ['noms_prenoms', 'date_de_naissance', 'sexe'],
            'enfants' => ['noms_prenoms', 'date_de_naissance', 'sexe'],
            'adresse' => ['identite', 'complement_d_identite', 'complement_d_identite_geo', 'numero_et_rue', 'lieu_dit', 'code_postal_et_ville', 'pays'],
            'quotient_familial' => ['quotient_familial', 'annee', 'mois']
          }
        }
      end
    end
  end
end
