# frozen_string_literal: true

class ModuleAPICarto < ApplicationRecord
  belongs_to :procedure, optional: false
end
