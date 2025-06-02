# frozen_string_literal: true

class Procedure::RevisionChangesComponent < ApplicationComponent
  def initialize(new_revision:, previous_revision:)
    @previous_revision = previous_revision
    @new_revision = new_revision

    @tdc_changes = previous_revision.compare_types_de_champ(new_revision)
    @public_move_changes, @private_move_changes = @tdc_changes.filter { _1.op == :move }.partition { !_1.private? }
    @delete_champ_warning = !total_dossiers.zero? && !@tdc_changes.all?(&:can_rebase?)

    @ineligibilite_rules_changes = previous_revision.compare_ineligibilite_rules(new_revision)
  end

  private

  def total_dossiers
    @total_dossiers ||= @previous_revision.dossiers
      .visible_by_administration
      .state_en_construction_ou_instruction
      .size
  end
end
