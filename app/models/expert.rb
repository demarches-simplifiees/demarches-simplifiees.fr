# frozen_string_literal: true

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
        COUNT(*) FILTER (where answer IS NULL AND dossiers.hidden_by_administration_at IS NULL AND dossiers.state not in ('accepte', 'refuse', 'sans_suite')) AS unanswered,
        COUNT(*) AS total
      EOF
      result = avis.select(query)[0]
      @avis_summary = { unanswered: result.unanswered, total: result.total }
    end
  end

  def self.autocomplete_mails(procedure)
    procedure_experts = Expert
      .joins(:experts_procedures, :user)
      .where(experts_procedures: { procedure: procedure })

    suggested_expert = if procedure.experts_require_administrateur_invitation?
      procedure_experts
        .where(experts_procedures: { revoked_at: nil })
    else
      procedure_experts
        .where.not(users: { last_sign_in_at: nil })
        .or(procedure_experts.where(users: { created_at: 1.day.ago.. }))
    end

    suggested_expert
      .pluck('users.email')
      .sort
  end

  def merge(old_expert)
    return if old_expert.nil?

    procedure_with_new, procedure_without_new = old_expert
      .procedures
      .with_discarded
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
