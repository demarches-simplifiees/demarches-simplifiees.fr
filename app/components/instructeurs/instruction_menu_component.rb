# frozen_string_literal: true

class Instructeurs::InstructionMenuComponent < ApplicationComponent
  attr_reader :dossier

  def initialize(dossier:)
    @dossier = dossier
  end

  def render?
    dossier.en_instruction?
  end

  def menu_label
    t(".instruct")
  end
end
