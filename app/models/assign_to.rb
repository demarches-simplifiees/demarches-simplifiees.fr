class AssignTo < ApplicationRecord
  belongs_to :procedure
  belongs_to :gestionnaire
  has_one :procedure_presentation, dependent: :destroy

  def procedure_presentation_or_default
    procedure_presentation || build_procedure_presentation
  end
end
