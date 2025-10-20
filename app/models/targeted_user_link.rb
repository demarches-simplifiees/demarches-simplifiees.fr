# frozen_string_literal: true

class TargetedUserLink < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :target_model, polymorphic: true, optional: false

  enum :target_context, { avis: 'avis', invite: 'invite' }

  def invalid_signed_in_user?(signed_in_user)
    signed_in_user && signed_in_user.email != target_email
  end

  def target_email
    case target_context
    when 'avis'
      user.email
    when 'invite'
      invite = find_invite!
      invite.user&.email || invite.email
    else
      raise 'invalid target_context'
    end
  end

  def redirect_url(url_helper, confirmation_token = nil)
    case target_context
    when "invite"
      invite = find_invite!

      user = User.find_by(email: target_email)
      user&.active? ?
        url_helper.invite_path(invite) :
        url_helper.invite_path(invite, params: { email: invite.email })
    when "avis"

      avis = target_model
      params = { email: avis.expert.email }
      if !avis.expert.user.active?
        params = params.merge(confirmation_token: confirmation_token) if confirmation_token.present?
        url_helper.sign_up_expert_avis_path(avis.procedure, avis, **params)
      elsif avis.expert.user.unverified_email?
        params = params.merge(token: confirmation_token) if confirmation_token.present?
        url_helper.users_confirm_email_url(avis.procedure, avis, **params)
      else
        url_helper.expert_avis_path(avis.procedure, avis)
      end
    end
  end

  private

  def find_invite!
    target_model || (fail ActiveRecord::RecordNotFound.new("Could not find Invite with id `#{target_model_id}`"))
  end
end
