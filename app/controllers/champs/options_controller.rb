class Champs::OptionsController < Champs::ChampController
  include TurboChampsConcern

  def remove
    @champ.remove_option([params[:option]].compact, true)
    @dossier = @champ.private? ? nil : @champ.dossier
    champs_attributes = params[:champ_id].present? ? { @champ.id => true } : { @champ.public_id => { with_public_id: true } }
    @to_show, @to_hide, @to_update = champs_to_turbo_update(champs_attributes, @champ.dossier.champs)
  end
end
