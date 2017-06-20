class Administrateurs::SessionsController < Sessions::SessionsController
  layout "new_application"

  def demo
    return redirect_to root_path if Rails.env.production?

    @user = User.new(email: DemoEmails[:admin], password: 'password')
    render 'users/sessions/new'
  end

  def new
    redirect_to new_user_session_path
  end

  def create
    super
  end

  def after_sign_in_path_for(resource)
    admin_procedures_path
  end
end
