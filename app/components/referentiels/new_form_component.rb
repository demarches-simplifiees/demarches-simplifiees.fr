# frozen_string_literal: true

class Referentiels::NewFormComponent < ApplicationComponent
  attr_reader :referentiel, :type_de_champ, :procedure
  def initialize(referentiel:, type_de_champ:, procedure:)
    @referentiel = referentiel
    @type_de_champ = type_de_champ
    @procedure = procedure
  end

  def id
    :new_referentiel
  end

  def back_url
    champs_admin_procedure_path(@procedure)
  end

  def form_url
    admin_procedure_referentiels_path(@procedure, @type_de_champ.stable_id)
  end

  def form_options
    {
      method: :post,
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
