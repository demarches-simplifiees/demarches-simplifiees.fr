# frozen_string_literal: true

module Maintenance
  class DossierAttributesTask < MaintenanceTasks::Task
    attribute :dossier, default: ""
    no_collection

    def process
      Champ.private_only.where(dossier:)
        .joins(type_de_champ: :revision_types_de_champ)
        .left_joins(parent: { type_de_champ: :revision_types_de_champ })
        .includes(type_de_champ: :revision_type_de_champ)
        .order(Arel.sql("coalesce(revision_types_de_champ_types_de_champ.position, procedure_revision_types_de_champ.position)," +
                          " COALESCE(champs.row_id,' '), procedure_revision_types_de_champ.position"))
        .each do |champ|
        Rails.logger.info("#{champ.dossier_id}:" +
                            (champ.parent_id ? champ.parent.libelle + '.' : '').to_s +
                            "#{champ.libelle}=#{champ.value}" +
                            ":#{champ.type_de_champ.revision_type_de_champ.revision_id}" +
                            ":#{champ.type_de_champ.revision_type_de_champ.id}")
      end
    end
  end
end
