class DemandesController < ApplicationController
  def new
  end

  def create
    Helpscout::FormAdapter.new(
      subject: "Demande de compte administrateur pour " + demande_params[:organization_name],
      email: demande_params[:email],
      phone: demande_params[:phone],
      text: demande_text,
      dossier_id: "",
      browser: browser_name,
      tags: [Helpscout::FormAdapter::ADMIN_TYPE_DEMANDE_COMPTE]
    ).send_form
    # PipedriveService.add_demande(
    #   demande_params[:email],
    #   demande_params[:phone],
    #   demande_params[:name],
    #   demande_params[:poste],
    #   demande_params[:source],
    #   demande_params[:organization_name],
    #   demande_params[:address],
    #   demande_params[:nb_of_procedures],
    #   demande_params[:nb_of_dossiers],
    #   demande_params[:deadline]
    # )
    flash.notice = 'Votre demande a bien été enregistrée, nous vous contacterons rapidement.'
    redirect_to administration_path(formulaire_demande_compte_admin_submitted: true)
  end

  private

  def demande_text
    %Q{
    <p>Demande de compte administrateur</p>
    <ul>
      <li>email: #{demande_params[:email]}</li>
      <li>Nom: #{demande_params[:name]}</li>
      <li>Téléphone: #{demande_params[:phone]}</li>
      <li>Poste occupé: #{demande_params[:poste]}:</li>
      <li>J'ai entendu parler de Mes-Demarches: #{demande_params[:source]}</li>
      <li>Service: #{demande_params[:organization_name]}</li>
      <li>Commune: #{demande_params[:address]}</li>
      <li>Nb de procédure envisagées: #{demande_params[:nb_of_procedures]}</li>
      <li>Nb  de dossiers envisagés: #{demande_params[:nb_of_dossiers]}</li>
      <li>Date limite: #{demande_params[:deadline]}</li>
    </ul>
    <p>Si vous pensez que la demande est légitime, pour créer un compte, copier l'adresse de mail puis cliquer sur <a href="https://www.mes-demarches.gov.pf/manager/administrateurs/new">ajouter un administrateur</a></p>
    }
  end

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

  def browser_name
    if browser.known?
      "#{browser.name} #{browser.version} (#{browser.platform.name})"
    end
  end
end
