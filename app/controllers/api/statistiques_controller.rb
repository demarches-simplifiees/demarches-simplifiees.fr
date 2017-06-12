class API::StatistiquesController < ApplicationController
  def dossiers_stats
    render json: {
               total: total_dossiers,
               mois: dossiers_mois
           }
  end

  private

  def total_dossiers
    Dossier.where.not(state: :draft).size
  end

  def dossiers_mois
    Dossier.where.not(state: :draft).where(created_at: (1.month.ago)..Time.now).size
  end
end
