class Champs::OptionsController < ApplicationController
  include TurboChampsConcern

  before_action :authenticate_logged_user!

  def remove
    champ = policy_scope(Champ).includes(:champs).find(params[:champ_id])
    champ.remove_option([params[:option]].compact, true)
    champs = champ.private? ? champ.dossier.champs_private_all : champ.dossier.champs_public_all
    @dossier = champ.private? ? nil : champ.dossier
    @to_show, @to_hide, @to_update = champs_to_turbo_update({ params[:champ_id] => true }, champs)
  end
end
