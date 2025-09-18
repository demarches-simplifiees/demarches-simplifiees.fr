# frozen_string_literal: true

class Dossiers::EpciComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    render Dossiers::ExternalChampComponent.new(data:, source:)
  end

  private

  def data
    [
      ['EPCI', name],
      ['Département', champ.departement_code_and_name],
      ['Code région', champ.code_region]
    ]
  end

  def name
    if champ.code?
      "#{champ.code} - #{champ}"
    else
      champ.to_s
    end
  end

  def source = tag.span("référentiels géographiques nationaux")
end
