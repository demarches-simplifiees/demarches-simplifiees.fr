# frozen_string_literal: true

class Dossiers::CommuneComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    render Dossiers::ExternalChampComponent.new(data:, source:)
  end

  def self.data_labels
    [
      t('.municipality'),
      t('.insee_code'),
      t('.department'),
    ]
  end

  private

  def data
    [
      [t('.municipality'), champ.to_s],
      [t('.insee_code'), champ.code],
      [t('.department'), champ.departement_code_and_name],
    ]
  end

  def source
    "référentiels géographiques nationaux"
  end
end
