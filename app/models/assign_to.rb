class AssignTo < ActiveRecord::Base
  belongs_to :procedure
  belongs_to :gestionnaire
end
