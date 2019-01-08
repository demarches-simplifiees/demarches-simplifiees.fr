class DemandesController < ApplicationController
  def new
  end

  def create
    PipedriveService.add_demande(
      demande_params[:email],
      demande_params[:phone],
      demande_params[:name],
      demande_params[:poste],
      demande_params[:source],
      demande_params[:organization_name],
      demande_params[:address],
      demande_params[:nb_of_procedures],
      demande_params[:nb_of_dossiers],
      demande_params[:deadline]
    )
    flash.notice = 'Votre demande a bien été enregistrée, nous vous contacterons rapidement.'
    redirect_to administration_path(formulaire_demande_compte_admin_submitted: true)
  end

  private

  def demande_params
    params.permit(
      :organization_name,
      :poste,
      :name,
      :email,
      :phone,
      :source,
      :address,
      :nb_of_procedures,
      :nb_of_dossiers,
      :deadline
    )
  end
end
