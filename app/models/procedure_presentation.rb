class ProcedurePresentation < ApplicationRecord
  belongs_to :assign_to

  def filters
    JSON.parse(read_attribute(:filters))
  end
end
