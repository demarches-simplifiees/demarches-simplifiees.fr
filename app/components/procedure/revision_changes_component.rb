# frozen_string_literal: true

class Procedure::RevisionChangesComponent < ApplicationComponent
  def initialize(new_revision:, previous_revision:)
    @previous_revision = previous_revision
    @new_revision = new_revision
    @procedure = new_revision.procedure

    @tdc_changes = previous_revision.compare_types_de_champ(new_revision)
    @public_move_changes, @private_move_changes = @tdc_changes.filter { _1.op == :move }.partition { !_1.private? }
    @ineligibilite_rules_changes = previous_revision.compare_ineligibilite_rules(new_revision)
  end

  private

  def used_by_routing_rules?(type_de_champ)
    @procedure.used_by_routing_rules?(type_de_champ)
  end
end
