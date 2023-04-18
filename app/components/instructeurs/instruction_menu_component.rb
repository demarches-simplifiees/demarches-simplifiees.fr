# frozen_string_literal: true

class Instructeurs::InstructionMenuComponent < ApplicationComponent
  attr_reader :dossier

  def initialize(dossier:)
    @dossier = dossier
  end

  def render?
    return true if dossier.en_instruction?
    return true if dossier.en_construction? && dossier.may_flag_as_pending_correction?

    false
  end

  def menu_label
    if dossier.en_instruction?
      t(".instruct")
    else
      "Demander une correction"
    end
  end
end
