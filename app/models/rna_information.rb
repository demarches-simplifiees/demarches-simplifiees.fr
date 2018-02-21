class RNAInformation < ActiveRecord::Base
  belongs_to :entreprise

  validates :association_id, presence: true, allow_blank: false, allow_nil: false

  def rna=(id)
    write_attribute(:association_id, id)
  end
end
