# frozen_string_literal: true

describe Dolist::API do
  after(:each) do
    Dolist::API.limit_reset_at.del
  end

  let(:headers) { { "X-Rate-Limit-Remaining" => "15", "X-Rate-Limit-Reset" => (Time.current + 3600).to_i.to_s } }

  let(:mail) do
    Mail.new do
      to 'test@example.com'
      from 'sender@example.com'
      subject 'Test'
      body 'Test body'
      header['X-Dolist-Message-Name'] = 'Test Message'
    end
  end

  describe ".save_rate_limit_headers" do
    it "saves the rate limit headers" do
      Dolist::API.save_rate_limit_headers(headers)
      expect(Dolist::API.limit_remaining.value).to eq(15)
      expect(Dolist::API.limit_reset_at.value).to be_within(1.second).of(Time.zone.at(headers["X-Rate-Limit-Reset"].to_i / 1_000))
    end
  end

  describe ".near_rate_limit?" do
    context "when limit_remaining is nil" do
      it "returns nil" do
        expect(Dolist::API.near_rate_limit?).to eq(false)
      end
    end

    context "when limit_remaining is less than 100" do
      it "returns true" do
        Dolist::API.limit_reset_at.value = 1.minute.from_now
        Dolist::API.limit_remaining.value = 15
        expect(Dolist::API.near_rate_limit?).to eq(true)
      end
    end

    context "when limit_remaining is 100 or more" do
      it "returns false" do
        Dolist::API.limit_reset_at.value = 1.minute.from_now
        Dolist::API.limit_remaining.value = 105
        expect(Dolist::API.near_rate_limit?).to eq(false)
      end
    end
  end

  describe ".rate_limited?" do
    context "when limits are not set" do
      it "returns false" do
        expect(Dolist::API.rate_limited?).to be false
      end
    end

    context "when rate limit is reached" do
      it "returns true if reset time is in future" do
        Dolist::API.limit_remaining.value = 0
        Dolist::API.limit_reset_at.value = 1.hour.from_now
        expect(Dolist::API.rate_limited?).to eq true
      end

      it "returns false if reset time is in past" do
        Dolist::API.limit_remaining.value = 0
        Dolist::API.limit_reset_at.value = 1.hour.ago
        expect(Dolist::API.rate_limited?).to eq false
      end
    end

    context "when rate limit is not reached" do
      it "returns false" do
        Dolist::API.limit_remaining.value = 1
        Dolist::API.limit_reset_at.value = 1.hour.from_now
        expect(Dolist::API.rate_limited?).to eq false
      end
    end
  end

  describe ".sendable?" do
    context "when mail has no recipient" do
      it "returns false" do
        allow(mail).to receive(:to).and_return([])
        expect(Dolist::API.sendable?(mail)).to be false
      end
    end

    context "when mail has bcc" do
      it "returns false" do
        allow(mail).to receive(:bcc).and_return(["bcc@example.com"])
        expect(Dolist::API.sendable?(mail)).to be false
      end
    end

    context "when mail has attachments that are not inline" do
      it "returns false" do
        attachment = double("Attachment", inline?: false)
        allow(mail).to receive(:attachments).and_return([attachment])
        expect(Dolist::API.sendable?(mail)).to be false
      end
    end

    context "when mail is valid" do
      it "returns true" do
        expect(Dolist::API.sendable?(mail)).to be true
      end
    end
  end

  describe "#send_email" do
    let(:api) { Dolist::API.new }
    let(:url) { "https://api.dolist.com/email/send" }
    let(:mail_body) do
      {
        "Type": "TransactionalService",
        "Contact": {
          "FieldList": [
            {
              "ID" => Dolist::API::EMAIL_KEY,
              "Value" => mail.to.first
            }
          ]
        },
        "Message": {
          "Name": mail['X-Dolist-Message-Name'].value,
          "Subject": mail.subject,
          "SenderID": api.send(:sender_id, mail.from_address.domain),
          "ForceHttp": false,
          "Format": "html",
          "DisableOpenTracking": true,
          "IsTrackingValidated": true
        },
        "MessageContent": {
          "SourceCode": mail.decoded,
          "EncodingType": "UTF8",
          "EnableTrackingDetection": false
        }
      }
    end

    let(:expected_body) { { "TransactionalSending": mail_body }.to_json }

    it "sends an email using the API" do
      stub_request(:post, "https://apiv9.dolist.net/v1/email/sendings/transactional?AccountID=#{ENV["DOLIST_ACCOUNT_ID"]}")
        .with(body: expected_body)
        .to_return(body: { "Result" => "success" }.to_json, headers: { "X-Rate-Limit-Remaining" => "15", "X-Rate-Limit-Reset" => "1234" })

      result = api.send_email(mail)
      expect(result).to eq({ "Result" => "success" })
    end
  end

  describe "#sent_mails" do
    let(:api) { Dolist::API.new }
    let(:email_address) { "test@example.com" }
    let(:contact_id) { "12345" }
    let(:dolist_messages) { [{ "SendingName" => "Test Message", "SendDate" => Time.zone.now.to_s, "Status" => "Sent", "IsDelivered" => true }] }

    before do
      allow(api).to receive(:fetch_contact_id).with(email_address).and_return(contact_id)
      allow(api).to receive(:fetch_dolist_messages).with(contact_id).and_return(dolist_messages)
    end

    it "returns a list of sent mails" do
      sent_mails = api.sent_mails(email_address)
      expect(sent_mails).not_to be_empty
      expect(sent_mails.first.subject).to eq("Test Message")
    end

    context "when contact_id is nil" do
      it "returns an empty list" do
        allow(api).to receive(:fetch_contact_id).with(email_address).and_return(nil)
        expect(api.sent_mails(email_address)).to be_empty
      end
    end

    context "when an error occurs" do
      it "returns an empty list and logs the error" do
        allow(api).to receive(:fetch_contact_id).and_raise(StandardError.new("Test Error"))
        expect(Rails.logger).to receive(:error).with("Test Error")
        expect(api.sent_mails(email_address)).to be_empty
      end
    end
  end
end
