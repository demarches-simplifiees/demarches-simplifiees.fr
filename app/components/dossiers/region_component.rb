# frozen_string_literal: true

class Dossiers::RegionComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    render Dossiers::ExternalChampComponent.new(data:, source:)
  end

  private

  def data
    [['Région', champ.name], ['Code INSEE', champ.code]]
  end

  def source = "référentiels géographiques nationaux"
end
