# frozen_string_literal: true

require_relative '../sanitizable'

module APIParticulier
  module Entities
    module CAF
      class Famille
        include Sanitizable

        class Mapper
          def self.from_api(**kwargs)
            kwargs.transform_keys do |k|
              case k.to_sym
              when :quotientFamilial then :quotient_familial
              else
                k.to_sym
              end
            end
          end
        end

        def initialize(**kwargs)
          attrs = Mapper.from_api(**kwargs)
          @allocataires = attrs[:allocataires]
          @enfants = attrs[:enfants]
          @adresse = attrs[:adresse]
          @quotient_familial = attrs[:quotient_familial]
          @annee = attrs[:annee]
          @mois = attrs[:mois]
        end

        def allocataires
          Array(@allocataires).map { |kwargs| Personne.new(**Hash(kwargs)) }
        end

        def allocataires?
          Array(@allocataires).map { |kwargs| Hash(kwargs).transform_values(&:presence).compact.presence }.any?
        end

        def enfants
          Array(@enfants).map { |kwargs| Personne.new(**Hash(kwargs)) }
        end

        def enfants?
          Array(@enfants).map { |kwargs| Hash(kwargs).transform_values(&:presence).compact.presence }.any?
        end

        def adresse
          PosteAdresse.new(**Hash(@adresse))
        end

        def adresse?
          Hash(@adresse).compact.any?
        end

        def quotient_familial
          @quotient_familial.to_i
        end

        def quotient_familial?
          !@quotient_familial.nil?
        end

        def annee
          @annee.to_i
        end

        def annee?
          !@annee.nil?
        end

        def mois
          @mois.to_i
        end

        def mois?
          !@mois.nil?
        end

        def as_json(*)
          super.tap do |famille|
            famille["allocataires"] = allocataires.map(&:as_json)
            famille["enfants"] = enfants.map(&:as_json)
            famille["adresse"] = adresse.as_json
          end
        end

        def as_sanitized_json(mask = nil)
          mask ||= {}

          super.tap do |famille|
            if famille.key?(:allocataires)
              famille[:allocataires] = allocataires.map { |a| a.as_sanitized_json(mask[:allocataires]) }
            end

            if famille.key?(:enfants)
              famille[:enfants] = enfants.map { |e| e.as_sanitized_json(mask[:enfants]) }
            end

            famille[:adresse] = adresse.as_sanitized_json(mask[:adresse]) if famille.key?(:adresse)
          end
        end
      end
    end
  end
end
