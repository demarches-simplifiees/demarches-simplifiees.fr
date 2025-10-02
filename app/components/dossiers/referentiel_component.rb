# frozen_string_literal: true

class Dossiers::ReferentielComponent < Referentiels::ReferentielDisplayBaseComponent
  attr_reader :champ, :profile

  def initialize(champ:, profile:)
    @champ = champ
    @profile = profile
  end

  def call
    render Dossiers::ExternalChampComponent.new(data:, source:)
  end

  private

  def data
    [['Identifiant', champ.to_s]] +
    data_source.filter_map do |jsonpath, _mapping|
      value = format(jsonpath, safe_value_json.dig(jsonpath))
      [libelle(jsonpath), value]
    end
  end

  def data_source
    if profile == 'instructeur'
      referentiel_mapping_displayable_for_instructeur
    else
      referentiel_mapping_displayable_for_usager
    end
  end

  def source
    tag.acronym("Référentiel Externe")
  end
end
