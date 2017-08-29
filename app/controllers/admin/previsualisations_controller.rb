class Admin::PrevisualisationsController < AdminController
  before_action :retrieve_procedure

  def show
    @procedure
    @dossier = Dossier.new(id: 0, procedure: @procedure)

    PrevisualisationService.delete_all_champs @dossier
    @dossier.build_default_champs

    @champs = @dossier.ordered_champs

    @headers = @champs.select { |champ| champ.type_champ == 'header_section' }
  end
end
