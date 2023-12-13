class RecoveriesController < ApplicationController
  before_action :ensure_agent_connect_is_used, except: [:nature, :post_nature, :support]
  before_action :ensure_collectivite_territoriale, except: [:nature, :post_nature, :support]

  def nature
  end

  def post_nature
    if nature_params == 'collectivite'
      redirect_to identification_recovery_path
    else
      redirect_to support_recovery_path(error: :other_nature)
    end
  end

  def identification
    @structure_name = structure_name
  end

  def post_identification
    # cookies are used to avoid leaking
    # email in url
    cookies[:recover_previous_email] = previous_email

    redirect_to selection_recovery_path
  end

  def selection
  end

  def post_selection
    redirect_to terminee_recovery_path
  end

  def terminee
  end

  def support
  end

  private

  def nature_params = params[:nature]
  def siret = current_instructeur.agent_connect_information.siret
  def previous_email = params[:previous_email]

  def structure_name
    # we know that the structure exists because
    # of the ensure_collectivite_territoriale guard
    APIRechercheEntreprisesService.new.(siret:).value![:nom_complet]
  end

  def ensure_agent_connect_is_used
    if current_instructeur&.agent_connect_information.nil?
      redirect_to support_recovery_path(error: :must_use_agent_connect)
    end
  end

  def ensure_collectivite_territoriale
    if !APIRechercheEntreprisesService.collectivite_territoriale?(siret:)
      redirect_to support_recovery_path(error: 'not_collectivite_territoriale')
    end
  end
end
