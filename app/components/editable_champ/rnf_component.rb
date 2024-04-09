class EditableChamp::RNFComponent < EditableChamp::EditableChampBaseComponent
  def initialize(form:, champ:, seen_at: nil, opts: {})
    @form, @champ, @seen_at, @opts = form, champ, seen_at, opts
    @attribute = :value
  end

  def dsfr_input_classname
    'fr-input'
    end
end
