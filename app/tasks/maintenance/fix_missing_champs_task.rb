# frozen_string_literal: true

# bundle exec maintenance_tasks perform Maintenance::FixMissingChampsTask --arguments procedure_ids:id1,id2,id3
module Maintenance
  class FixMissingChampsTask < MaintenanceTasks::Task
    attribute :procedure_ids, array: true, default: []

    def collection
      Dossier.joins(:procedure).where(procedure: { id: procedure_ids }).in_batches
    end

    def process(dossiers)
      # rubocop:disable Rails/FindEach
      DossierPreloader.new(dossiers).all.each do |dossier|
        # rubocop:enable Rails/FindEach
        maybe_fixable = [dossier, dossier.editing_forks.first].compact.any? { _1.champs.size < _1.revision.types_de_champ.size }
        if maybe_fixable
          DataFixer::DossierChampsMissing.new(dossier:).fix
        end
      end
    end
  end
end
