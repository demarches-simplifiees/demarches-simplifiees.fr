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
    @api_token.update!(api_token_params)

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
    params.require(:api_token).permit(:name)
  end
end
