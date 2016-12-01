class ProfileDecorator < Draper::Decorator
  delegate_all

  def gender_fr
    return 'Mr' if gender == 'male'
    return 'Mme' if gender == 'female'
  end

  def birthdate_fr
    birthdate.try { strftime('%d/%m/%Y') }
  end

  def born_on_date_fr
    birthdate.try do |date|
      date = date.strftime('%d/%m/%Y')
      case gender
      when 'male'
        "Né le #{date}"
      when 'female'
        "Née le #{date}"
      else
        "Né(e) le #{date}"
      end
    end
  end

  def picture_url
    if Features.remote_storage
      File.join(STORAGE_URL, picture.path)
    else
      picture.url
    end
  end
end
