class ProcedurePath < ApplicationRecord
  validates :path, format: { with: /\A[a-z0-9_\-]{3,50}\z/ }, presence: true, allow_blank: false, allow_nil: false
  validates :administrateur_id, presence: true, allow_blank: false, allow_nil: false
  validates :procedure_id, presence: true, allow_blank: false, allow_nil: false

  belongs_to :test_procedure, class_name: 'Procedure'
  belongs_to :procedure
  belongs_to :administrateur

  def self.find_with_procedure(procedure)
    where(procedure: procedure).or(where(test_procedure: procedure)).last
  end

  def hide!(procedure)
    if self.procedure == procedure
      update(procedure: nil)
    end
    if self.test_procedure == procedure
      update(test_procedure: nil)
    end
    if procedure.nil? && test_procedure.nil?
      destroy
    end
  end
end
