class Admin::PrevisualisationsController < AdminController
  before_action :retrieve_procedure

  def show
    @procedure
    @dossier = Dossier.new(id: 0, procedure: @procedure)

    Champ.where(dossier_id: @dossier.id).destroy_all
    @dossier.build_default_champs

    @champs = @dossier.ordered_champs
  end
end