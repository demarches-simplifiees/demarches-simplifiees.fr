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
    # cipher previous_user email
    # to avoid leaks in the url
    ciphered_email = cipher(previous_email)

    redirect_to selection_recovery_path(ciphered_email:)
  end

  def selection
    @previous_email = uncipher(params[:ciphered_email])

    previous_user = User.find_by(email: @previous_email)

    @recoverables = RecoveryService
      .recoverable_procedures(previous_user:, siret:)

    redirect_to support_recovery_path(error: :no_dossier) if @recoverables.empty?
  end

  def post_selection
    previous_user = User.find_by(email: previous_email)

    RecoveryService.recover_procedure!(previous_user:,
                          next_user: current_user,
                          siret:,
                          procedure_ids:)

    redirect_to terminee_recovery_path
  end

  def terminee
  end

  def support
  end

  private

  def nature_params = params[:nature]
  def siret = current_instructeur.last_agent_connect_information.siret
  def previous_email = params[:previous_email]
  def procedure_ids = params[:procedure_ids].map(&:to_i)

  def cipher(email) = message_verifier.generate(email, purpose: :agent_files_recovery, expires_in: 1.hour)
  def uncipher(email) = message_verifier.verified(email, purpose: :agent_files_recovery) rescue nil

  def structure_name
    # we know that the structure exists because
    # of the ensure_collectivite_territoriale guard
    APIRechercheEntreprisesService.new.(siret:).value![:nom_complet]
  end

  def ensure_agent_connect_is_used
    if current_instructeur&.last_agent_connect_information.nil?
      redirect_to support_recovery_path(error: :must_use_agent_connect)
    end
  end

  def ensure_collectivite_territoriale
    if !APIRechercheEntreprisesService.collectivite_territoriale?(siret:)
      redirect_to support_recovery_path(error: 'not_collectivite_territoriale')
    end
  end
end
