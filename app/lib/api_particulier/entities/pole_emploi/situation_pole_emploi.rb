# frozen_string_literal: true

require_relative '../sanitizable'

module APIParticulier
  module Entities
    module PoleEmploi
      class SituationPoleEmploi
        include Sanitizable

        class Mapper
          def self.from_api(**kwargs)
            kwargs.transform_keys do |k|
              case k.to_sym
              when :nomUsage then :nom_d_usage
              when :dateNaissance then :date_de_naissance
              when :dateInscription then :date_d_inscription
              when :dateRadiation then :date_de_radiation
              when :dateProchaineConvocation then :date_de_la_prochaine_convocation
              when :categorieInscription then :categorie_d_inscription
              when :codeCertificationCNAV then :code_de_certification_cnav
              else
                k.to_sym
              end
            end
          end
        end

        def initialize(**kwargs)
          attrs = Mapper.from_api(**kwargs)
          @email = attrs[:email]
          @nom = attrs[:nom]
          @nom_d_usage = attrs[:nom_d_usage]
          @prenom = attrs[:prenom]
          @identifiant = attrs[:identifiant]
          @sexe = attrs[:sexe]
          @date_de_naissance = attrs[:date_de_naissance]
          @date_d_inscription = attrs[:date_d_inscription]
          @date_de_radiation = attrs[:date_de_radiation]
          @date_de_la_prochaine_convocation = attrs[:date_de_la_prochaine_convocation]
          @categorie_d_inscription = attrs[:categorie_d_inscription]
          @code_de_certification_cnav = attrs[:code_de_certification_cnav]
          @telephone = attrs[:telephone]
          @telephone2 = attrs[:telephone2]
          @civilite = attrs[:civilite]
          @adresse = attrs[:adresse]
        end

        attr_reader :email, :nom, :nom_d_usage, :prenom, :identifiant, :categorie_d_inscription,
                    :code_de_certification_cnav, :civilite, :telephone, :telephone2

        def sexe
          APIParticulier::Types::Sexe[@sexe]
        rescue ArgumentError
          nil
        end

        def date_de_naissance
          Date.parse(@date_de_naissance)
        rescue Date::Error, TypeError
          nil
        end

        def date_d_inscription
          Date.parse(@date_d_inscription)
        rescue Date::Error, TypeError
          nil
        end

        def date_de_radiation
          Date.parse(@date_de_radiation)
        rescue Date::Error, TypeError
          nil
        end

        def date_de_la_prochaine_convocation
          Date.parse(@date_de_la_prochaine_convocation)
        rescue Date::Error, TypeError
          nil
        end

        def telephones
          [@telephone, @telephone2].compact
        end

        def adresse
          Adresse.new(**Hash(@adresse))
        end

        def adresse?
          Hash(@adresse).compact.any?
        end

        def as_json(*)
          super.tap do |situation|
            situation["adresse"] = adresse.as_json
          end
        end

        def as_sanitized_json(mask = nil)
          mask ||= {}

          super.tap do |situation|
            situation[:adresse] = adresse.as_sanitized_json(mask[:adresse]) if situation.key?(:adresse)
          end
        end
      end
    end
  end
end
