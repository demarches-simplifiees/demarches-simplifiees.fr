# frozen_string_literal: true

require_relative '../sanitizable'

module APIParticulier
  module Entities
    module PoleEmploi
      class Adresse
        include Sanitizable

        class Mapper
          def self.from_api(**kwargs)
            kwargs.transform_keys do |k|
              case k.to_sym
              when :codePostal then :code_postal
              when :INSEECommune then :insee_commune
              when :ligneVoie then :ligne_voie
              when :ligneComplementDestinataire then :ligne_complement_destinataire
              when :ligneComplementAdresse then :ligne_complement_d_adresse
              when :ligneComplementDistribution then :ligne_complement_de_distribution
              when :ligneNom then :ligne_nom_du_detinataire
              else
                k.to_sym
              end
            end
          end
        end

        def initialize(**kwargs)
          attrs = Mapper.from_api(**kwargs)
          @code_postal = attrs[:code_postal]
          @insee_commune = attrs[:insee_commune]
          @localite = attrs[:localite]
          @ligne_voie = attrs[:ligne_voie]
          @ligne_complement_destinataire = attrs[:ligne_complement_destinataire]
          @ligne_complement_d_adresse = attrs[:ligne_complement_d_adresse]
          @ligne_complement_de_distribution = attrs[:ligne_complement_de_distribution]
          @ligne_nom_du_detinataire = attrs[:ligne_nom_du_detinataire]
        end

        attr_reader :code_postal, :insee_commune, :localite, :ligne_voie, :ligne_complement_destinataire,
                    :ligne_complement_d_adresse, :ligne_complement_de_distribution, :ligne_nom_du_detinataire
      end
    end
  end
end
