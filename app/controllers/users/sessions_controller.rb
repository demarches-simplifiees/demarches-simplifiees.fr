class Users::SessionsController < Sessions::SessionsController
# before_filter :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  #POST /resource/sign_in
  def create
    super

    current_user.update_attributes(loged_in_with_france_connect: false)
  end

  # DELETE /resource/sign_out
  def destroy
    connected_with_france_connect = current_user.loged_in_with_france_connect
    current_user.update_attributes(loged_in_with_france_connect: false)


    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out && is_flashing_format?
    yield if block_given?


    if connected_with_france_connect
      redirect_to FRANCE_CONNECT.logout_endpoint
    else
      respond_to_on_destroy
    end
  end

  # protected

  # You can put the params you want to permit in the empty array.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.for(:sign_in) << :attribute
  # end
end
