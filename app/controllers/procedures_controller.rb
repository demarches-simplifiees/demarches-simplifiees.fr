class ProceduresController < ApplicationController
  before_action :retrieve_procedure

  def logo
    if @procedure.logo.attached?
      logo_variant = logo.variant(resize_to_limit: [400, 400])
      if logo_variant.key.present?
        redirect_to logo_variant.processed.url
      else
        redirect_to url_for(@procedure.logo)
      end
    else
      redirect_to ActionController::Base.helpers.image_url(PROCEDURE_DEFAULT_LOGO_SRC)
    end
  end

  private

  def retrieve_procedure
    @procedure = Procedure.find(params[:id])
  end
end
