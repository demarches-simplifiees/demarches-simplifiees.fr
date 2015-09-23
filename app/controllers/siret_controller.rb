class SiretController < ApplicationController
  before_action :authenticate_user!
  def index
    @procedure = Procedure.find(params['procedure_id'])
  rescue ActiveRecord::RecordNotFound
    error_procedure
  end

  def error_procedure
    render :file => "#{Rails.root}/public/404_procedure_not_found.html",  :status => 404
  end

end
