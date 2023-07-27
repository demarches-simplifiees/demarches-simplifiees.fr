class EditableChamp::EditableChampBaseComponent < ApplicationComponent
  include Dsfr::InputErrorable

  def initialize(form:, champ:, seen_at: nil, opts: {})
    @form, @champ, @seen_at, @opts = form, champ, seen_at, opts
    @attribute = :value
  end
end
