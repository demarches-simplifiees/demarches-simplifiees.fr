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

      # Remove sources not available for the procedure
      def sanitize(requested_sources)
        requested_sources_a = h_to_a(requested_sources)
        available_sources_a = h_to_a(available_sources)

        filtered_sources_a = requested_sources_a.intersection(available_sources_a)

        a_to_h(filtered_sources_a)
      end

      private

      # { 'cnaf' => { 'scope' => ['a', 'b'] }} => [['cnaf', 'scope', 'a'], ['cnaf', 'scope', 'b']]
      def h_to_a(h)
        h.reduce([]) { |acc, (provider, scopes)| scopes.each { |scope, values| values.each { |s, _| acc << [provider, scope, s] } }; acc }
      end

      # [['cnaf', 'scope', 'a'], ['cnaf', 'scope', 'b']] => { 'cnaf' => { 'scope' => ['a', 'b'] }}
      def a_to_h(a)
        h = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }

        a.reduce(h) { |acc, (provider, scope, source)| h[provider][scope] << source; acc }
      end

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
