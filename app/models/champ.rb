class Champ < ApplicationRecord
  belongs_to :dossier, touch: true
  belongs_to :type_de_champ, inverse_of: :champ
  has_many :commentaires
  has_one_attached :piece_justificative_file

  delegate :libelle, :libelle_for_export, :type_champ, :order_place, :mandatory?, :description, :drop_down_list, to: :type_de_champ

  before_save :format_date_to_iso, if: Proc.new { type_champ == 'date' }
  before_save :format_datetime, if: Proc.new { type_champ == 'datetime' }
  before_save :multiple_select_to_string, if: Proc.new { type_champ == 'multiple_drop_down_list' }

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
    if type_champ == 'piece_justificative'
      mandatory? && !piece_justificative_file.attached?
    else
      mandatory? && value.blank?
    end
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

  private

  def format_date_to_iso
    date = begin
      Date.parse(value).iso8601
    rescue
      nil
    end
    self.value = date
  end

  def format_datetime
    if (value =~ /=>/).present?
      date = begin
        hash_date = YAML.safe_load(value.gsub('=>', ': '))
        year, month, day, hour, minute = hash_date.values_at(1,2,3,4,5)
        DateTime.new(year, month, day, hour, minute).strftime("%d/%m/%Y %H:%M")
      rescue
        nil
      end
      self.value = date
    elsif /^\d{2}\/\d{2}\/\d{4}\s\d{2}:\d{2}$/.match?(value) # old browsers can send with dd/mm/yyyy hh:mm format
      self.value = DateTime.parse(value, "%d/%m/%Y %H:%M").strftime("%Y-%m-%d %H:%M")
    elsif !(/^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}$/.match?(value)) # a datetime not correctly formatted should not be stored
      self.value = nil
    end
  end

  def multiple_select_to_string
    if value.present?
      json = JSON.parse(value)
      if json == ['']
        self.value = nil
      else
        json = json - ['']
        self.value = json.to_s
      end
    end
  end
end
