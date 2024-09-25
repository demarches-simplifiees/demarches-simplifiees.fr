# frozen_string_literal: true

module Maintenance
  class DossierAttributesTask < MaintenanceTasks::Task
    attribute :dossier, default: ""
    no_collection

    def process
      order = Arel.sql("COALESCE(revision_types_de_champ_types_de_champ.position, procedure_revision_types_de_champ.position), \
                       COALESCE(champs.row_id,' '), procedure_revision_types_de_champ.position")
      Champ.private_only.where(dossier:)
        .joins(type_de_champ: :revision_types_de_champ)
        .includes(:type_de_champ)
        .where(procedure_revision_types_de_champ: { revision_id: dossier.revision_id })
        .left_joins(parent: { type_de_champ: :revision_types_de_champ })
        .where(revision_types_de_champ_types_de_champ: { revision_id: [dossier.revision_id, nil] })
        .order(order)
      AdministrateurMailer.champ_description(User.find(2), champs).deliver_now
    end
  end
end
