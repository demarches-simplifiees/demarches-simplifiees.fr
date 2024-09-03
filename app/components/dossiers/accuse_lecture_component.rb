# frozen_string_literal: true

class Dossiers::AccuseLectureComponent < ApplicationComponent
  def initialize(dossier:)
    @dossier = dossier
  end
end
