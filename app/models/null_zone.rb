# frozen_string_literal: true

class NullZone
  include ActiveModel::Model
  ReflectionAssociation = Struct.new(:class_name)

  def procedures
    Procedure.where(zone: nil).where.not(published_at: nil).order(published_at: :desc)
  end

  def self.reflect_on_association(association)
    ReflectionAssociation.new("Procedure") if association == :procedures
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
