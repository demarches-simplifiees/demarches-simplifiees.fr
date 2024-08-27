# frozen_string_literal: true

module Maintenance::Ignored
  class DeleteDraftRevisionTypeDeChampsTask < MaintenanceTasks::Task
    csv_collection

    # See UpdateDraftRevisionTypeDeChampsTask for more information
    # Just add delete_flag with "true" to effectively remove the type de champ from the draft.

    def process(row)
      return unless row["delete_flag"] == "true"

      procedure_id = row["demarche_id"]
      typed_id = row["id"]

      Rails.logger.info { "#{self.class.name}: Processing #{row.inspect}" }

      revision = Procedure.find(procedure_id).draft_revision

      stable_id = revision.types_de_champ.find { _1.to_typed_id == typed_id }&.stable_id

      fail "TypeDeChamp not found ! #{typed_id}" if stable_id.nil?

      coordinate, type_de_champ = revision.coordinate_and_tdc(stable_id)

      if coordinate&.used_by_routing_rules?
        fail "#{typed_id} / #{type_de_champ.libelle} » est utilisé pour le routage, vous ne pouvez pas le supprimer."
      end

      revision.remove_type_de_champ(stable_id)
    end
  end
end
