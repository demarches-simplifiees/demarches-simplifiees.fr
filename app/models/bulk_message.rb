# frozen_string_literal: true

class BulkMessage < ApplicationRecord
  belongs_to :instructeur
  belongs_to :procedure

  attr_accessor :without_group
end
