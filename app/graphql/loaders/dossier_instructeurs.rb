module Loaders
  class DossierInstructeurs < GraphQL::Batch::Loader
    def perform(ids)
      Follow.includes(:gestionnaire).where(dossier_id: ids)
        .group_by(&:dossier_id)
        .each { |id, records| fulfill(id, records.map(&:gestionnaire)) }

      ids.each { |id| fulfill(id, []) unless fulfilled?(id) }
    end
  end
end
