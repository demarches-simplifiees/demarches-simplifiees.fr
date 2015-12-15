class Admin::ProfileController < AdminController
  def show
    @administrateur = current_administrateur
  end
end
