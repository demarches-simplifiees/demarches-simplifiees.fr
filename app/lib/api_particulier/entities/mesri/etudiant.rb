# frozen_string_literal: true

require_relative '../sanitizable'

module APIParticulier
  module Entities
    module MESRI
      class Etudiant
        include Sanitizable

        class Mapper
          def self.from_api(**kwargs)
            kwargs.transform_keys do |k|
              case k.to_sym
              when :dateNaissance then :date_de_naissance
              else
                k.to_sym
              end
            end
          end
        end

        def initialize(**kwargs)
          attrs = Mapper.from_api(**kwargs)
          @ine = attrs[:ine]
          @nom = attrs[:nom]
          @prenom = attrs[:prenom]
          @date_de_naissance = attrs[:date_de_naissance]
          @inscriptions = attrs[:inscriptions]
        end

        attr_reader :ine, :nom, :prenom

        def date_de_naissance
          DateTime.parse(@date_de_naissance)
        rescue Date::Error, TypeError
          nil
        end

        def inscriptions
          Array(@inscriptions).map { |kwargs| Inscription.new(**Hash(kwargs)) }
        end

        def inscriptions?
          Array(@inscriptions).map { |kwargs| Hash(kwargs).transform_values(&:presence).compact.presence }.any?
        end

        def as_json(*)
          super.tap do |etudiant|
            etudiant["inscriptions"] = inscriptions.map(&:as_json)
          end
        end

        def as_sanitized_json(mask = nil)
          mask ||= {}

          super.tap do |etudiant|
            if etudiant.key?(:inscriptions)
              etudiant[:inscriptions] = inscriptions.map { |i| i.as_sanitized_json(mask[:inscriptions]) }
            end
          end
        end
      end
    end
  end
end
