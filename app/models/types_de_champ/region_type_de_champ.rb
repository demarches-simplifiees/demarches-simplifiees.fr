# frozen_string_literal: true

class TypesDeChamp::RegionTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def filter_to_human(filter_value)
    APIGeoService.region_name(filter_value).presence || filter_value
  end

  class << self
    def champ_value(champ)
      champ.name
    end

    def champ_value_for_export(champ, path = :value)
      case path
      when :value
        champ_value(champ)
      when :code
        champ.code
      end
    end

    def champ_value_for_tag(champ, path = :value)
      case path
      when :value
        champ_value(champ)
      when :code
        champ.code
      end
    end
  end

  private

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Code)",
      description: "#{description} (Code)",
      path: :code,
      maybe_null: public? && !mandatory?
    })
    paths
  end
end
