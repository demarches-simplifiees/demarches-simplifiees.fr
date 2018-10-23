class AssignTo < ApplicationRecord
  belongs_to :procedure
  belongs_to :gestionnaire
  has_one :procedure_presentation, dependent: :destroy

  def procedure_presentation_or_default_and_errors
    [procedure_presentation || build_procedure_presentation, nil]
  end
end
