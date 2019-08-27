class GroupeInstructeur < ApplicationRecord
  DEFAULT_LABEL = 'défaut'
  belongs_to :procedure
end
