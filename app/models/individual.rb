class Individual < ActiveRecord::Base
  belongs_to :dossier

  validates_uniqueness_of :dossier_id
  validates :gender, presence: true, allow_nil: false, on: :update
  validates :nom, presence: true, allow_blank: false, allow_nil: false, on: :update
  validates :prenom, presence: true, allow_blank: false, allow_nil: false, on: :update
  validates :birthdate, format: { with: /\A\d{4}\-\d{2}\-\d{2}\z/, message: "La date n'est pas au format AAAA-MM-JJ" }, allow_nil: true

  before_validation :set_iso_date, if: -> { birthdate_changed? }

  private

  def set_iso_date
    if birthdate.present?
      self.birthdate = Date.parse(birthdate).iso8601
    end
  end
end
