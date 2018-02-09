class Champ < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  belongs_to :dossier, touch: true
  belongs_to :type_de_champ, inverse_of: :champ
  has_many :commentaires

  delegate :libelle, :type_champ, :order_place, :mandatory, :description, :drop_down_list, to: :type_de_champ

  before_save :format_date_to_iso, if: Proc.new { type_champ == 'date' }
  before_save :format_datetime, if: Proc.new { type_champ == 'datetime' }
  before_save :multiple_select_to_string, if: Proc.new { type_champ == 'multiple_drop_down_list' }

  scope :updated_since?, -> (date) { where('champs.updated_at > ?', date) }
  scope :public_only, -> { where.not(type: 'ChampPrivate').or(where(private: [false, nil])) }
  scope :private_only, -> { where(type: 'ChampPrivate').or(where(private: true)) }

  def mandatory?
    mandatory
  end

  def public?
    !private?
  end

  def private?
    super || type == 'ChampPrivate'
  end

  def same_hour? num
    same_date? num, '%H'
  end

  def same_minute? num
    same_date? num, '%M'
  end

  def mandatory_and_blank?
    mandatory? && value.blank?
  end

  def same_date? num, compare
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
    elsif /^\d{2}\/\d{2}\/\d{4}\s\d{2}:\d{2}$/ =~ value # old browsers can send with dd/mm/yyyy hh:mm format
      self.value = DateTime.parse(value, "%d/%m/%Y %H:%M").strftime("%Y-%m-%d %H:%M")
    elsif !(/^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}$/ =~ value) # a datetime not correctly formatted should not be stored
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
