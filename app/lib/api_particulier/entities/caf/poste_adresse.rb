# frozen_string_literal: true

require_relative '../sanitizable'

module APIParticulier
  module Entities
    module CAF
      class PosteAdresse
        include Sanitizable

        class Mapper
          def self.from_api(**kwargs)
            kwargs.transform_keys do |k|
              case k.to_sym
              when :complementIdentite then :complement_d_identite
              when :complementIdentiteGeo then :complement_d_identite_geo
              when :numeroRue then :numero_et_rue
              when :lieuDit then :lieu_dit
              when :codePostalVille then :code_postal_et_ville
              else
                k.to_sym
              end
            end
          end
        end

        def initialize(**kwargs)
          attrs = Mapper.from_api(**kwargs)
          @identite = attrs[:identite]
          @complement_d_identite = attrs[:complement_d_identite]
          @complement_d_identite_geo = attrs[:complement_d_identite_geo]
          @numero_et_rue = attrs[:numero_et_rue]
          @lieu_dit = attrs[:lieu_dit]
          @code_postal_et_ville = attrs[:code_postal_et_ville]
          @pays = attrs[:pays]
        end

        attr_reader :identite, :complement_d_identite, :complement_d_identite_geo, :numero_et_rue, :lieu_dit,
                    :code_postal_et_ville, :pays
      end
    end
  end
end
