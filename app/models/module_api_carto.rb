class ModuleAPICarto < ActiveRecord::Base
  enum name: {'quartiers_prioritaires' => 'quartiers_prioritaires'}

  belongs_to :procedure

  validates :name, presence: true, allow_blank: false, allow_nil: false
end
