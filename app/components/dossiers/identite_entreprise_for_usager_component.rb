# frozen_string_literal: true

class Dossiers::IdentiteEntrepriseForUsagerComponent < ApplicationComponent
  attr_reader :etablissement

  def initialize(etablissement:)
    @etablissement = etablissement
  end

  def call
    if etablissement.diffusable_commercialement
      render Dossiers::ExternalChampComponent.new(title:, data:, details:, source:, details_footer:)
    else
      c = Dossiers::ExternalChampComponent.new(title:, source: 'Annuaire des Entreprises')
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

  def title = pretty_siret(etablissement.siret)

  def data
    [
      ['Dénomination', raison_sociale_or_name(etablissement)],
      ['SIRET', pretty_siret(etablissement.siret)],
      ['Forme juridique', sanitize(etablissement.entreprise.forme_juridique)]
    ]
  end

  def details
    [
      ['SIRET du siège social', pretty_siret(etablissement.dedicated_siret_siege_social)],
      ['Libellé NAF', etablissement.libelle_naf],
      ['Code NAF', etablissement.naf],
      ['Date de création', render(Dossiers::FormattedDateWithBadgeComponent.new(etablissement:))],
      ['Chiffre d’affaires', chiffre_affaires],
      ['Bilans Banque de France', bilans_bdf],
      ['Numéro RNA', etablissement.association_rna],
      ['Titre', etablissement.association_titre],
      ['Objet', etablissement.association_objet],
      ['Date de création (association)', try_format_date(etablissement.association_date_creation)],
      ['Date de publication', try_format_date(etablissement.association_date_publication)],
      ['Date de déclaration', try_format_date(etablissement.association_date_declaration)]
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
    "Les 3 derniers bilans connus de votre entreprise par la Banque de France ont été joints à votre dossier."
  end

  delegate :pretty_siret, :raison_sociale_or_name, :try_format_date,
           :sanitize, to: :helpers
end
