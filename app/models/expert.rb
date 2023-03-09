# == Schema Information
#
# Table name: experts
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
class Expert < ApplicationRecord
  belongs_to :user
  has_many :experts_procedures
  has_many :procedures, through: :experts_procedures
  has_many :avis, through: :experts_procedures
  has_many :dossiers, through: :avis
  has_many :commentaires, inverse_of: :expert, dependent: :nullify

  default_scope { eager_load(:user) }

  def email
    user.email
  end

  def self.by_email(email)
    Expert.eager_load(:user).find_by(users: { email: email })
  end

  def avis_summary
    if @avis_summary.present?
      @avis_summary
    else
      query = <<~EOF
        COUNT(*) FILTER (where answer IS NULL AND dossiers.hidden_by_administration_at IS NULL) AS unanswered,
        COUNT(*) AS total
      EOF
      result = avis.select(query)[0]
      @avis_summary = { unanswered: result.unanswered, total: result.total }
    end
  end

  def merge(old_expert)
    return if old_expert.nil?

    procedure_with_new, procedure_without_new = old_expert
      .procedures
      .partition { |p| p.experts.exists?(id) }

    ExpertsProcedure
      .where(expert_id: old_expert.id, procedure: procedure_without_new)
      .update_all(expert_id: id)

    ExpertsProcedure
      .where(expert_id: old_expert.id, procedure: procedure_with_new)
      .destroy_all

    old_expert.commentaires.update_all(expert_id: id)

    Avis
      .where(claimant_id: old_expert.id, claimant_type: Expert.name)
      .update_all(claimant_id: id)
  end
end
