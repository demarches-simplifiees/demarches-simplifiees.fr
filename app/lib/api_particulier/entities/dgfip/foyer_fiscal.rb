# frozen_string_literal: true

require_relative '../sanitizable'

module APIParticulier
  module Entities
    module DGFIP
      class FoyerFiscal
        include Sanitizable

        class Mapper
          def self.from_api(**kwargs)
            kwargs.symbolize_keys
          end
        end

        def initialize(**kwargs)
          attrs = Mapper.from_api(**kwargs)
          @annee = attrs[:annee]
          @adresse = attrs[:adresse]
        end

        attr_reader :adresse

        def annee
          @annee.to_i
        end

        def annee?
          !@annee.nil?
        end
      end
    end
  end
end
