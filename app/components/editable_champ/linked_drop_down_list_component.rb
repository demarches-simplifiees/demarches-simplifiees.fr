# frozen_string_literal: true

class EditableChamp::LinkedDropDownListComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_champ_container
    :fieldset
  end

  def render?
    @champ.drop_down_options.any?
  end

  private

  def secondary_label
    secondary_label_text + secondary_label_mandatory
  end

  def secondary_label_text
    @champ.drop_down_secondary_libelle.presence || "#{@champ.libelle} : précisez"
  end

  def secondary_label_mandatory
    @champ.mandatory? ? tag.span(' *', class: 'mandatory') : ''
  end
end
