# frozen_string_literal: true

class Dossiers::DegradedIdentiteEntrepriseComponent < ApplicationComponent
  attr_reader :etablissement, :profile

  def initialize(etablissement:, profile:)
    @etablissement = etablissement
    @profile = profile
  end

  def call
    source = 'Annuaire des Entreprises'
    header = safe_join([
      render(insee_down),
      render(Dossiers::AnnuaireEntrepriseLinkComponent.new(
        siret: etablissement.siret,
        extra_class_names: 'pull-left'
      ))
    ])

    render Dossiers::ExternalChampComponent.new(source:)
      .tap { it.with_header { header } }
  end

  def insee_down
    texts = [t('.insee_down')]
    texts << t('.dossier_blocked') if profile == 'instructeur'

    Dsfr::AlertComponent.new(state: :warning, size: :sm, extra_class_names: 'fr-mb-2w pull-left width-100').tap do
      it.with_body { safe_join(texts, tag.br) }
    end
  end
end
