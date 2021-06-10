# frozen_string_literal: true

require_relative '../sanitizable'

module APIParticulier
  module Entities
    module CAF
      class QuotientFamilial
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
          @quotient_familial = attrs[:quotient_familial]
          @annee = attrs[:annee]
          @mois = attrs[:mois]
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
      end
    end
  end
end
