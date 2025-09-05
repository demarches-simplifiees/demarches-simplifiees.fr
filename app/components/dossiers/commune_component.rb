# frozen_string_literal: true

class Dossiers::CommuneComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    render Dossiers::ExternalChampComponent.new(title:, data:, source:)
  end

  private

  def title = champ.to_s

  def data
    [
      ['Code INSEE', champ.code],
      ['Département', champ.departement_code_and_name]
    ].select { |_, value| value.present? }
  end

  def source
    "référentiels géographiques nationaux"
  end
end
