# frozen_string_literal: true

module Maintenance
  class T20251017destroyAttestationTemplatesV1WhenV2PublishedTask < MaintenanceTasks::Task
    # Documentation: cette tâche modifie les données car certaines démarches ont à la fois
    # une attestation_template v2 et une v1. Normalement la v1 est supprimée lors de la publication de la v2.

    def collection
      Procedure.joins(:attestation_templates)
        .where(id: AttestationTemplate.select(:procedure_id).where(version: 2, state: 'published'))
        .where(id: AttestationTemplate.select(:procedure_id).where(version: 1))
        .distinct
        .pluck(:id)
    end

    def process(procedure_id)
      templates_v1 = AttestationTemplate.where(procedure_id: procedure_id, version: 1)
      templates_v1.destroy_all
    end
  end
end
