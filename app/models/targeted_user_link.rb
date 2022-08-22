# == Schema Information
#
# Table name: targeted_user_links
#
#  id                :uuid             not null, primary key
#  target_context    :string           not null
#  target_model_type :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  target_model_id   :bigint           not null
#  user_id           :bigint
#
class TargetedUserLink < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :target_model, polymorphic: true, optional: false

  enum target_context: { avis: 'avis', invite: 'invite' }

  def invalid_signed_in_user?(signed_in_user)
    signed_in_user && signed_in_user.email != target_email
  end

  def target_email
    case target_context
    when 'avis'
      user.email
    when 'invite'
      target_model.user&.email || target_model.email
    else
      raise 'invalid target_context'
    end
  end

  def redirect_url(url_helper)
    case target_context
    when "invite"
      invite = target_model
      user = User.find_by(email: target_email)
      user&.active? ?
      url_helper.invite_path(invite) :
      url_helper.invite_path(invite, params: { email: invite.email })
    when "avis"
      avis = target_model
      avis.expert.user.active? ?
        url_helper.expert_avis_path(avis.procedure, avis) :
        url_helper.sign_up_expert_avis_path(avis.procedure, avis, email: avis.expert.email)
    end
  end
end
