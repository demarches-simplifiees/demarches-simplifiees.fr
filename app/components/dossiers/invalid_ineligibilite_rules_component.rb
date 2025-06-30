# frozen_string_literal: true

class Dossiers::InvalidIneligibiliteRulesComponent < ApplicationComponent
  include ChampHelper
  delegate :can_passer_en_construction?, to: :dossier

  def initialize(dossier:, wrapped: true)
    @dossier = dossier
    @revision = dossier.revision

    @opened = !dossier.can_passer_en_construction?
    @wrapped = wrapped
  end

  private

  attr_reader :dossier

  def render?
    dossier.revision.ineligibilite_enabled?
  end

  def error_message
    dossier.revision.ineligibilite_message
  end

  def opened? = @opened
  def wrapped? = @wrapped
end
