# frozen_string_literal: true

class Dossiers::RNFComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    if champ.value.blank?
      tag.p(t('not_filled', scope: 'activerecord.attributes.type_de_champ'), class: "fr-mt-1w")
    elsif champ.data.blank?
      tag.p(t('not_found', rnf: champ.value, scope: 'activerecord.errors.models.champs/rnf_champ.attributes.value'), class: "fr-mt-1w")
    else
      render Dossiers::ExternalChampComponent.new(data:, details:, source:)
    end
  end

  private

  def data
    [
      [label(:rnf_id), champ.to_s],
      *['title', 'email'].map { [label(it), champ.data[it]] },
    ]
  end

  def details
    [
      *['phone', 'status'].map { [label(it), champ.data[it]] },
      *['createdAt', 'updatedAt', 'dissolvedAt'].map { [label(it), champ.data[it]&.to_date] },
      *helpers.address_array(champ),
    ]
  end

  def label(key) = champ.class.human_attribute_name(key)

  def source
    tag.acronym("RNF", title: "Répertoire National des Fondations")
  end
end
