# frozen_string_literal: true

class Dossiers::AutosaveFooterComponent < ApplicationComponent
  include ApplicationHelper
  attr_reader :dossier

  def initialize(dossier:, annotation:, owner:)
    @dossier = dossier
    @annotation = annotation
    @owner = owner
  end

  private

  def annotation?
    @annotation
  end

  def owner?
    @owner
  end
end
