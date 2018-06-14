class Champ < ApplicationRecord
  belongs_to :dossier, touch: true
  belongs_to :type_de_champ, inverse_of: :champ
  has_many :commentaires
  has_one_attached :piece_justificative_file
  has_one :virus_scan

  delegate :libelle, :type_champ, :order_place, :mandatory?, :description, :drop_down_list, to: :type_de_champ

  scope :updated_since?, -> (date) { where('champs.updated_at > ?', date) }
  scope :public_only, -> { where(private: false) }
  scope :private_only, -> { where(private: true) }

  PIECE_JUSTIFICATIVE_FILE_MAX_SIZE = 200.megabytes

  PIECE_JUSTIFICATIVE_FILE_ACCEPTED_FORMATS = [
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "application/vnd.ms-powerpoint",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "application/vnd.oasis.opendocument.text",
    "application/vnd.oasis.opendocument.presentation",
    "application/vnd.oasis.opendocument.spreadsheet",
    "image/png",
    "image/jpeg"
  ]

  def public?
    !private?
  end

  def same_hour?(num)
    same_date? num, '%H'
  end

  def same_minute?(num)
    same_date? num, '%M'
  end

  def mandatory_and_blank?
    mandatory? && value.blank?
  end

  def same_date?(num, compare)
    if type_champ == 'datetime' && value.present?
      if value.to_datetime.strftime(compare) == num
        return true
      end
    end
    false
  end

  def self.regions
    JSON.parse(Carto::GeoAPI::Driver.regions).sort_by { |e| e['nom'] }.pluck("nom")
  end

  def self.departements
    JSON.parse(Carto::GeoAPI::Driver.departements).map { |liste| "#{liste['code']} - #{liste['nom']}" }.push('99 - Étranger')
  end

  def self.pays
    JSON.parse(Carto::GeoAPI::Driver.pays).pluck("nom")
  end

  def to_s
    if value.present?
      case type_champ
      when 'date'
        Date.parse(value).strftime('%d/%m/%Y')
      when 'multiple_drop_down_list'
        drop_down_list.selected_options_without_decorator(self).join(', ')
      else
        value.to_s
      end
    else
      ''
    end
  end

  def for_export
    if value.present?
      case type_champ
      when 'textarea'
        ActionView::Base.full_sanitizer.sanitize(value)
      when 'yes_no'
        value == 'true' ? 'oui' : 'non'
      when 'multiple_drop_down_list'
        drop_down_list.selected_options_without_decorator(self).join(', ')
      else
        value
      end
    else
      nil
    end
  end

  def piece_justificative_file_errors
    errors = []

    if piece_justificative_file.attached? && piece_justificative_file.previous_changes.present?
      if piece_justificative_file.blob.byte_size > PIECE_JUSTIFICATIVE_FILE_MAX_SIZE
        errors << "Le fichier #{piece_justificative_file.filename.to_s} est trop lourd, il doit faire au plus #{PIECE_JUSTIFICATIVE_FILE_MAX_SIZE.to_s(:human_size, precision: 2)}"
      end

      if !piece_justificative_file.blob.content_type.in?(PIECE_JUSTIFICATIVE_FILE_ACCEPTED_FORMATS)
        errors << "Le fichier #{piece_justificative_file.filename.to_s} est dans un format que nous n'acceptons pas"
      end

      # FIXME: add Clamav check
    end

    if errors.present?
      piece_justificative_file.purge
    end

    errors
  end
end
