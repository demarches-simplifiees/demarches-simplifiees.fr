class Champs::OptionsController < Champs::ChampController
  include TurboChampsConcern

  def remove
    @champ.remove_option([params[:option]].compact, true)
    @dossier = @champ.private? ? nil : @champ.dossier
    @to_show, @to_hide, @to_update = champs_to_turbo_update({ @champ.public_id => true }, @champ.dossier.champs)
  end
end
