class Procedure::Card::AttestationComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  private

  def error_messages
    @procedure.errors.messages_for(:attestation_template).to_sentence
  end
end
