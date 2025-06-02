# frozen_string_literal: true

class TypesDeChamp::TeFenuaTypeDeChamp < TypesDeChamp::TypeDeChampBase
  LAYERS = [:parcelles, :zones_manuelles] # , :batiments

  class << self
    def champ_value_for_api(champ, version = 2)
      nil
    end

    def champ_value_for_export(champ, path = :value)
      champ.geo_json_from_value&.map do |k, v|
        case k
        when :parcelles
          for_each_feature(v) { |_f, p| "Parcelle n°#{p[:sec_parcelle]} - #{p[:surface_adop]} m2 - #{p[:terre]} à #{p[:commune]} (#{p[:ile]})" }
        when :zones_manuelles
          for_each_feature(v) { |f, p| "#{f[:id]} à #{p[:commune]} (#{p[:ile]})" }
        end
      end&.join("\r\n")
    end

    def for_each_feature(value)
      value[:features].map do |f|
        yield f, f[:properties]
      end.join("\r\n")
    end
  end
end
