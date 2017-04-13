class Admin::PrevisualisationsController < AdminController
  before_action :retrieve_procedure

  def show
    @procedure
    @dossier = Dossier.new(id: 0, procedure: @procedure)

    PrevisualisationService.destroy_all_champs @dossier
    @dossier.build_default_champs

    @champs = @dossier.ordered_champs

    @headers = @champs.inject([]) do |acc, champ|
      acc.push(champ) if champ.type_champ == 'header_section'
      acc
    end
  end
end
