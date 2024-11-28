# frozen_string_literal: true

class Instructeurs::ProposeRdvMenuComponent < ApplicationComponent
  include Turbo::FramesHelper

  def initialize(dossier:)
    @dossier = dossier
  end
end
