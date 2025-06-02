# frozen_string_literal: true

class ProceduresController < ApplicationController
  before_action :retrieve_procedure

  def logo
    if @procedure.logo.attached?
      redirect_to url_for(@procedure.logo.variant(:email))
    else
      redirect_to ActionController::Base.helpers.image_url(PROCEDURE_DEFAULT_LOGO_SRC)
    end
  end

  private

  def retrieve_procedure
    @procedure = Procedure.find(params[:id])
  end
end
