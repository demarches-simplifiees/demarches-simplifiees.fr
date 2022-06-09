class ConditionsController < ApplicationController
  include Logic

  def update
    condition = ConditionForm.new(condition_params).to_condition
    tdc.update(condition: condition)

    @procedure = procedure
    @coordinate = procedure.draft_revision.coordinate_for(tdc)
    @upper_coordinates = procedure.draft_revision.revision_types_de_champ_public.includes(:type_de_champ).take_while { |c| c != @coordinate }

    render 'administrateurs/types_de_champ/update.turbo_stream.haml'
  end

  def add_row
    condition = tdc.condition

    empty_condition = empty_operator(empty, empty)

    new_condition = if condition.nil?
      empty_condition
    elsif [And, Or].include?(condition.class)
      condition.class.new(condition.operands << empty_condition)
    else
      Logic::And.new([condition, empty_condition])
    end

    tdc.update(condition: new_condition)

    @procedure = procedure
    @coordinate = procedure.draft_revision.coordinate_for(tdc)
    @upper_coordinates = procedure.draft_revision.revision_types_de_champ_public.includes(:type_de_champ).take_while { |c| c != @coordinate }

    render 'administrateurs/types_de_champ/update.turbo_stream.haml'
  end

  def delete_row
    condition = ConditionForm.new(condition_params).delete_row(row_index).to_condition
    tdc.update(condition: condition)

    @procedure = procedure
    @coordinate = procedure.draft_revision.coordinate_for(tdc)
    @upper_coordinates = procedure.draft_revision.revision_types_de_champ_public.includes(:type_de_champ).take_while { |c| c != @coordinate }

    render 'administrateurs/types_de_champ/update.turbo_stream.haml'
  end

  def delete
    tdc.update(condition: nil)

    @procedure = procedure
    @coordinate = procedure.draft_revision.coordinate_for(tdc)
    @upper_coordinates = procedure.draft_revision.revision_types_de_champ_public.includes(:type_de_champ).take_while { |c| c != @coordinate }

    render 'administrateurs/types_de_champ/update.turbo_stream.haml'
  end

  def change_champ
    condition = ConditionForm.new(condition_params).change_champ(row_index).to_condition
    tdc.update(condition: condition)

    @procedure = procedure
    @coordinate = procedure.draft_revision.coordinate_for(tdc)
    @upper_coordinates = procedure.draft_revision.revision_types_de_champ_public.includes(:type_de_champ).take_while { |c| c != @coordinate }

    render 'administrateurs/types_de_champ/update.turbo_stream.haml'
  end

  private

  def tdc
    @tdc ||= TypeDeChamp.find(params[:id])
  end

  def procedure
    tdc.procedure
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
