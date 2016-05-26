class Users::SessionsController < Sessions::SessionsController
# before_filter :configure_sign_in_params, only: [:create]

  def demo
    return redirect_to root_path if Rails.env.production?

    @user = User.new(email: 'demo@tps.fr', password: 'password')

    render 'new'
  end

# GET /resource/sign_in
  def new
    unless user_return_to_procedure_id.nil?
      @dossier = Dossier.new(procedure: Procedure.not_archived(user_return_to_procedure_id))
    end

    @user = User.new
  rescue ActiveRecord::RecordNotFound
    error_procedure
  end

#POST /resource/sign_in
  def create
    super

    current_user.update_attributes(loged_in_with_france_connect: '')
  end

# DELETE /resource/sign_out
  def destroy
    connected_with_france_connect = current_user.loged_in_with_france_connect
    current_user.update_attributes(loged_in_with_france_connect: '')

    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out && is_flashing_format?
    yield if block_given?

    if connected_with_france_connect == 'entreprise'
      redirect_to FRANCE_CONNECT.entreprise_logout_endpoint
    elsif connected_with_france_connect == 'particulier'
      redirect_to FRANCE_CONNECT.particulier_logout_endpoint
    else
      respond_to_on_destroy
    end
  end

  def no_procedure
    session['user_return_to'] = nil
    redirect_to new_user_session_path
  end

  private

  def error_procedure
    flash.alert = t('errors.messages.procedure_not_found')
    redirect_to url_for root_path
  end

  def user_return_to_procedure_id
    return nil if session["user_return_to"].nil?

    NumberService.to_number session["user_return_to"].split("?procedure_id=").second
  end
end
