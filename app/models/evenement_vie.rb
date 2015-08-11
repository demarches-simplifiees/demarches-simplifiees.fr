class EvenementVie < ActiveRecord::Base
  #TODO a tester
  def self.for_admi_facile
    where(use_admi_facile: true)
  end
end
