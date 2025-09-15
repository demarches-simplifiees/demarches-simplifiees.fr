# frozen_string_literal: true

class Dossiers::RNAComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    if champ.value.blank?
      tag.p(t('not_filled', scope: 'activerecord.attributes.type_de_champ'), class: "fr-mt-1w")
    elsif champ.data.blank?
      tag.p(t('not_found', value: champ.value, scope: 'activerecord.errors.models.champs/rna_champ.attributes.value'), class: "fr-mt-1w")
    else
      render Dossiers::ExternalChampComponent.new(data:, details:, source:)
    end
  end

  private

  def data
    [
      [champ.class.human_attribute_name(:value), champ.to_s],
      *['titre', 'objet'].map { label_value(it) }
    ]
  end

  def details
    [
      *['date_creation', 'date_declaration', 'date_publication'].map { label_value(it) },
      *helpers.address_array(champ)
    ]
  end

  def label_value(key)
    [champ.class.human_attribute_name("association_#{key}"), champ.data["association_#{key}"]]
  end

  def source
    tag.acronym("RNA", title: "Répertoire National des Associations")
  end
end
