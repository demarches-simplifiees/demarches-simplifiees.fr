# frozen_string_literal: true

# Explains to a super admin why a user cannot be deleted, with links to act on.
class Manager::DeletionBlockersComponent < ApplicationComponent
  AVIS_SHOWN = 10

  def initialize(user:)
    @user = user
  end

  def render?
    blockers.any?
  end

  private

  attr_reader :user

  def blockers
    @blockers ||= user.deletion_blockers
  end

  def avis_rows(scope)
    scope.includes(:dossier, :claimant, experts_procedure: { expert: :user }).order(created_at: :desc).limit(AVIS_SHOWN)
  end

  def hidden_count(scope)
    [scope.count - AVIS_SHOWN, 0].max
  end

  def dossier_link(avis)
    link_to(t(".dossier", id: avis.dossier_id), manager_dossier_path(avis.dossier_id))
  end

  def procedure_link(avis)
    procedure = avis.dossier.procedure
    link_to(procedure.libelle, manager_procedure_path(procedure))
  end
end
