class AssignTo < ActiveRecord::Base
  belongs_to :procedure
  belongs_to :gestionnaire
  has_one :procedure_presentation, dependent: :destroy

  after_create :create_procedure_presentation

  private

  def create_procedure_presentation
    ProcedurePresentation.create(assign_to_id: id)
  end
end
