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

  def dossier_options_for(champ)
    type_champ = champ.type_de_champ
    return [] unless type_champ

    options = []

    type_champ.procedures.each do |procedure|
      dossiers = procedure.dossiers.select do |dossier|
        dossier.user == current_user && !%w[brouillon supprimés].include?(dossier.state)
      end
      next if dossiers.empty?

      options << {
        value: "separator_#{procedure.id}",
        label: "-- Démarche : #{procedure.libelle} --"
      }

      options.concat(dossiers.map do |dossier|
        {
          value: dossier.id.to_s,
          label: "N° #{dossier.id} - déposé le #{dossier.depose_at.strftime('%d/%m/%Y')}"
        }
      end)
    end

    options
  end




  def react_props
    {
      items: dossier_options_for(@champ),
      placeholder: "Sélectionnez un dossier",
      name: "dossier[champs_public_attributes][#{@champ.public_id}][value]",
      id: @champ.input_id,
      class: "#{@champ.blank? ? '' : 'small-margin'}",
        
    }
  end

  private

  def before_render_dossiers
    type_champ = @champ.type_de_champ
    return [] unless type_champ

    type_champ.procedures.flat_map(&:dossiers).select do |dossier|
      !%w[brouillon supprimés].include?(dossier.state) && dossier.user == @current_user
    end

  end

  def render_as_radios?
    before_render_dossiers.size <= 5
  end

  def render_as_combobox?
    before_render_dossiers.size >= 20
  end

  def contains_long_option?
    max_length = 100
    dossier_options_for(@champ).any? { |option| option[:label].size > max_length }
  end

  def before_render
    @current_user = current_user
    @filtered_dossiers = before_render_dossiers
  end
end
