# frozen_string_literal: true

class Dossiers::AttestationStatusComponent < ApplicationComponent
  attr_reader :dossier

  def initialize(dossier:)
    @dossier = dossier
  end

  private

  def render?
    return true if attestation.present?

    (dossier.accepte? || dossier.refuse?) && template_available?
  end

  def attestation
    dossier.attestation
  end

  def attestation_template
    @attestation_template ||= if dossier.accepte?
      dossier.procedure.attestation_acceptation_template
    elsif dossier.refuse?
      dossier.procedure.attestation_refus_template
    end
  end

  def template_available?
    return false if attestation_template.blank?
    return false unless attestation_template.activated?

    # Template must have been published before dossier was processed
    attestation_template.updated_at <= dossier.processed_at
  end
end
