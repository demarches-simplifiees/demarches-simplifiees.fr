class ProcedureDecorator < Draper::Decorator
  delegate_all

  def lien
    h.new_users_dossiers_url(procedure_id: id)
  end
end
