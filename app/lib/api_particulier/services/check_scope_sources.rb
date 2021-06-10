# frozen_string_literal: true

module APIParticulier
  module Services
    class CheckScopeSources
      def initialize(scopes, sources)
        @scopes = scopes
        @sources = sources
      end

      def call(scope_type, strict: true)
        scope_types = Array(scope_type).map { |scope| APIParticulier::Types::Scope[scope] }

        (scopes & scope_types).any? && (!strict || selected_scopes?(scope_types))
      end
      alias_method :mandatory?, :call

      def caf_mandatory?(strict: true)
        call(APIParticulier::Types::CAF_SCOPES, strict: strict)
      end

      private

      def scopes
        Array(@scopes)
      end

      def sources
        Hash(@sources)
      end

      def selected?(hsh = nil)
        hsh ||= sources

        hsh.values.any? do |value|
          value.is_a?(Hash) ? selected?(value) : value.positive?
        end
      end

      def selected_scopes?(scope_types)
        scope_types.any? do |scope_type|
          selected?(scoped_sources(scope_type))
        end
      end

      def scoped_sources(scope_type)
        case scope_type
        when APIParticulier::Types::Scope[:cnaf_allocataires] then sources.dig(:caf, :allocataires)
        when APIParticulier::Types::Scope[:cnaf_enfants] then sources.dig(:caf, :enfants)
        when APIParticulier::Types::Scope[:cnaf_adresse] then sources.dig(:caf, :adresse)
        when APIParticulier::Types::Scope[:cnaf_quotient_familial]
          Hash(sources[:caf]).slice(*APIParticulier::Entities::CAF::QuotientFamilial.new.as_json.symbolize_keys.keys)
        end
      end
    end
  end
end
