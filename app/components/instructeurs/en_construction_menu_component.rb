# frozen_string_literal: true

class Instructeurs::EnConstructionMenuComponent < ApplicationComponent
  attr_reader :dossier

  def initialize(dossier:)
    @dossier = dossier
  end

  def render?
    return true if dossier.may_repasser_en_construction?
    return true if dossier.may_flag_as_pending_correction?

    false
  end

  def menu_label
    if dossier.en_construction?
      t('.request_correction')
    else
      t(".revert_en_construction")
    end
  end
end
