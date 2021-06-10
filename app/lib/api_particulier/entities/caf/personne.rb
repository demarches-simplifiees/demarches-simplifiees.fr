# frozen_string_literal: true

require_relative '../sanitizable'

module APIParticulier
  module Entities
    module CAF
      class Personne
        include Sanitizable

        class Mapper
          def self.from_api(**kwargs)
            kwargs.transform_keys do |k|
              case k.to_sym
              when :nomPrenom then :noms_et_prenoms
              when :dateDeNaissance then :date_de_naissance
              else
                k.to_sym
              end
            end
          end
        end

        def initialize(**kwargs)
          attrs = Mapper.from_api(**kwargs)
          @noms_et_prenoms = attrs[:noms_et_prenoms]
          @date_de_naissance = attrs[:date_de_naissance]
          @sexe = attrs[:sexe]
        end

        attr_reader :noms_et_prenoms

        # Date de naissance au format: JJMMAAAA
        def date_de_naissance
          Date.strptime(@date_de_naissance, "%d%m%Y")
        rescue Date::Error, TypeError
          nil
        end

        def sexe
          APIParticulier::Types::Sexe[@sexe]
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
