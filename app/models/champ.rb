class Champ < ActiveRecord::Base
  belongs_to :dossier, touch: true
  belongs_to :type_de_champ
  has_many :commentaires

  delegate :libelle, :type_champ, :order_place, :mandatory, :description, :drop_down_list, to: :type_de_champ

  before_save :format_date_to_iso, if: Proc.new { type_champ == 'date' }
  before_save :serialize_datetime_if_needed, if: Proc.new { type_champ == 'datetime' }
  before_save :multiple_select_to_string, if: Proc.new { type_champ == 'multiple_drop_down_list' }

  after_save :internal_notification, if: Proc.new { !dossier.nil? }

  scope :updated_since?, -> (date) { where('champs.updated_at > ?', date) }

  def mandatory?
    mandatory
  end

  def data_provide
    return 'datepicker' if (type_champ == 'datetime') && !(BROWSER.value.chrome? || BROWSER.value.edge?)
    return 'typeahead' if type_champ == 'address'
  end

  def data_date_format
    ('dd/mm/yyyy' if type_champ == 'datetime')
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
    if type_champ == 'datetime' && !value.nil?
      if value.to_datetime.strftime(compare) == num
        return true
      end
    end
    false
  end

  def self.regions
    JSON.parse(Carto::GeoAPI::Driver.regions).sort_by { |e| e['nom'] }.inject([]) { |acc, liste| acc.push(liste['nom']) }
  end

  def self.departements
    JSON.parse(Carto::GeoAPI::Driver.departements).inject([]) { |acc, liste| acc.push(liste['code'] + ' - ' + liste['nom']) }.push('99 - Étranger')
  end

  def self.pays
    JSON.parse(Carto::GeoAPI::Driver.pays).inject([]) { |acc, liste| acc.push(liste['nom']) }
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

  def serialize_datetime_if_needed
    if (value =~ /=>/).present?
      date = begin
        hash_date = YAML.safe_load(value.gsub('=>', ': '))
        year, month, day, hour, minute = hash_date.values_at(1,2,3,4,5)
        DateTime.new(year, month, day, hour, minute).strftime("%d/%m/%Y %H:%M")
      rescue
        nil
      end

      self.value = date
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
