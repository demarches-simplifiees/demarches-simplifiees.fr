# frozen_string_literal: true

class ViewableChamp::ReferentielDisplayComponent < Referentiels::ReferentielDisplayBaseComponent
  attr_reader :profile

  def initialize(champ:, profile:)
    super(champ:)
    @profile = profile
  end

  def data
    data_source.filter_map do |jsonpath, _mapping|
      value = format(jsonpath, safe_value_json.dig(jsonpath))
      [libelle(jsonpath), value, jsonpath] if !value.nil?
    end
  end

  def data_source
    if profile == 'instructeur'
      referentiel_mapping_displayable_for_instructeur
    else
      referentiel_mapping_displayable_for_usager
    end
  end

  def tooltip_id(jsonpath)
    "#{@champ.focusable_input_id}_#{jsonpath.parameterize}_tooltip"
  end
end
