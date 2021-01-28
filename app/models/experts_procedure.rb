# == Schema Information
#
# Table name: experts_procedures
#
#  id                    :bigint           not null, primary key
#  allow_decision_access :boolean          default(FALSE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  expert_id             :bigint           not null
#  procedure_id          :bigint           not null
#
class ExpertsProcedure < ApplicationRecord
  belongs_to :expert
  belongs_to :procedure

  has_many :avis, dependent: :destroy

  def email_to_display
    expert&.email
  end

  def self.invited_experts(procedure)
    joins(:expert)
      .where(procedure: procedure)
      .sort
  end
end
