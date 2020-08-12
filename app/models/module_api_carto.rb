# == Schema Information
#
# Table name: module_api_cartos
#
#  id                     :integer          not null, primary key
#  cadastre               :boolean          default(FALSE)
#  migrated               :boolean
#  quartiers_prioritaires :boolean          default(FALSE)
#  use_api_carto          :boolean          default(FALSE)
#  created_at             :datetime
#  updated_at             :datetime
#  procedure_id           :integer
#
class ModuleAPICarto < ApplicationRecord
  belongs_to :procedure
end
