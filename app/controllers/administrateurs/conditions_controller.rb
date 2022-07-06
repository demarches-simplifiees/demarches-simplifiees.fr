module Administrateurs
  class ConditionsController < AdministrateurController
    include Logic

    before_action :retrieve_procedure, :retrieve_coordinate_and_uppers

    def update
      condition = condition_form.to_condition
      tdc.update!(condition: condition)

      render 'administrateurs/types_de_champ/update.turbo_stream.haml'
    end

    def add_row
      condition = Logic.add_empty_condition_to(tdc.condition)
      tdc.update!(condition: condition)

      render 'administrateurs/types_de_champ/update.turbo_stream.haml'
    end

    def delete_row
      condition = condition_form.delete_row(row_index).to_condition
      tdc.update!(condition: condition)

      render 'administrateurs/types_de_champ/update.turbo_stream.haml'
    end

    def destroy
      tdc.update!(condition: nil)

      render 'administrateurs/types_de_champ/update.turbo_stream.haml'
    end

    def change_targeted_champ
      condition = condition_form.change_champ(row_index).to_condition
      tdc.update!(condition: condition)

      render 'administrateurs/types_de_champ/update.turbo_stream.haml'
    end

    private

    def condition_form
      ConditionForm.new(condition_params)
    end

    def retrieve_coordinate_and_uppers
      @coordinate = draft_revision.coordinate_for(tdc)
      @upper_coordinates = draft_revision
        .revision_types_de_champ_public
        .includes(:type_de_champ)
        .take_while { |c| c != @coordinate }
    end

    def tdc
      @tdc ||= draft_revision.find_and_ensure_exclusive_use(params[:stable_id])
    end

    def draft_revision
      @procedure.draft_revision
    end

    def condition_params
      params
        .require(:type_de_champ)
        .require(:condition_form)
        .permit(:top_operator_name, rows: [:targeted_champ, :operator_name, :value])
    end

    def row_index
      params[:row_index].to_i
    end
  end
end
