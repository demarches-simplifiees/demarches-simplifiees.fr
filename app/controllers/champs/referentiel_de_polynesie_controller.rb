# frozen_string_literal: true

class Champs::ReferentielDePolynesieController < ApplicationController
  before_action :authenticate_logged_user!

  def search
    @params = search_params
    if bad_parameters
      render json: [], status: 400
    else
      render json: ReferentielDePolynesie::API.search(@params[:domain], @params[:term])
    end
  end

  def bad_parameters
    @params[:domain].blank? || @params[:domain].to_i == 0 || @params[:term].blank?
  end

  def search_params = params.permit(:domain, :term)
end
