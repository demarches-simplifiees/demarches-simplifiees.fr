# frozen_string_literal: true

class Dossiers::IdentiteEntrepriseForUsagerComponent < ApplicationComponent
  attr_reader :etablissement

  def initialize(etablissement:)
    @etablissement = etablissement
  end

  def call
    if etablissement.diffusable_commercialement
      render Dossiers::ExternalChampComponent.new(data:, details:, source:, details_footer:)
    else
      c = Dossiers::ExternalChampComponent.new(source: 'Annuaire des Entreprises')
      c.with_header do
        safe_join([
          tag.p(warning_for_private_info),
          render(Dossiers::AnnuaireEntrepriseLinkComponent.new(siret: etablissement.siret))
        ])
      end
      render c
    end
  end

  private

  def data
    [
      [label('.siret'), pretty_siret(etablissement.siret), data_to_copy: etablissement.siret],
      [label('.denomination'), raison_sociale_or_name(etablissement)],
      [label('.forme_juridique'), sanitize(etablissement.entreprise.forme_juridique)]
    ]
  end

  def details
    [
      [label('.siret_siege_social'), pretty_siret(etablissement.dedicated_siret_siege_social)],
      [label('.libelle_naf'), etablissement.libelle_naf],
      [label('.code_naf'), etablissement.naf],
      [label('.date_creation'), render(Dossiers::FormattedDateWithBadgeComponent.new(etablissement:))],
      [label('.chiffre_affaires'), chiffre_affaires],
      [label('.bilan_bdf'), bilans_bdf],
      [label('.numero_rna'), etablissement.association_rna],
      [label('.titre'), etablissement.association_titre],
      [label('.objet'), etablissement.association_objet],
      [label('.date_creation_association'), try_format_date(etablissement.association_date_creation)],
      [label('.date_publication'), try_format_date(etablissement.association_date_publication)],
      [label('.date_declaration'), try_format_date(etablissement.association_date_declaration)]
    ]
  end

  def details_footer = Dossiers::AnnuaireEntrepriseLinkComponent.new(siret: etablissement.siret)

  def source = "INSEE, Infogreffe, URSSAF"

  def chiffre_affaires
    if etablissement.exercices.present?
      t('activemodel.models.exercices_summary', count: etablissement.exercices.count)
    end
  end

  def warning_for_private_info
    t('warning_for_private_info', scope: 'views.shared.dossiers.identite_entreprise', siret: pretty_siret(etablissement.siret))
  end

  def bilans_bdf
    t('.bilans_bdf') if etablissement.entreprise_bilans_bdf.present?
  end

  def label(k, opt = {}) = etablissement.class.human_attribute_name(k, opt)

  delegate :pretty_siret, :raison_sociale_or_name, :try_format_date,
           :sanitize, to: :helpers
end
