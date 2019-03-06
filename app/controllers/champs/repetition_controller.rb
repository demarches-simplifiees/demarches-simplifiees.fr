class Champs::RepetitionController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @champ = Champ
      .joins(:dossier)
      .where(dossiers: { user_id: logged_user_ids })
      .find(params[:champ_id])

    @position = params[:position]
    row = (@champ.champs.empty? ? 0 : @champ.champs.last.row) + 1

    @champ.add_row(row)

    if @champ.private?
      @attribute = "dossier[champs_private_attributes][#{@position}][champs_attributes]"
    else
      @attribute = "dossier[champs_attributes][#{@position}][champs_attributes]"
    end
  end
end
