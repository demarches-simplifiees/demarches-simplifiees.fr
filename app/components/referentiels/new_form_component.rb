# frozen_string_literal: true

class Referentiels::NewFormComponent < Referentiels::MappingFormBase
  def id
    :new_referentiel
  end

  def back_url
    champs_admin_procedure_path(@procedure)
  end

  def form_url
    if @referentiel.persisted? && @referentiel.valid?
      admin_procedure_referentiel_path(@procedure, @type_de_champ.stable_id, @referentiel)
    else
      admin_procedure_referentiels_path(@procedure, @type_de_champ.stable_id)
    end
  end

  def form_options
    {
      data: { turbo: 'true' },
      html: { novalidate: 'novalidate', id: }
    }
  end

  def submit_options
    if referentiel.type.nil?
      { class: 'fr-btn', disabled: true }
    else
      { class: 'fr-btn' }
    end
  end
end
