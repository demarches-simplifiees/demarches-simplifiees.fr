class Champ < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :type_de_champ
  has_many :commentaires

  delegate :libelle, :type_champ, :order_place, :mandatory, :description, :drop_down_list, to: :type_de_champ

  before_save :format_date_to_iso, if: Proc.new { type_champ == 'date' }
  after_save :internal_notification, if: Proc.new { !dossier.nil? }

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

  private

  def format_date_to_iso
    date = begin
      Date.parse(value).iso8601
    rescue
      nil
    end
    self.value = date
  end

  def internal_notification
    unless dossier.state == 'draft'
      NotificationService.new('champs', self.dossier.id, self.libelle).notify
    end
  end
end
