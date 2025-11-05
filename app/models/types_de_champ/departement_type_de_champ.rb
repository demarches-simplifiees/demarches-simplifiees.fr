# frozen_string_literal: true

class TypesDeChamp::DepartementTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def filter_to_human(filter_value)
    APIGeoService.departement_name(filter_value).presence || filter_value
  end

  def champ_value(champ)
    "#{champ.code} – #{champ.name}"
  end

  def champ_value_for_export(champ, path = :value)
    case path
    when :code
      champ.code
    when :value
      champ.name
    end
  end

  def champ_value_for_tag(champ, path = :value)
    case path
    when :code
      champ.code
    when :value
      champ_value(champ)
    end
  end

  def champ_value_for_api(champ, version: 2)
    case version
    when 2
      champ_value(champ).tr('–', '-')
    else
      champ_value(champ)
    end
  end

  private

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Code)",
      description: "#{description} (Code)",
      path: :code,
      maybe_null: public? && !mandatory?,
    })
    paths
  end
end
