module Administrateurs
  class ChorusController < AdministrateurController
    before_action :retrieve_procedure

    def edit
    end

    def update
      @configuration = @procedure.chorus_configuration
      @configuration.assign_attributes(configurations_params)
      if @configuration.valid?
        @procedure.update!(chorus: @configuration.attributes)

        flash.notice = "La configuration Chorus a été mise à jour et prend immédiatement effet pour les nouveaux dossiers."
        redirect_to admin_procedure_path(@procedure)
      else
        flash.now.alert = "Des erreurs empêchent la validation du connecteur chorus. Corrigez les erreurs"
        render :edit
      end
    end

    private

    def configurations_params
      params.require(:chorus_configuration).permit(:centre_de_coup, :domaine_fonctionnel, :referentiel_de_programmation)
    end
  end
end
