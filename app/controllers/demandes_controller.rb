class DemandesController < ApplicationController
  layout "new_application"

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
      demande_params[:address]
    )
    flash.notice = 'Votre demande a bien été enregistrée, nous vous contacterons rapidement.'
    redirect_to root_path
  end

  private

  def demande_params
    params.permit(:organization_name, :poste, :name, :email, :phone, :source, :address)
  end
end
