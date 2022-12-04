class Dossier::SendDecisionToExpertsJob < EventHandlerJob
  def perform(event)
    avis_experts_procedures_ids = dossier
      .avis
      .joins(:experts_procedure)
      .where(experts_procedures: { allow_decision_access: true })
      .with_answer
      .distinct
      .pluck('avis.id, experts_procedures.id')

    # rubocop:disable Lint/UnusedBlockArgument
    avis = avis_experts_procedures_ids
      .uniq { |(avis_id, experts_procedures_id)| experts_procedures_id }
      .map { |(avis_id, _)| avis_id }
      .then { |avis_ids| Avis.find(avis_ids) }
    # rubocop:enable Lint/UnusedBlockArgument

    avis.each { |a| ExpertMailer.send_dossier_decision_v2(a).deliver_later }
  end
end
