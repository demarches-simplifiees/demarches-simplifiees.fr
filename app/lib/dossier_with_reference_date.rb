# frozen_string_literal: true

class DossierWithReferenceDate
  def self.assign(dossier, state: nil, reference_date: nil)
    created_at = reference_date.presence || default_created_at(dossier)

    case (state || dossier.state)
    when Dossier.states.fetch(:en_construction)
      dossier.created_at = created_at
      dossier.en_construction_at ||= created_at + 1.minute
      dossier.depose_at ||= dossier.en_construction_at
    when Dossier.states.fetch(:en_instruction)
      assign(dossier, state: Dossier.states.fetch(:en_construction), reference_date: created_at)
      dossier.en_instruction_at ||= created_at + 2.minutes
    when Dossier.states.fetch(:accepte), Dossier.states.fetch(:refuse), Dossier.states.fetch(:sans_suite)
      assign(dossier, state: Dossier.states.fetch(:en_instruction), reference_date: created_at)
      dossier.processed_at ||= created_at + 3.minutes
    end
  end

  def self.default_created_at(dossier)
    reference_date, delta = case dossier.state
    when Dossier.states.fetch(:en_construction)
      [dossier.depose_at || dossier.en_construction_at, 1.minute]
    when Dossier.states.fetch(:en_instruction)
      [dossier.en_instruction_at, 2.minutes]
    when Dossier.states.fetch(:accepte), Dossier.states.fetch(:refuse), Dossier.states.fetch(:sans_suite)
      [dossier.processed_at, 3.minutes]
    end
    if reference_date.present?
      reference_date - delta
    else
      10.minutes.ago
    end
  end
end
