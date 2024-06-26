class Conditions::InstructeurFilterComponent < Conditions::ConditionsComponent
  include Logic

  def initialize(procedure:, procedure_presentation:, statut:)
    @procedure = procedure
    @revision = procedure.published_revision
    @procedure_presentation = procedure_presentation
    @condition = procedure_presentation.conditions
    @source_tdcs = @revision.types_de_champ_for # in fact, should take all prtdc from all revision
  end

  private

  def input_prefix
    'procedure_presentation[condition_form]'
  end

  def input_id_for(name, row_index)
    "#{@revision.id}-#{name}-#{row_index}"
  end

  def delete_condition_path(row_index)
    delete_row_instructeur_procedure_presentation_path(@procedure.id, @procedure_presentation.id, row_index:)
  end

  def add_condition_path
    add_row_instructeur_procedure_presentation_path(@procedure.id, @procedure_presentation.id)
  end
end
