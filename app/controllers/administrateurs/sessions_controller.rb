class Administrateurs::SessionsController < Sessions::SessionsController
  def demo
    return redirect_to root_path if Rails.env.production?

    @administrateur = Administrateur.new(email: 'admin@tps.fr', password: 'password')
    render 'new'
  end

  def new
    @administrateur = Administrateur.new
  end

  def create
    super
  end

  def after_sign_in_path_for(resource)
    admin_procedures_path
  end
end
