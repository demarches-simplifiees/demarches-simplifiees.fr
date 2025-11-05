# frozen_string_literal: true

class Dossiers::CommuneComponent < ApplicationComponent
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
      ['Commune', champ.to_s],
      ['Code INSEE', champ.code],
      ['Département', champ.departement_code_and_name],
    ]
  end

  def source
    "référentiels géographiques nationaux"
  end
end
