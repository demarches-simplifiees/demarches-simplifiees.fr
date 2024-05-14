# frozen_string_literal: true

class APIEducation::API
  class ResourceNotFound < StandardError
  end

  def self.get_annuaire_education(id)
    call([API_EDUCATION_URL, 'search'].join('/'), 'fr-en-annuaire-education', { 'refine.identifiant_de_l_etablissement': id })
  end

  private

  def self.call(url, dataset, params)
    response = Typhoeus.get(url, params: { rows: 1, dataset: dataset }.merge(params))

    if response.success?
      response.body
    else
      message = response.code == 0 ? response.return_message : response.code.to_s
      Rails.logger.error "[APIEducation] Error on #{url}: #{message}"
      raise ResourceNotFound
    end
  end
end
