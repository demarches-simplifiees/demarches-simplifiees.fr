# frozen_string_literal: true

class BulkRouteJob < ApplicationJob
  queue_as :critical

  def perform(procedure)
    dossiers = procedure.dossiers
      .with_revision
      .includes(:procedure, :groupe_instructeur, :champs)
      .state_not_termine

    dossiers.each do |dossier|
      dossier.update_column(:forced_groupe_instructeur, false)
      RoutingEngine.compute(dossier, assignment_mode: DossierAssignment.modes.fetch(:bulk_routing))
    end

    procedure.update!(routing_alert: false)
  end
end
