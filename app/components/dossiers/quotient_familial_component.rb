# frozen_string_literal: true

class Dossiers::QuotientFamilialComponent < ApplicationComponent
  delegate :type_de_champ, :correct_qf_data?, :incorrect_qf_data?, to: :@champ
  delegate :substitution_champ, to: :type_de_champ

  attr_reader :champ, :profile

  def initialize(champ:, profile:)
    @champ = champ
    @profile = profile
  end

  def call
    safe_join([
      notice,
      champ_content
    ])

  end

  private

  def notice
    if profile == 'instructeur'
      render Dsfr::NoticeComponent.new(
        closable: false,
        data_attributes: { "data-notice-name" => "info-recuperation-donnees-qf" }
      ) do |c|
        c.with_desc do
          description
        end
      end
    end
  end

  def description
    if correct_qf_data?
      t(".correct_qf_data")
    elsif incorrect_qf_data?
      t(".incorrect_qf_data")
    else
      t(".not_recovered_qf_data")
    end
  end

  def champ_content
    if correct_qf_data?
      render Dossiers::ExternalChampComponent.new(data:, source:)
    else
      # TODO: refacto un ViewableChamp::SectionComponent
      render partial: "shared/champs/piece_justificative/show", locals: { champ: substitution_champ(champ), profile: }
    end
  end

  def data
    return [] unless champ.data.is_a?(Hash)

    qf = champ.data["quotient_familial"]
    allocataire = champ.data["allocataires"]&.first
    adresse = champ.data["adresse"]

    rows = []

    if qf.present?
      rows << [
        "Quotient familial #{qf['fournisseur']}",
        number_with_delimiter(qf["valeur"], delimiter: " ")
      ]

      rows << [
        "Période du quotient",
        format("%02d/%d", qf["mois"], qf["annee"])
      ]
    end

    if allocataire.present?
      rows << [
        "Allocataire",
        full_name(allocataire)
      ]

      rows << [
        "Date de naissance",
        I18n.l(Date.parse(allocataire["date_naissance"]))
      ]
    end

    if adresse.present?
      rows << [
        "Adresse",
        format_adresse(adresse),
      ]
    end

    rows
  end

  def source
    tag.acronym("API Particulier v3")
  end

  def full_name(allocataire)
    [
      allocataire["prenoms"],
      allocataire["nom_usage"] || allocataire["nom_naissance"]
    ].compact.join(" ").titleize
  end

  def format_adresse(adresse)
    [
      adresse["numero_libelle_voie"],
      adresse["code_postal_ville"],
      adresse["pays"]
    ].compact.join(", ")
  end
end
