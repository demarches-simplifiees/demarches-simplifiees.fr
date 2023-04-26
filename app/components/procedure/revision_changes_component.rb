class Procedure::RevisionChangesComponent < ApplicationComponent
  def initialize(changes:, previous_revision:)
    @changes = changes
    @previous_revision = previous_revision
    @public_move_changes, @private_move_changes = changes.filter { _1.op == :move }.partition { !_1.private? }
    @delete_champ_warning = !total_dossiers.zero? && !@changes.all?(&:can_rebase?)
  end

  private

  def total_dossiers
    @total_dossiers ||= @previous_revision.dossiers
      .visible_by_administration
      .state_en_construction_ou_instruction
      .size
  end
end
