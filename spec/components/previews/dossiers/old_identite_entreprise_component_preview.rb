# frozen_string_literal: true

class Dossiers::OldIdentiteEntrepriseComponentPreview < ViewComponent::Preview
  include Dossiers::FakeEtablissementConcern

  def nominal
    champ = Champs::SiretChamp.new(etablissement:)
    profile = 'instructeur'

    render_with_template(
      template: 'dossiers/old_identite_entreprise_component_preview',
      locals: { champ:, profile:, dossier: }
    )
  end

  def degraded_mode
    et = etablissement
    et.adresse = nil # enable degraded mode
    champ = Champs::SiretChamp.new(etablissement: et)
    profile = 'instructeur'

    render_with_template(
      template: 'dossiers/old_identite_entreprise_component_preview',
      locals: { champ:, profile:, dossier: }
    )
  end

  def confidential
    et = etablissement
    et.diffusable_commercialement = false
    champ = Champs::SiretChamp.new(etablissement: et)
    profile = 'usager'

    render_with_template(
      template: 'dossiers/old_identite_entreprise_component_preview',
      locals: { champ:, profile:, dossier: }
    )
  end

  def usager
    champ = Champs::SiretChamp.new(etablissement:)
    profile = 'usager'

    render_with_template(
      template: 'dossiers/old_identite_entreprise_component_preview',
      locals: { champ:, profile:, dossier: }
    )
  end

  AttachmentData = Data.define(:attached?, :url)
  ModelData = Data.define(:model_name, :id, :persisted?)

  private

  def dossier
    Dossier.new(id: 1, procedure: Procedure.new(id: 1))
  end
end
