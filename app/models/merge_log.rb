# == Schema Information
#
# Table name: merge_logs
#
#  id              :bigint           not null, primary key
#  from_user_email :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  from_user_id    :bigint           not null
#  user_id         :bigint           not null
#
class MergeLog < ApplicationRecord
  belongs_to :user
end
