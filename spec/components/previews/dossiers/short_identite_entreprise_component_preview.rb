# frozen_string_literal: true

class Dossiers::ShortIdentiteEntrepriseComponentPreview < ViewComponent::Preview
  include Dossiers::FakeEtablissementConcern

  def default
    render Dossiers::ShortIdentiteEntrepriseComponent.new(etablissement:)
  end

  def non_diffusable
    et = etablissement
    et.diffusable_commercialement = false
    render Dossiers::ShortIdentiteEntrepriseComponent.new(etablissement: et)
  end
end
