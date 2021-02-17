# == Schema Information
#
# Table name: experts
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Expert < ApplicationRecord
  has_one :user

  def email
    user.email
  end
end
