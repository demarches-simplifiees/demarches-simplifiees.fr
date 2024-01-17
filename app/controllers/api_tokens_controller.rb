class APITokensController < ApplicationController
  before_action :authenticate_administrateur!
  before_action :set_api_token, only: [:destroy]

  def nom
    @name = params[:name]
  end

  def create
    @api_token, @packed_token = APIToken.generate(current_administrateur)

    render :index
  end

  def destroy
    @api_token.destroy

    redirect_to profil_path
  end

  private

  def set_api_token
    @api_token = current_administrateur.api_tokens.find(params[:id])
  end

  def become_full_access?
    api_token_params[:become_full_access].present?
  end

  def disallow_procedure_id
    api_token_params[:disallow_procedure_id]
  end

  def api_token_params
    params.require(:api_token).permit(:name, :write_access, :become_full_access, :disallow_procedure_id, allowed_procedure_ids: [])
  end
end
