module Manager
  class DossiersController < Manager::ApplicationController
    #
    # Administrate overrides
    #

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    def scoped_resource
      if unfiltered_list?
        # Don't display discarded dossiers in the unfiltered list…
        Dossier.kept
      else
        # … but allow them to be searched and displayed.
        Dossier
      end
    end

    private

    def unfiltered_list?
      action_name == "index" && !params[:search]
    end
  end
end
