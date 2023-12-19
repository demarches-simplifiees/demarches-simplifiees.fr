class RecoveryService
  def self.recoverable_procedures(previous_user:, siret:)
    return [] if previous_user.nil?

    previous_user.dossiers
      .includes(:procedure)
      .joins(:etablissement)
      .where(etablissements: { siret: })
      .pluck('procedures.id, procedures.libelle')
      .tally
      .map { |(procedure_id, libelle), count| { procedure_id:, libelle:, count: } }
      .sort_by { |h| [-h[:count], h[:libelle]] }
  end

  def self.recover_procedure!(previous_user:, next_user:, siret:, procedure_ids:)
    recoverable_procedure_ids = recoverable_procedures(previous_user: previous_user, siret: siret)
      .map { _1[:procedure_id] }

    procedure_ids
      .select { |id| id.in?(recoverable_procedure_ids) }
      .then do |p_ids|
        previous_user.dossiers.joins(:procedure)
          .where(procedure: { id: p_ids })
          .update_all(user_id: next_user.id)
      end
  end
end
