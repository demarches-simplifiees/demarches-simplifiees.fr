# frozen_string_literal: true

class EditableChamp::SiretComponent < EditableChamp::EditableChampBaseComponent
  include EtablissementHelper

  def initialize(form:, champ:, seen_at: nil, opts: {})
    super
    @attribute = :external_id
  end

  def dsfr_input_classname
    'fr-input'
  end

  def hint_id
    dom_id(@champ, :siret_info)
  end

  def hintable?
    true
  end
end
