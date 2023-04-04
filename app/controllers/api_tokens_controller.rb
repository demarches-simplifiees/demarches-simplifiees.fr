class APITokensController < ApplicationController
  before_action :authenticate_administrateur!

  def create
    @api_token, @packed_token = APIToken.generate(current_administrateur)

    respond_to do |format|
      format.turbo_stream { render :index }
      format.html { redirect_back(fallback_location: profil_path) }
    end
  end

  def update
    @api_token = current_administrateur.api_tokens.find(params[:id])

    disallow_procedure_id = api_token_params.fetch(:disallow_procedure_id, nil)
    if disallow_procedure_id.present?
      @api_token.disallow_procedure(disallow_procedure_id.to_i)
    else
      @api_token.update!(api_token_params)
    end

    respond_to do |format|
      format.turbo_stream { render :index }
      format.html { redirect_back(fallback_location: profil_path) }
    end
  end

  def destroy
    @api_token = current_administrateur.api_tokens.find(params[:id])
    @api_token.destroy

    respond_to do |format|
      format.turbo_stream { render :index }
      format.html { redirect_back(fallback_location: profil_path) }
    end
  end

  private

  def api_token_params
    params.require(:api_token).permit(:name, :write_access, :disallow_procedure_id, allowed_procedure_ids: [])
  end
end
