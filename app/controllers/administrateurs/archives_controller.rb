module Administrateurs
  class ArchivesController < AdministrateurController
    before_action :retrieve_procedure, only: [:index]
    def index
      @exports = Export.find_for_groupe_instructeurs(@procedure.groupe_instructeur_ids, nil)
      @average_dossier_weight = @procedure.average_dossier_weight
      @count_dossiers_termines_by_month = Traitement.count_dossiers_termines_by_month(@procedure.groupe_instructeurs)
      @archives = Archive.for_groupe_instructeur(@procedure.groupe_instructeurs).to_a
    end
  end
end
