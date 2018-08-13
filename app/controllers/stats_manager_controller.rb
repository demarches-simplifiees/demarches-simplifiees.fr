class StatsManagerController < ApplicationController
  before_action :authenticate_administration!

  def index
  end

  def download
    data = []

    dossier = Dossier.where(state: ['brouillon', 'en_construction', 'en_instruction'])
    header_file = ['ID du dossier', 'ID de la procédure', 'Nom de la procédure', 'ID utilisateur', 'Etat du fichier', 'Durée en brouillon (jours)', 'Durée en construction', 'Durée en instruction']

    Dossier.all.each do |dossier|
      en_brouillon = dossier.en_construction_at.present? ? ((dossier.en_construction_at - dossier.created_at).to_f / 60 / 60 / 24).round(2) : nil
      en_construction = dossier.en_instruction_at.present? ? ((dossier.en_instruction_at - dossier.en_construction_at).to_f / 60 / 60 / 24).round(2) : nil
      en_instruction = dossier.processed_at.present? ? ((dossier.processed_at - dossier.en_instruction_at).to_f / 60 / 60 / 24).round(2) : nil

      row = [dossier.id, dossier.procedure.id, dossier.procedure.libelle, dossier.user.id, dossier.state, en_brouillon.to_s, en_construction.to_s, en_instruction.to_s]

      data << row
    end

    respond_to do |format|
      format.csv { send_data(SpreadsheetArchitect.to_xlsx(data: data, headers: header_file), filename: "statistiques.csv") }
    end
  end
end
