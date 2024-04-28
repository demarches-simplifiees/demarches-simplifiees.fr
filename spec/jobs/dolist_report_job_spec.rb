# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DolistReportJob, type: :job do
  let(:event1) { create(:email_event, :dolist, :dispatched, to: "you@blabla.com", processed_at: 1.minute.ago) }
  let(:event2) { create(:email_event, :dolist, :dispatched) }

  before do
    emails = [
      SentMail.new(
        to: event1.to,
        status: "delivered",
        delivered_at: event1.processed_at + 1.minute
      )
    ]

    allow_any_instance_of(Dolist::API).to receive(:sent_mails).with(event1.to).and_return(emails)
    allow_any_instance_of(Dolist::API).to receive(:sent_mails).with(event2.to).and_return([])
  end

  subject(:perform_job) { described_class.perform_now("you@rocks.com") }

  it "generates a csv file and send it by email" do
    perform_job

    email = ActionMailer::Base.deliveries.last
    expect(email.to).to eq(["you@rocks.com"])
    expect(email.attachments[0].filename).to eq("dolist_report.csv")

    csv = CSV.parse(email.attachments[0].body.decoded, headers: true)
    expect(csv.size).to eq(2)

    # events were processed randomly, go back to a deterministic order
    rows = csv.sort_by { _1["dispatched_at"] }

    expect(rows[0]["domain"]).to eq("blabla.com")
    expect(rows[0]["status"]).to eq("delivered")
    expect(rows[0]["delay (min)"]).to eq("1")
    expect(rows[1]["status"]).to be_nil
  end
end
