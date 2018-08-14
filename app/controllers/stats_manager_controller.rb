class StatsManagerController < ApplicationController
  layout "new_application"
  before_action :authenticate_administration!

  def index
    excluded_ids = []
    stats = ['accepte', 'refuse', 'sans_suite', 'en_instruction', 'en_construction', 'brouillon']
    @dossiers = stats.map do |state|
      if state == 'brouillon'
        data, ids = compute_state(state, :created_at, excluded_ids)
        excluded_ids += ids
        { name: state, data: data }
      elsif state == 'en_construction'
        data, ids = compute_state(state, :en_construction_at, excluded_ids)
        excluded_ids += ids
        { name: state, data: data }
      elsif state == 'en_instruction'
        data, ids = compute_state(state, :en_instruction_at, excluded_ids)
        excluded_ids += ids
        { name: state, data: data }
      else
        data, ids = compute_state(state, :updated_at, excluded_ids, true)
        excluded_ids += ids
        { name: state, data: data }
      end
    end

    satisfied = Feedback.where(mark: 2).count
    neutral = Feedback.where(mark: 1).count
    unsatisfied = Feedback.where(mark: 0).count
    @indice_satisfaction = { 'Satisfait': satisfied, 'Neutre': neutral, 'Insatisfait': unsatisfied }
  end

  def download
    data = []

    header_file = ['ID du dossier', 'ID de la procédure', 'Nom de la procédure', 'ID utilisateur', 'Etat du fichier', 'Durée en brouillon (jours)', 'Durée en construction', 'Durée en instruction']

    Dossier.find_each do |dossier|
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

  private

  def compute_state(state, date_attr, excluded_ids, need_state = false)
    ids = []
    [
      [0, 1, 2, 3, 4, 5].reduce({}) do |data, month_number|
        range = (Time.now - month_number.month).beginning_of_month..(Time.now - month_number.month).end_of_month
        if need_state
          dossiers = Dossier.where(state: state).where.not(id: excluded_ids.uniq).where("#{date_attr}": range)
        else
          dossiers = Dossier.where.not(id: excluded_ids.uniq).where("#{date_attr}": range)
        end
        ids += dossiers.ids
        data["#{Time.now.month - month_number}"] = dossiers.count
        data
      end, ids
    ]
  end
end
