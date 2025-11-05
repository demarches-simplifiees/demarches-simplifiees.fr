# frozen_string_literal: true

class API::V1::DossiersController < APIController
  before_action :check_api_token
  before_action :fetch_dossiers

  DEFAULT_PAGE_SIZE = 100
  MAX_PAGE_SIZE = 1000
  ORDER_DIRECTIONS = { 'asc' => :asc, 'desc' => :desc }

  def index
    dossiers = @dossiers.page(params[:page]).per(per_page)

    render json: { dossiers: dossiers.map { |dossier| DossiersSerializer.new(dossier) }, pagination: pagination(dossiers) }
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: :not_found
  end

  def show
    dossier = @dossiers.for_api.find(params[:id])
    DossierPreloader.load_one(dossier)

    render json: { dossier: DossierSerializer.new(dossier).as_json }
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: :not_found
  end

  private

  def pagination(dossiers)
    {
      page: dossiers.current_page,
      resultats_par_page: dossiers.limit_value,
      nombre_de_page: dossiers.total_pages,
    }
  end

  def per_page # inherited value from will_paginate
    resultats_par_page = params[:resultats_par_page]&.to_i
    if resultats_par_page && resultats_par_page > 0
      [resultats_par_page, MAX_PAGE_SIZE].min
    else
      DEFAULT_PAGE_SIZE
    end
  end

  def fetch_dossiers
    procedure = @api_token.procedures.find(params[:procedure_id])

    order = ORDER_DIRECTIONS.fetch(params[:order], :asc)
    @dossiers = procedure
      .dossiers
      .visible_by_administration
      .order_by_created_at(order)

  rescue ActiveRecord::RecordNotFound
    render json: {}, status: :not_found
  end
end
