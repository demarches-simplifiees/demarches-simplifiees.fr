# frozen_string_literal: true

class EditableChamp::LinkedDropDownListComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_champ_container
    :fieldset
  end

  def render?
    @champ.drop_down_options.any?
  end

  def select_options
    @champ.mandatory? ? { prompt: t('views.components.select_list') } : { include_blank: t('views.components.select_list') }
  end
end
