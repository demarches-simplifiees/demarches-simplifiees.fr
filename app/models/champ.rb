class Champ < ActiveRecord::Base
  belongs_to :dossier, touch: true
  belongs_to :type_de_champ
  has_many :commentaires

  delegate :libelle, :type_champ, :order_place, :mandatory?, :description, :drop_down_list, to: :type_de_champ

  before_save :format_date_to_iso, if: Proc.new { type_champ == 'date' }
  before_save :format_datetime, if: Proc.new { type_champ == 'datetime' }
  before_save :multiple_select_to_string, if: Proc.new { type_champ == 'multiple_drop_down_list' }

  after_save :internal_notification, if: Proc.new { dossier.present? }

  scope :updated_since?, -> (date) { where('champs.updated_at > ?', date) }

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
    if typed?
      typed_string_value
    elsif value.present?
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
    if typed?
      typed_for_export
    elsif value.present?
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

  def value
    if typed?
      cast_typed_value
    else
      read_attribute(:value)
    end
  end

  def value=(value)
    write_attribute(:value, value)

    case type_champ
    when 'checkbox', 'engagement'
      self.boolean_value = value === 'on'
      self.typed = true
    when 'yes_no'
      if value == 'true'
        self.boolean_value = true
      elsif value == 'false'
        self.boolean_value = false
      end
      self.typed = true
    end
  end

  def typed_value
    case type_champ
    when 'yes_no', 'checkbox', 'engagement'
      boolean_value
    else
      value
    end
  end

  def formatted_typed_value
    if boolean? || non_nil_trivalent?
      typed_value ? 'Oui' : 'Non'
    else
      typed_string_value
    end
  end

  def boolean?
    type_champ.in? ['checkbox', 'engagement']
  end

  def trivalent?
    type_champ == 'yes_no'
  end

  def yes?
    if trivalent?
      typed? ? typed_value == true : value == 'true'
    end
  end

  def no?
    if trivalent?
      typed? ? typed_value == false : value == 'false'
    end
  end

  def checked?
    if boolean?
      typed? ? typed_value : value == 'on'
    end
  end

  private

  def non_nil_trivalent?
    trivalent? && !read_attribute(:value).nil?
  end

  def cast_typed_value
    case type_champ
    when 'yes_no'
      if boolean_value.nil?
        nil
      else
        boolean_value ? 'true' : 'false'
      end
    when 'checkbox', 'engagement'
      boolean_value ? 'on' : nil
    else
      read_attribute(:value)
    end
  end

  def typed_string_value
    if boolean? || non_nil_trivalent?
      typed_value.to_s
    elsif value.present?
      typed_value.to_s
    else
      ''
    end
  end

  def typed_for_export
    if boolean? || non_nil_trivalent?
      typed_value ? 'oui' : 'non'
    elsif value.present?
      typed_value
    else
      nil
    end
  end

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

  def internal_notification
    if dossier.state != 'brouillon'
      if type == 'ChampPublic'
        NotificationService.new('champs', self.dossier.id, self.libelle).notify
      else
        NotificationService.new('annotations_privees', self.dossier.id, self.libelle).notify
      end
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
