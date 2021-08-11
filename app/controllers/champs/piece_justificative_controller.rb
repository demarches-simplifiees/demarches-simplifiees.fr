class Champs::PieceJustificativeController < ApplicationController
  before_action :authenticate_logged_user!

  def update
    @champ = policy_scope(Champ).find(params[:champ_id])

    @champ.piece_justificative_file.attach(params[:blob_signed_id])
    if @champ.save
      render :show
    else
      errors = @champ.errors.full_messages
      render :json => { errors: errors }, :status => 422
    end
  end

  def download
    @champ = read_scope.find(params[:champ_id])
    if @champ&.is_a? Champs::PieceJustificativeChamp
      redirect_to @champ.piece_justificative_file.service_url, status: :found
    else
      render :json => { errors: "Il n'y a pas de piece justificative #{params[:champ_id]}" }, :status => 404
    end
  end

  private

  def read_scope
    policy_scope(Champ, policy_scope_class: ChampPolicy::ReadScope)
  end
end
