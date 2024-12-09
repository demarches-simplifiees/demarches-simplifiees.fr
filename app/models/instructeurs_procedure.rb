# frozen_string_literal: true

class InstructeursProcedure < ApplicationRecord
  belongs_to :instructeur
  belongs_to :procedure
end
