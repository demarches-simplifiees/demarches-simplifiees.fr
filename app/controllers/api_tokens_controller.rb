class APITokensController < ApplicationController
  before_action :authenticate_administrateur!
  before_action :set_api_token, only: [:destroy]

  def nom
    @name = name
  end

  def autorisations
    @name = name
    @libelle_id_procedures = current_administrateur
      .procedures
      .order(:libelle)
      .pluck(:libelle, :id)
      .map { |libelle, id| ["#{id} - #{libelle}", id] }
  end

  def securite
  end

  def create
    @api_token, @packed_token = APIToken.generate(current_administrateur)

    @api_token.update!(name:, write_access:,
                       allowed_procedure_ids:, authorized_networks:, expires_at:)
  end

  def destroy
    @api_token.destroy

    redirect_to profil_path
  end

  private

  def authorized_networks
    if params[:networkFiltering] == "customNetworks"
      networks
    else
      []
    end
  end

  def networks
    params[:networks]
      .split
      .map { begin IPAddr.new(_1) rescue nil end }
      .compact
  end

  def set_api_token
    @api_token = current_administrateur.api_tokens.find(params[:id])
  end

  def name
    params[:name]
  end

  def write_access
    params[:access] == "read_write"
  end

  def allowed_procedure_ids
    if params[:target] == "custom"
      current_administrateur
        .procedure_ids
        .intersection(params[:targets].map(&:to_i))
    else
      nil
    end
  end

  def expires_at
    case params[:lifetime]
    in 'oneWeek'
      1.week.from_now.to_date
    in 'custom'
      [
        Date.parse(params[:customLifetime]),
        1.year.from_now
      ].min
    in 'infinite' if authorized_networks.present?
      nil
    else
      1.week.from_now.to_date
    end
  end
end
