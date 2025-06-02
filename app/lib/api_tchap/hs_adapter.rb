# frozen_string_literal: true

class APITchap::HsAdapter
  def initialize(email)
    @email = email
  end

  def to_hs
    data_source[:hs]
  end

  private

  def data_source
    @data_source ||= JSON.parse(APITchap::API.get_hs(@email), symbolize_names: true)
  end
end
