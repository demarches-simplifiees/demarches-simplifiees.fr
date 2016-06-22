class Champ < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :type_de_champ

  delegate :libelle, :type_champ, :order_place, :mandatory, :description, to: :type_de_champ

  def mandatory?
    mandatory
  end

  def data_provide
    return 'datepicker' if type_champ == 'datetime' || type_champ == 'date'
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
end
