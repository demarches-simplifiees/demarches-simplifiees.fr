# frozen_string_literal: true

class Instructeurs::DossierTraitementsComponent < ApplicationComponent
  attr_reader :traitements

  def initialize(traitements:)
    @traitements = traitements
  end
end
