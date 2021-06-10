# frozen_string_literal: true

require_relative '../sanitizable'

module APIParticulier
  module Entities
    module MESRI
      class Inscription
        include Sanitizable

        class Mapper
          def self.from_api(**kwargs)
            kwargs.transform_keys do |k|
              case k.to_sym
              when :dateDebutInscription then :date_de_debut_d_inscription
              when :dateFinInscription then :date_de_fin_d_inscription
              when :codeCommune then :code_commune
              else
                k.to_sym
              end
            end
          end
        end

        def initialize(**kwargs)
          attrs = Mapper.from_api(**kwargs)
          @date_de_debut_d_inscription = attrs[:date_de_debut_d_inscription]
          @date_de_fin_d_inscription = attrs[:date_de_fin_d_inscription]
          @statut = attrs[:statut]
          @regime = attrs[:regime]
          @code_commune = attrs[:code_commune]
          @etablissement = attrs[:etablissement]
        end

        attr_reader :code_commune

        def date_de_debut_d_inscription
          DateTime.parse(@date_de_debut_d_inscription)
        rescue Date::Error, TypeError
          nil
        end

        def date_de_fin_d_inscription
          DateTime.parse(@date_de_fin_d_inscription)
        rescue Date::Error, TypeError
          nil
        end

        def statut
          APIParticulier::Types::StatutEtudiant[@statut]
        rescue ArgumentError
          nil
        end

        def regime
          APIParticulier::Types::RegimeEtudiant[@regime]
        rescue ArgumentError
          nil
        end

        def etablissement
          Etablissement.new(**Hash(@etablissement))
        end

        def etablissement?
          Hash(@etablissement).compact.any?
        end

        def as_json(*)
          super.tap do |etudiant|
            etudiant["etablissement"] = etablissement.as_json
          end
        end

        def as_sanitized_json(mask = nil)
          mask ||= {}

          super.tap do |etudiant|
            if etudiant.key?(:etablissement)
              etudiant[:etablissement] = etablissement.as_sanitized_json(mask[:etablissement])
            end
          end
        end
      end
    end
  end
end
