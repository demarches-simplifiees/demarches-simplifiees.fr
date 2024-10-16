# frozen_string_literal: true

class ReferentielDePolynesie::BaserowAPI
  class << self
    SECRETS = Rails.application.secrets.baserow

    def search(domain_id, term)
      config = config(domain_id)
      search_field = config['Champ de recherche']
      params = { "filter__field_#{search_field}__contains" => term }
      url = rows_url(config['Table'])
      response = Typhoeus.get(url, headers: database_headers(config['Token']), params: params)
      pp response
      if response.success?
        JSON.parse(response.body, symbolize_names: true)[:results].map do
          { name: _1[:"field_#{search_field}"], id: _1[:id], domain: domain_id }
        end + [{ name: 'Autre', id: 0, domain: domain_id }]
      end
    end

    def available_tables
      response = Typhoeus.get(rows_url(SECRETS[:config_table]), headers: config_database_headers, params: default_params)
      if response.success?
        JSON.parse(response.body, symbolize_names: true)[:results]&.filter { _1[:Actif] }&.map do
          { name: _1[:Nom], id: _1[:id] }
        end
      end
    end

    def fetch_row(domain_id, row)
      return {} if row.to_i.zero?

      config = config(domain_id)
      response = Typhoeus.get(row_url(config['Table'], row), headers: database_headers(config['Token']))
      if response.success?
        model = fields(config)
        usager_fields = field_names(model, config['Champs usager'])
        instructeur_fields = field_names(model, config['Champs instructeur'])
        row = JSON.parse(response.body).filter { |name, _| name.start_with?('field_') }.transform_keys do |key|
          model[key[6..-1].to_i]
        end
        { usager_fields:, instructeur_fields:, row: }
      end
    end

    def field_names(model, field_ids)
      field_ids&.split(/,/)&.map(&:strip)&.map { model[_1.to_i] } || []
    end

    def config(row_id)
      response = Typhoeus.get(row_url(SECRETS[:config_table], row_id), headers: config_database_headers, params: default_params)
      response.success? ? JSON.parse(response.body) : nil
    end

    def fields(config)
      response = Typhoeus.get(list_database_table_fields(config['Table']), headers: database_headers(config['Token']))
      if response.success?
        JSON.parse(response.body).map { [_1['id'], _1['name']] }.to_h
      end
    end

    def rows_url(table_id) = "#{SECRETS[:url]}/api/database/rows/table/#{table_id}/"

    def row_url(table_id, row_id) = "#{rows_url(table_id)}#{row_id}/"

    def list_database_table_fields(table_id) = "#{SECRETS[:url]}/api/database/fields/table/#{table_id}/"

    def config_database_headers = database_headers(SECRETS[:token])

    def database_headers(token) = { 'Authorization' => "Token #{token}" }

    def default_params = { user_field_names: true }

    JWT_URL = "#{SECRETS[:url]}/api/user/token-auth/"
    MUTEX = Mutex.new

    def meta_headers
      credentials = { username: SECRETS[:user], password: SECRETS[:password] }
      response = Typhoeus.post(JWT_URL, body: credentials)
      if response.success?
        jwt = JSON.parse(response.body)['token']
        { authorization: "JWT #{jwt}" }
      end
    end
  end
end
