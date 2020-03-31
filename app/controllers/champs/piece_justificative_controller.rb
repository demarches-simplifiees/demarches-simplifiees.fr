class Champs::PieceJustificativeController < ApplicationController
  before_action :authenticate_logged_user!

  def update
    @champ = policy_scope(Champ).find(params[:champ_id])

    @champ.piece_justificative_file.attach(params[:blob_signed_id])
    if @champ.save
      render :show
    else
      errors = @champ.errors.full_messages

      # Before Rails 6, the attachment was persisted to database
      # by 'attach', even before calling save.
      # So until we're on Rails 6, we need to purge the file explicitely.
      @champ.piece_justificative_file.purge_later

      render :json => { errors: errors }, :status => 422
    end
  end
end
