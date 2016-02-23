class Users::SessionsController < Sessions::SessionsController
# before_filter :configure_sign_in_params, only: [:create]

  def demo
    return redirect_to root_path if Rails.env.production?

    @user = User.new(email: 'demo@tps.fr', password: 'password')

    render 'new'
  end

# GET /resource/sign_in
  def new
    @user = User.new
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

# protected

# You can put the params you want to permit in the empty array.
# def configure_sign_in_params
#   devise_parameter_sanitizer.for(:sign_in) << :attribute
# end
end
