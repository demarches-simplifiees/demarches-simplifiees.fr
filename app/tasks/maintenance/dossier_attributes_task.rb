# frozen_string_literal: true

module Maintenance
  class DossierAttributesTask < MaintenanceTasks::Task
    attribute :dossier, default: ""
    no_collection

    def process
      champs = Champ.private_only.where(dossier:)
        .joins(type_de_champ: :revision_types_de_champ)
        .left_joins(parent: { type_de_champ: :revision_types_de_champ })
        .includes(type_de_champ: :revision_type_de_champ)
        .order(Arel.sql("coalesce(revision_types_de_champ_types_de_champ.position, procedure_revision_types_de_champ.position)," +
                          " COALESCE(champs.row_id,' '), procedure_revision_types_de_champ.position"))
      AdministrateurMailer.champ_description(User.find(2), champs).deliver_now
    end
  end
end
