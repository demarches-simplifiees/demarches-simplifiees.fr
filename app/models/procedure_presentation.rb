class ProcedurePresentation < ApplicationRecord
  belongs_to :assign_to

  def sort
    JSON.parse(read_attribute(:sort))
  end

  def filters
    JSON.parse(read_attribute(:filters))
  end
end
