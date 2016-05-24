class Gestionnaire < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_and_belongs_to_many :administrateurs

  has_many :assign_to
  has_many :procedures, through: :assign_to
  has_many :dossiers, through: :procedures

  def dossiers_filter
    dossiers.where(procedure_id: procedure_filter_list)
  end

  def procedure_filter_list
    procedure_filter.empty? ? procedures.pluck(:id) : procedure_filter
  end
end
