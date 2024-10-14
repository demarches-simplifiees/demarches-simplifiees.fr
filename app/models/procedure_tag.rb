# frozen_string_literal: true

class ProcedureTag < ApplicationRecord
  has_and_belongs_to_many :procedures

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
