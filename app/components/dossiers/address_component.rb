# frozen_string_literal: true

class Dossiers::AddressComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    if champ.full_address? && champ.france?
      render Dossiers::ExternalChampComponent.new(data:, source:)
    else
      no_ban_address
    end
  end

  private

  def no_ban_address
    safe_join([
      tag.p(class: 'fr-mb-1w copy-zone', role: 'button') { champ.to_s },
      tag.p(class: 'champ-label') { 'Pays' },
      tag.p(class: 'champ-content copy-zone') { champ.country_name }
    ])
  end

  def data
    [
      ['Adresse', champ.to_s],
      ['Code INSEE', champ.city_code],
      ['Département', champ.departement_code_and_name]
    ]
  end

  def source
    tag.acronym(title: 'Base Adresse Nationale') { 'BAN' } if champ.ban?
  end
end
