class Champ < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :type_de_champ
  has_many :commentaires

  delegate :libelle, :type_champ, :order_place, :mandatory, :description, :drop_down_list, to: :type_de_champ

  after_save :internal_notification

  def mandatory?
    mandatory
  end

  def data_provide
    return 'datepicker' if (type_champ == 'datetime' || type_champ == 'date') && !(BROWSER.value.chrome? || BROWSER.value.edge?)
    return 'typeahead' if type_champ == 'address'
  end

  def data_date_format
    ('dd/mm/yyyy' if type_champ == 'datetime' || type_champ == 'date')
  end

  def same_hour? num
    same_date? num, '%H'
  end

  def same_minute? num
    same_date? num, '%M'
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

  def internal_notification
    unless dossier.state == 'draft'
      NotificationService.new('champs', self.dossier.id, self.libelle).notify
    end
  end
end
