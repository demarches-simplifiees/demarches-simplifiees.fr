class Administrateurs::SessionsController < Sessions::SessionsController

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
