class Individual < ApplicationRecord
  belongs_to :dossier

  validates :dossier_id, uniqueness: true
  validates :gender, presence: true, allow_nil: false, on: :update
  validates :nom, presence: true, allow_blank: false, allow_nil: false, on: :update
  validates :prenom, presence: true, allow_blank: false, allow_nil: false, on: :update
  validates :birthdate, format: { with: /\A\d{4}\-\d{2}\-\d{2}\z/, message: "La date n'est pas au format AAAA-MM-JJ" }, allow_nil: true

  before_validation :set_iso_date, if: -> { birthdate_changed? }
  before_save :save_birthdate_in_datetime_format

  private

  def set_iso_date
    if birthdate.present? &&
        birthdate =~ /\A\d{2}\/\d{2}\/\d{4}\z/
      self.birthdate = Date.parse(birthdate).iso8601
    end
  end

  def save_birthdate_in_datetime_format
    if birthdate.present?
      begin
        self.second_birthdate = Date.parse(birthdate)
      rescue
      end
    end
  end
end
