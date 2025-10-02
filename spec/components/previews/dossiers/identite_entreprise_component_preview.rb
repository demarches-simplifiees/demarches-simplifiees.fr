# frozen_string_literal: true

class Dossiers::IdentiteEntrepriseComponentPreview < ViewComponent::Preview
  include Dossiers::FakeEtablissementConcern

  def default
    champ = Champs::SiretChamp.new(etablissement:, dossier:)

    render_with_template(
      template: 'dossiers/external_champ_component_preview/default',
      locals: {
        component: Dossiers::IdentiteEntrepriseComponent.new(champ:)
      }
    )
  end

  private

  def dossier
    Dossier.new(id: 1, procedure: Procedure.new(id: 1))
  end
end
