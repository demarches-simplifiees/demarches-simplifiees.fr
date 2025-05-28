# frozen_string_literal: true

class EditableChamp::DossierLinkComponent < EditableChamp::EditableChampBaseComponent
  def select_class_names
    class_names('width-100': contains_long_option?, 'fr-select': true)
  end

  def dsfr_input_classname
    'fr-select'
  end

  def dsfr_champ_container
    render_as_radios? ? :fieldset : :div
  end

  def other_element_class_names
    class_names("fr-fieldset__element" => dsfr_champ_container == :fieldset)
  end

  def select_aria_describedby
    describedby = []
    describedby << @champ.describedby_id if @champ.description.present?
    describedby << @champ.error_id if errors_on_attribute?
    describedby.present? ? describedby.join(' ') : nil
  end
  def dsfr_input_classname
    'fr-input'
  end

  def dossier
    @dossier ||= @champ.blank? ? nil : Dossier.visible_by_administration.find_by(id: @champ.to_s)
  end

  def dossier_options
    dossiers = @champ.procedure.types_de_champ_for_tags.last.procedures.first.dossiers
    dossiers.map do |dossier|
      {
        value: dossier.id.to_s,
        label: dossier.id.to_s
      }
    end
  end

  def react_props
    {
      items: dossier_options,
      placeholder: "Sélectionnez un dossier",
      name: "dossier[champs_public_attributes][#{@champ.public_id}][value]",
      id: @champ.input_id,
      class: "#{@champ.blank? ? '' : 'small-margin'}"
    }
  end
end
