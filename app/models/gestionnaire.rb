class Gestionnaire < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  belongs_to :administrateur

  has_many :procedures, through: :administrateur
  has_many :dossiers, through: :procedures
end
