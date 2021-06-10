# frozen_string_literal: true

require_relative '../sanitizable'

module APIParticulier
  module Entities
    module DGFIP
      class AvisImposition
        include Sanitizable

        class Mapper
          def self.from_api(**kwargs)
            kwargs.transform_keys do |k|
              case k.to_sym
              when :foyerFiscal then :foyer_fiscal
              when :dateRecouvrement then :date_de_recouvrement
              when :dateEtablissement then :date_d_etablissement
              when :nombreParts then :nombre_de_parts
              when :situationFamiliale then :situation_familiale
              when :nombrePersonnesCharge then :nombre_de_personnes_a_charge
              when :revenuBrutGlobal then :revenu_brut_global
              when :revenuImposable then :revenu_imposable
              when :impotRevenuNetAvantCorrections then :impot_revenu_net_avant_corrections
              when :montantImpot then :montant_de_l_impot
              when :revenuFiscalReference then :revenu_fiscal_de_reference
              when :anneeImpots then :annee_d_imposition
              when :anneeRevenus then :annee_des_revenus
              when :erreurCorrectif then :erreur_correctif
              when :situationPartielle then :situation_partielle
              else
                k.to_sym
              end
            end
          end
        end

        def initialize(**kwargs)
          attrs = Mapper.from_api(**kwargs)
          @declarant1 = attrs[:declarant1]
          @declarant2 = attrs[:declarant2]
          @foyer_fiscal = attrs[:foyer_fiscal]
          @date_de_recouvrement = attrs[:date_de_recouvrement]
          @date_d_etablissement = attrs[:date_d_etablissement]
          @nombre_de_parts = attrs[:nombre_de_parts]
          @situation_familiale = attrs[:situation_familiale]
          @nombre_de_personnes_a_charge = attrs[:nombre_de_personnes_a_charge]
          @revenu_brut_global = attrs[:revenu_brut_global]
          @revenu_imposable = attrs[:revenu_imposable]
          @impot_revenu_net_avant_corrections = attrs[:impot_revenu_net_avant_corrections]
          @montant_de_l_impot = attrs[:montant_de_l_impot]
          @revenu_fiscal_de_reference = attrs[:revenu_fiscal_de_reference]
          @annee_d_imposition = attrs[:annee_d_imposition]
          @annee_des_revenus = attrs[:annee_des_revenus]
          @erreur_correctif = attrs[:erreur_correctif]
          @situation_partielle = attrs[:situation_partielle]
        end

        attr_reader :situation_familiale, :erreur_correctif, :situation_partielle

        def declarant1
          Declarant.new(**Hash(@declarant1))
        end

        def declarant1?
          Hash(@declarant1).compact.any?
        end

        def declarant2
          Declarant.new(**Hash(@declarant2))
        end

        def declarant2?
          Hash(@declarant2).compact.any?
        end

        def foyer_fiscal
          FoyerFiscal.new(**Hash(@foyer_fiscal))
        end

        def foyer_fiscal?
          Hash(@foyer_fiscal).compact.any?
        end

        def date_de_recouvrement
          Date.parse(@date_de_recouvrement)
        rescue Date::Error, TypeError
          nil
        end

        def date_d_etablissement
          Date.parse(@date_d_etablissement)
        rescue Date::Error, TypeError
          nil
        end

        def nombre_de_parts
          @nombre_de_parts.to_f
        end

        def nombre_de_parts?
          !@nombre_de_parts.nil?
        end

        def nombre_de_personnes_a_charge
          @nombre_de_personnes_a_charge.to_i
        end

        def nombre_de_personnes_a_charge?
          !@nombre_de_personnes_a_charge.nil?
        end

        def revenu_brut_global
          @revenu_brut_global.to_i
        end

        def revenu_brut_global?
          !@revenu_brut_global.nil?
        end

        def revenu_imposable
          @revenu_imposable.to_i
        end

        def revenu_imposable?
          !@revenu_imposable.nil?
        end

        def impot_revenu_net_avant_corrections
          @impot_revenu_net_avant_corrections.to_i
        end

        def impot_revenu_net_avant_corrections?
          !@impot_revenu_net_avant_corrections.nil?
        end

        def montant_de_l_impot
          @montant_de_l_impot.to_i
        end

        def montant_de_l_impot?
          !@montant_de_l_impot.nil?
        end

        def revenu_fiscal_de_reference
          @revenu_fiscal_de_reference.to_i
        end

        def revenu_fiscal_de_reference?
          !@revenu_fiscal_de_reference.nil?
        end

        def annee_d_imposition
          @annee_d_imposition.to_i
        end

        def annee_d_imposition?
          !@annee_d_imposition.nil?
        end

        def annee_des_revenus
          @annee_des_revenus.to_i
        end

        def annee_des_revenus?
          !@annee_des_revenus.nil?
        end

        def ignore_foyer_fiscal!
          @foyer_fiscal = nil
        end

        def as_json(*)
          super.tap do |avis|
            avis["declarant1"] = declarant1.as_json
            avis["declarant2"] = declarant2.as_json
            avis["foyer_fiscal"] = foyer_fiscal.as_json
          end
        end

        def as_sanitized_json(mask = nil)
          mask ||= {}

          super.tap do |avis|
            avis[:declarant1] = declarant1.as_sanitized_json(mask[:declarant1]) if avis.key?(:declarant1)
            avis[:declarant2] = declarant2.as_sanitized_json(mask[:declarant2]) if avis.key?(:declarant2)
            avis[:foyer_fiscal] = foyer_fiscal.as_sanitized_json(mask[:foyer_fiscal]) if avis.key?(:foyer_fiscal)
          end
        end
      end
    end
  end
end
