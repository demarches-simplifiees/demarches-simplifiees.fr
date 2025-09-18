# frozen_string_literal: true

class Dossiers::DepartementComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    render Dossiers::ExternalChampComponent.new(data:, source:)
  end

  private

  def data
    [['Département', champ.to_s], ['Code région', champ.code_region]]
  end

  def source = "référentiels géographiques nationaux"
end
