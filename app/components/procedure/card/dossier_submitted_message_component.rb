# frozen_string_literal: true

class Procedure::Card::DossierSubmittedMessageComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
