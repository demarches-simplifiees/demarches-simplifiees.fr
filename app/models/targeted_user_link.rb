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
#  user_id           :bigint           not null
#
class TargetedUserLink < ApplicationRecord
  belongs_to :user
  belongs_to :target_model, polymorphic: true, optional: false

  enum target_context: { :avis => 'avis' }

  def invalid_signed_in_user?(signed_in_user)
    signed_in_user && signed_in_user != self.user
  end

  def redirect_url(url_helper)
    case target_context
    when "avis"
      avis = target_model
      avis.expert.user.active? ?
        url_helper.expert_avis_path(avis.procedure, avis) :
        url_helper.sign_up_expert_avis_path(avis.procedure, avis, email: avis.expert.email)
    end
  end
end
