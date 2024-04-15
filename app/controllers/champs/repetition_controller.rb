class Champs::RepetitionController < ApplicationController
  before_action :authenticate_logged_user!

  def add
    @champ = find_champ
    row = @champ.add_row(@champ.dossier.revision)
    @first_champ_id = row.map(&:focusable_input_id).compact.first
    @row_id = row.first&.row_id
    @row_number = @row_id.nil? ? 0 : @champ.row_ids.find_index(@row_id) + 1
  end

  def remove
    @champ = find_champ
    @champ.champs.where(row_id: params[:row_id]).destroy_all
    @champ.reload
    @row_id = params[:row_id]
  end

  private

  def find_champ
    if params[:champ_id].present?
      policy_scope(Champ).includes(:champs).find(params[:champ_id])
    else
      policy_scope(Champ)
        .includes(:champs, :type_de_champ)
        .find_by!(dossier_id: params[:dossier_id], type_de_champ: { stable_id: params[:stable_id] })
    end
  end
end
