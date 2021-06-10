# frozen_string_literal: true

require_relative '../sanitizable'

module APIParticulier
  module Entities
    module DGFIP
      class Declarant
        include Sanitizable

        class Mapper
          def self.from_api(**kwargs)
            kwargs.transform_keys do |k|
              case k.to_sym
              when :nomNaissance then :nom_de_naissance
              when :dateNaissance then :date_de_naissance
              else
                k.to_sym
              end
            end
          end
        end

        def initialize(**kwargs)
          attrs = Mapper.from_api(**kwargs)
          @nom = attrs[:nom]
          @nom_de_naissance = attrs[:nom_de_naissance]
          @prenoms = attrs[:prenoms]
          @date_de_naissance = attrs[:date_de_naissance]
        end

        attr_reader :nom, :nom_de_naissance, :prenoms

        def date_de_naissance
          Date.parse(@date_de_naissance)
        rescue Date::Error, TypeError
          nil
        end
      end
    end
  end
end
