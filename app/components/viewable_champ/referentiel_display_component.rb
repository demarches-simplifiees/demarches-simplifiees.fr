# frozen_string_literal: true

class ViewableChamp::ReferentielDisplayComponent < Referentiels::ReferentielDisplayBaseComponent
  attr_reader :profile

  def initialize(champ:, profile:)
    super(champ:)
    @profile = profile
  end

  def data
    Hash(@champ.value_json&.with_indifferent_access)
      &.dig(data_source)
      &.map { |jsonpath, value| [libelle(jsonpath), format(jsonpath, value), jsonpath] }
      &.reject { |_libelle, value, _jsonpath| value.nil? }
  end

  def data_source
    if profile == 'instructeur'
      :display_instructeur
    else
      :display_usager
    end
  end

  def tooltip_id(jsonpath)
    "#{@champ.input_id}_#{jsonpath.parameterize}_tooltip"
  end
end
