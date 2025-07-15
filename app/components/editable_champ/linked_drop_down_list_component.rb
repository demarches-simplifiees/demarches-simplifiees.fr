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

  private

  def secondary_label
    secondary_label_text + secondary_label_mandatory
  end

  def secondary_label_text
    @champ.drop_down_secondary_libelle.presence || "Valeur secondaire dépendant de la première"
  end

  def secondary_label_mandatory
    @champ.mandatory? ? tag.span(' *', class: 'mandatory') : ''
  end
end
