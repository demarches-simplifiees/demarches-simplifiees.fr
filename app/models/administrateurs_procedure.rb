# frozen_string_literal: true

class AdministrateursProcedure < ApplicationRecord
  belongs_to :administrateur
  belongs_to :procedure
end
