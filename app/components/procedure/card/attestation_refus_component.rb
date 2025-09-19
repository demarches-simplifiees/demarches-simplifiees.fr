# frozen_string_literal: true

class Procedure::Card::AttestationRefusComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  private

  def error_messages
    @procedure.errors.messages_for(:attestation_refus_template).to_sentence
  end
end
