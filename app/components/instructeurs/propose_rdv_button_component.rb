# frozen_string_literal: true

class Instructeurs::ProposeRdvButtonComponent < ApplicationComponent
  def initialize(dossier:)
    @dossier = dossier
  end
end
