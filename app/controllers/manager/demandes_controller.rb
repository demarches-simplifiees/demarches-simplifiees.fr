module Manager
  class DemandesController < Manager::ApplicationController
    PIPEDRIVE_PEOPLE_URL = 'https://api.pipedrive.com/v1/persons'
    PIPEDRIVE_POSTE_ATTRIBUTE_ID = '33a790746f1713d712fe97bcce9ac1ca6374a4d6'
    PIPEDRIVE_DEV_ID = '2748449'

    def index
      @pending_demandes = pending_demandes
    end

    private

    def pending_demandes
      already_approved_emails = Administrateur
        .where(email: demandes.map { |d| d[:email] })
        .pluck(:email)

      demandes.reject { |demande| already_approved_emails.include?(demande[:email]) }
    end

    def demandes
      @demandes ||= fetch_demandes
    end

    def fetch_demandes
      params = {
        start: 0,
        limit: 500,
        user_id: PIPEDRIVE_DEV_ID,
        api_token: PIPEDRIVE_TOKEN
      }

      response = RestClient.get(PIPEDRIVE_PEOPLE_URL, { params: params })
      json = JSON.parse(response.body)

      json['data'].map do |datum|
        {
          person_id: datum['id'],
          nom: datum['name'],
          poste: datum[PIPEDRIVE_POSTE_ATTRIBUTE_ID],
          email: datum.dig('email', 0, 'value'),
          organisation: datum['org_name']
        }
      end
    end
  end
end
