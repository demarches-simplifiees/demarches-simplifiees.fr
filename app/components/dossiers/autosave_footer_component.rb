# frozen_string_literal: true

class Dossiers::AutosaveFooterComponent < ApplicationComponent
  include ApplicationHelper
  attr_reader :dossier

  def initialize(dossier:, annotation:)
    @dossier = dossier
    @annotation = annotation
  end

  private

  def annotation?
    @annotation
  end
end
