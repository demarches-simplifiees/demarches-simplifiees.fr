# frozen_string_literal: true

class Procedure::Card::AttestationRefusComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  private

  def edit_attestation_refus_path
    if @procedure.attestation_refus_template&.version == 1
      helpers.edit_admin_procedure_attestation_refus_template_path(@procedure)
    else
      helpers.edit_admin_procedure_attestation_refus_template_v2_path(@procedure)
    end
  end

  def error_messages
    @procedure.errors.messages_for(:attestation_refus_template).to_sentence
  end
end