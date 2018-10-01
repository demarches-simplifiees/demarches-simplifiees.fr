module NewUser
  class DemarchesController < UserController
    def index
      @previous_demarches_still_active = current_user
        .dossiers
        .includes(:procedure)
        .map(&:procedure)
        .uniq
        .select(&:publiee?)

      @popular_demarches = Procedure
        .includes(:service)
        .select("procedures.*, COUNT(*) AS procedures_count")
        .joins(:dossiers)
        .publiees
        .where(dossiers: { created_at: 7.days.ago..Time.now })
        .group("procedures.id")
        .order("procedures_count DESC")
        .limit(5)
    end
  end
end
