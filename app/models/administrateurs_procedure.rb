# == Schema Information
#
# Table name: administrateurs_procedures
#
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  administrateur_id :bigint           not null
#  procedure_id      :bigint           not null
#
class AdministrateursProcedure < ApplicationRecord
  belongs_to :administrateur
  belongs_to :procedure
end
