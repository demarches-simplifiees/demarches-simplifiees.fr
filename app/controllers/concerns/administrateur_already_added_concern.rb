# frozen_string_literal: true

module AdministrateurAlreadyAddedConcern
  private

  def ensure_not_already_added
    return unless administrateur&.owns?(procedure)

    flash[:notice] = t('manager.procedures.administrateur_already_added')
    redirect_to manager_procedure_path(procedure)
  end
end
