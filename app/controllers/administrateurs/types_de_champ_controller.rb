module Administrateurs
  class TypesDeChampController < AdministrateurController
    before_action :retrieve_procedure, only: [:create, :update, :move, :move_up, :move_down, :destroy]
    before_action :procedure_revisable?, only: [:create, :update, :move, :move_up, :move_down, :destroy]

    def create
      type_de_champ = @procedure.draft_revision.add_type_de_champ(type_de_champ_create_params)

      if type_de_champ.valid?
        @coordinate = @procedure.draft_revision.coordinate_for(type_de_champ)

        # TODO : faire un test dans system qui pete

        if !@coordinate.child?
          all_coordinates = @procedure.draft_revision.revision_types_de_champ_public.includes(:type_de_champ)
          index_of_current_coordinate = all_coordinates.index(@coordinate)
          @upper_coordinates = all_coordinates.take(index_of_current_coordinate)

          @other_coordinates = all_coordinates.drop(index_of_current_coordinate + 1)
            .map { |coordinate| [coordinate, all_coordinates.take_while { |c| c != coordinate }] }
        else
          @upper_coordinates = []
          @other_coordinates = []
        end

        reset_procedure
        flash.notice = "Formulaire enregistré"
      else
        flash.alert = type_de_champ.errors.full_messages
      end
    end

    def update
      type_de_champ = @procedure.draft_revision.find_and_ensure_exclusive_use(params[:id])

      coordinate = @procedure.draft_revision.coordinate_for(type_de_champ)

      all_coordinates = @procedure.draft_revision.revision_types_de_champ_public.includes(:type_de_champ)

      index_of_current_coordinate = all_coordinates.index(coordinate)

      @upper_coordinates = all_coordinates.take(index_of_current_coordinate)

      if type_de_champ.update(type_de_champ_update_params)
        if params[:should_render]
          @coordinate = @procedure.draft_revision.coordinate_for(type_de_champ)
        end

        all_coordinates = @procedure.draft_revision.revision_types_de_champ_public.includes(:type_de_champ)

        @other_coordinates = all_coordinates.drop(index_of_current_coordinate + 1)
          .map { |coordinate| [coordinate, all_coordinates.take_while { |c| c != coordinate }] }

        reset_procedure
        flash.notice = "Formulaire enregistré"
      else
        flash.alert = type_de_champ.errors.full_messages
      end
    end

    def move
      flash.notice = "Formulaire enregistré"
      @procedure.draft_revision.move_type_de_champ(params[:id], params[:position].to_i)
    end

    def move_up
      flash.notice = "Formulaire enregistré"
      @coordinate = @procedure.draft_revision.move_up_type_de_champ(params[:id])

      all_coordinates = @procedure.draft_revision.revision_types_de_champ_public.includes(:type_de_champ)
      index_of_current_coordinate = all_coordinates.index(@coordinate)
      @upper_coordinates = all_coordinates.take(index_of_current_coordinate)

      @other_coordinates = all_coordinates.drop(index_of_current_coordinate + 1)
        .map { |coordinate| [coordinate, all_coordinates.take_while { |c| c != coordinate }] }
    end

    def move_down
      flash.notice = "Formulaire enregistré"
      @coordinate = @procedure.draft_revision.move_down_type_de_champ(params[:id])

      all_coordinates = @procedure.draft_revision.revision_types_de_champ_public.includes(:type_de_champ)
      index_of_current_coordinate = all_coordinates.index(@coordinate)
      @upper_coordinates = all_coordinates.take(index_of_current_coordinate)

      @other_coordinates = all_coordinates.take(index_of_current_coordinate)
        .map { |coordinate| [coordinate, all_coordinates.take_while { |c| c != coordinate }] }
    end

    def destroy
      @coordinate = @procedure.draft_revision.remove_type_de_champ(params[:id])
      reset_procedure
      flash.notice = "Formulaire enregistré"

      # TODO : si on supprime un target champ, il faut modifier les enfants
    end

    private

    def type_de_champ_create_params
      params
        .required(:type_de_champ)
        .permit(:type_champ, :parent_id, :private, :libelle, :after_id)
    end

    def type_de_champ_update_params
      params.required(:type_de_champ).permit(:type_champ,
        :libelle,
        :description,
        :mandatory,
        :drop_down_list_value,
        :drop_down_other,
        :drop_down_secondary_libelle,
        :drop_down_secondary_description,
        :piece_justificative_template,
        editable_options: [
          :cadastres,
          :unesco,
          :arretes_protection,
          :conservatoire_littoral,
          :reserves_chasse_faune_sauvage,
          :reserves_biologiques,
          :reserves_naturelles,
          :natura_2000,
          :zones_humides,
          :znieff
        ])
    end
  end
end
