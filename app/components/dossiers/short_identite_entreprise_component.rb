# frozen_string_literal: true

class Dossiers::ShortIdentiteEntrepriseComponent < ApplicationComponent
  attr_reader :etablissement

  def initialize(etablissement:)
    @etablissement = etablissement
  end

  private

  def label(k, opt = {}) = etablissement.class.human_attribute_name(k, opt)

  delegate :pretty_siret, :raison_sociale_or_name, to: :helpers
end
