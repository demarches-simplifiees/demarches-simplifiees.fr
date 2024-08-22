# frozen_string_literal: true

class BulkMessage < ApplicationRecord
  belongs_to :instructeur
  belongs_to :procedure
end
