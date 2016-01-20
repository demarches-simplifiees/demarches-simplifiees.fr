class Cadastre < ActiveRecord::Base
  belongs_to :dossier

  def geometry
    JSON.parse(read_attribute(:geometry))
  end
end
