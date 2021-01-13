class ApiEducation::API
  class ResourceNotFound < StandardError
  end

  def self.search_annuaire_education(search_term)
    call([API_EDUCATION_URL, 'search'].join('/'), 'fr-en-annuaire-education', { q: search_term })
  end

  private

  def self.call(url, dataset, params)
    response = Typhoeus.get(url, params: { rows: 1, dataset: dataset }.merge(params))

    if response.success?
      response.body
    else
      message = response.code == 0 ? response.return_message : response.code.to_s
      Rails.logger.error "[ApiEducation] Error on #{url}: #{message}"
      raise ResourceNotFound
    end
  end
end
