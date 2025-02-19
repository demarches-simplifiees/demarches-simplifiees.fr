# frozen_string_literal: true

class Instructeurs::ScheduleRdvButtonComponent < ApplicationComponent
  def initialize(dossier:)
    @dossier = dossier
  end
end
