# frozen_string_literal: true

describe Maintenance::HelpscoutDeleteOldConversationsTask do
  before do
    mock_helpscout_secrets
    travel_to DateTime.new(2024, 6, 5)
  end

  subject do
    described_class.new.tap { _1.status = "closed" }
  end

  describe '#enumerator_builder' do
    it "enumerates conversation ids" do
      VCR.use_cassette("helpscout_list_old_conversations") do |c|
        ids = subject.enumerator_builder(cursor: 0).to_a
        # Warning: calling a enumerable method always reinvoke the enumerable !
        # So immediately convert in array and run expectations on it

        # anonymize when recorded cassettes
        c.new_recorded_interactions.each do |interaction|
          interaction.request.body = anonymize_request(interaction)

          body = anonymize_response(interaction)
          interaction.response.body = body.to_json
        end

        expect(ids.count).to eq(27) # 25 first page + 2 next page
        expect(ids[0][0]).to eq(1910642153)
      end
    end
  end

  def anonymize_response(interaction)
    body = JSON.parse(interaction.response.body)

    Array(body.dig("_embedded", "conversations")).each do |conversation|
      conversation["createdBy"] = {}
      conversation["closedByUser"] = {}
      conversation["primaryCustomer"] = {}
      conversation["assignee"] = {}
      conversation["preview"] = "" # this also removes binary string
      conversation["cc"] = []
    end

    body["access_token"] = "redacted" if body.key?("access_token")

    body
  end

  def anonymize_request(interaction)
    body = interaction.request.body

    return body unless body.include?("client_secret")

    URI.decode_www_form(body).to_h.merge("client_id" => "1234", "client_secret" => "5678").to_query
  end

  def mock_helpscout_secrets
    ENV.stub(:fetch).and_call_original
    ENV.stub(:fetch).with('HELPSCOUT_MAILBOX_ID').and_return('9999')
    ENV.stub(:fetch).with('HELPSCOUT_CLIENT_ID').and_return('1234')
    ENV.stub(:fetch).with('HELPSCOUT_CLIENT_SECRET').and_return('5678')
  end
end
