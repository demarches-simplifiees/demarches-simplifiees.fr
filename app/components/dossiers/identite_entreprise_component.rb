# frozen_string_literal: true

class Dossiers::IdentiteEntrepriseComponent < ApplicationComponent
  attr_reader :etablissement, :dossier

  def initialize(champ:)
    @etablissement = champ.etablissement
    @dossier = champ.dossier
  end

  def call
    render Dossiers::ExternalChampComponent.new(title:, data:, details:, source:, details_footer:)
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
      ["Effectif mensuel #{try_format_mois_effectif(etablissement)} de l'établissement (URSSAF ou MSA)", etablissement.entreprise_effectif_mensuel],
      ["Effectif moyen annuel #{etablissement.entreprise_effectif_annuel_annee} de l'unité légale (URSSAF ou MSA)", etablissement.entreprise_effectif_annuel],
      ["Effectif de l'organisation (INSEE)", effectif(etablissement)],
      ["Numéro de TVA intracommunautaire", etablissement.entreprise.numero_tva_intracommunautaire],
      *address,
      ["Capital social", pretty_currency(etablissement.entreprise.capital_social)],
      ["Chiffre d'affaires", chiffre_affaires],
      ['Résultat exercice', extract_from_bilans('resultat_exercice')],
      ['Excédent brut d’exploitation', extract_from_bilans('excedent_brut_exploitation')],
      ['Fonds de roulement net global', extract_from_bilans('fonds_roulement_net_global')],
      ['Besoin en fonds de roulement', extract_from_bilans('besoin_en_fonds_de_roulement')],
      ["Chiffres financiers clés (Banque de France) en #{pretty_currency_unit(etablissement.entreprise_bilans_bdf_monnaie)}", chiffre_cles_bdf, copy: false],
      ['Attestation sociale', link_attestation_sociale, copy: false],
      ['Attestation fiscale', link_attestation_fiscale, copy: false],
      ['Numéro RNA', etablissement.association_rna],
      ['Titre', etablissement.association_titre],
      ['Objet', etablissement.association_objet],
      ['Date de création (association)', try_format_date(etablissement.association_date_creation)],
      ['Date de publication', try_format_date(etablissement.association_date_publication)],
      ['Date de déclaration', try_format_date(etablissement.association_date_declaration)]
    ]
  end

  def chiffre_cles_bdf
    csv, xlsx, ods = ['csv', 'xlsx', 'ods'].map { link_to("au format #{it}", bilan_bdf(it)) }

    safe_join(["Les consulter ", csv, ", ", xlsx, " ou ", ods])
  end

  def link_attestation_sociale
    if etablissement.entreprise_attestation_sociale.attached?
      link_to("Consulter l'attestation", url_for(etablissement.entreprise_attestation_sociale), **external_link_attributes)
    end
  end

  def link_attestation_fiscale
    if etablissement.entreprise_attestation_fiscale.attached?
      link_to("Consulter l'attestation", url_for(etablissement.entreprise_attestation_fiscale), **external_link_attributes)
    end
  end

  def bilan_bdf(format)
    if controller.is_a?(Instructeurs::AvisController)
      bilans_bdf_instructeur_avis_path(@avis, format:)
    else
      dossier_id, procedure_id = @dossier.id, @dossier.procedure.id
      bilans_bdf_instructeur_dossier_path(procedure_id:, dossier_id:, format:)
    end
  end

  def source
    "INSEE, Infogreffe, URSSAF …"
  end

  def chiffre_affaires
    etablissement.exercices
      .map { [it.date_fin_exercice.year, pretty_currency(it.ca)] }
      .then { to_dl(it) }
  end

  def to_dl(array)
    return nil if array.blank?

    dt_dds = array
      .map { |label, value| tag.dt(label, class: 'inline') + tag.dd(value, class: 'inline') }
    dt_dds.last&.concat(tag.span('data-copy-message-placeholder': true))

    tag.dl { dt_dds.map { |it| tag.div(it) }.then { safe_join(it) } }
  end

  def extract_from_bilans(key)
    etablissement.entreprise_bilans_bdf.map do |bilan|
      [
        pretty_date_exercice(year_for_bilan(bilan)),
        pretty_currency(
          value_for_bilan_key(bilan, key),
          unit: pretty_currency_unit(etablissement.entreprise_bilans_bdf_monnaie)
        )
      ]
    end.then { |it| to_dl(it) }
  end

  def address
    scope = "activemodel.attributes.normalized_address"
    address = AddressProxy.new(etablissement)

    [
      [t("full_address", scope:), full_address(address)],
      [t("city_code", scope:), address.city_code],
      [t("postal_code", scope:), address.postal_code],
      [t("department", scope:), address.departement_name],
      [t("region", scope:), address.region_name]
    ]
  end

  def details_footer = Dossiers::AnnuaireEntrepriseLinkComponent.new(siret: etablissement.siret)

  def full_address(proxy)
    safe_join([
      proxy.street_address,
      [proxy.city_name, proxy.postal_code].join(" ")
    ], tag.br)
  end

  delegate :pretty_siret, :raison_sociale_or_name, :try_format_date, :try_format_mois_effectif,
    :effectif, :pretty_currency, :sanitize, :pretty_date_exercice, :year_for_bilan, :value_for_bilan_key,
    :pretty_currency_unit, :external_link_attributes, to: :helpers
end
