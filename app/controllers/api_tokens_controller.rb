class APITokensController < ApplicationController
  before_action :authenticate_administrateur!
  before_action :set_api_token, only: [:update, :destroy]

  def create
    @api_token, @packed_token = APIToken.generate(current_administrateur)

    respond_to do |format|
      format.turbo_stream { render :index }
      format.html { redirect_back(fallback_location: profil_path) }
    end
  end

  def update
    if become_full_access?
      @api_token.become_full_access!
    elsif disallow_procedure_id.present?
      @api_token.untarget_procedure(disallow_procedure_id.to_i)
    else
      @api_token.update!(api_token_params)
    end

    respond_to do |format|
      format.turbo_stream { render :index }
      format.html { redirect_back(fallback_location: profil_path) }
    end
  end

  def destroy
    @api_token.destroy

    respond_to do |format|
      format.turbo_stream { render :index }
      format.html { redirect_back(fallback_location: profil_path) }
    end
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
