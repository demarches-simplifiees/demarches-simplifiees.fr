module NewUser
  class DemarchesController < UserController
    def index
      @previous_demarches_still_active = current_user
        .dossiers
        .includes(:procedure)
        .map(&:procedure)
        .uniq
        .select { |p| p.publiee? }
    end
  end
end
