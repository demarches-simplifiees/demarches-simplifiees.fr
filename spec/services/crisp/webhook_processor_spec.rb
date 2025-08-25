# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crisp::WebhookProcessor do
  let!(:user) { users(:default_user) }
  let(:event) { "message:send" }
  let(:email) { user.email }
  let(:params) do
    {
      event:,
      data: {
        user: {
          user_id: email
        }
      }
    }
  end
  let(:processor) { described_class.new(params) }
  let(:crisp_service) { instance_double(Crisp::APIService) }

  before do
    allow(Crisp::APIService).to receive(:new).and_return(crisp_service)
  end

  subject { processor.process }

  describe '#process' do
    context 'with event message:send' do
      before do
        allow(crisp_service).to receive(:update_people_data)
      end

      it 'update people data' do
        subject

        expect(crisp_service).to have_received(:update_people_data).with(
          email:,
          body: { data: hash_including("Liens") }
        )
      end
    end

    context 'with another event' do
      let(:event) { "other:event" }

      it 'does not handle webhook' do
        expect(crisp_service).not_to receive(:update_people_data)
        subject
      end
    end

    context 'with unknown user' do
      let(:email) { 'nonexistent@example.com' }

      it 'ignore webhook' do
        expect(crisp_service).not_to receive(:update_people_data)
        subject
      end
    end
  end
end
