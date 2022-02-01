class NullZone
  include ActiveModel::Model

  def procedures
    Procedure.where(zone: nil).where.not(published_at: nil).order(published_at: :desc)
  end

  def self.reflect_on_association(association)
    OpenStruct.new(class_name: "Procedure") if association == :procedures
  end

  def label
    "non renseignée"
  end

  def id
    -1
  end

  def acronym
    "NA"
  end

  def created_at
    "NA"
  end

  def updated_at
    "NA"
  end
end
