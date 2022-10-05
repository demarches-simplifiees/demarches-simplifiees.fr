# == Schema Information
#
# Table name: tags_procedures
#
#  id                    :bigint           not null, primary key
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  tag_id                :bigint           not null
#  procedure_id          :bigint           not null

class TagsProcedure < ApplicationRecord
  belongs_to :procedure
  belongs_to :tag
end
