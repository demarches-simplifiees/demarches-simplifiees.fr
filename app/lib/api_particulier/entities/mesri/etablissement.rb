# frozen_string_literal: true

require_relative '../sanitizable'

module APIParticulier
  module Entities
    module MESRI
      class Etablissement
        include Sanitizable

        class Mapper
          def self.from_api(**kwargs)
            kwargs.symbolize_keys
          end
        end

        def initialize(**kwargs)
          attrs = Mapper.from_api(**kwargs)
          @uai = attrs[:uai]
          @nom = attrs[:nom]
        end

        attr_reader :uai, :nom
      end
    end
  end
end
