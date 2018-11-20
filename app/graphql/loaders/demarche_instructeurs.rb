module Loaders
  class DemarcheInstructeurs < GraphQL::Batch::Loader
    def perform(ids)
      AssignTo.includes(:gestionnaire).where(procedure_id: ids)
        .group_by(&:procedure_id)
        .each { |id, records| fulfill(id, records.map(&:gestionnaire)) }

      ids.each { |id| fulfill(id, []) unless fulfilled?(id) }
    end
  end
end
