class AssignTo < ActiveRecord::Base
  belongs_to :procedure
  belongs_to :gestionnaire
  has_one :procedure_presentation, dependent: :destroy

  def procedure_presentation_or_default
    procedure_presentation ||= ProcedurePresentation.new(assign_to_id: id)
  end
end
