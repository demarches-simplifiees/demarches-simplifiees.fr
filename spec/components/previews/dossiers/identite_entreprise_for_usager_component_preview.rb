# frozen_string_literal: true

class Dossiers::IdentiteEntrepriseForUsagerComponentPreview < ViewComponent::Preview
  include Dossiers::FakeEtablissementConcern

  def default
    render_with_template(
      template: 'dossiers/external_champ_component_preview/default',
      locals: {
        component: Dossiers::IdentiteEntrepriseForUsagerComponent.new(etablissement:)
      }
    )
  end

  def confidential
    et = etablissement
    et.diffusable_commercialement = false
    render_with_template(
      template: 'dossiers/external_champ_component_preview/default',
      locals: {
        component: Dossiers::IdentiteEntrepriseForUsagerComponent.new(etablissement: et)
      }
    )
  end

  private

  def dossier
    Dossier.new(id: 1, procedure: Procedure.new(id: 1))
  end
end
