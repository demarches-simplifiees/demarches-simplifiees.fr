describe Champs::COJOChamp, type: :model do
  let(:champ) { build(:champ_cojo, accreditation_number:, accreditation_birthdate:) }
  let(:external_id) { nil }
  let(:stub) { stub_request(:post, url).with(body: { accreditationNumber: accreditation_number.to_i, birthdate: accreditation_birthdate }).to_return(body:, status:) }
  let(:url) { COJOService.new.send(:url) }
  let(:body) { Rails.root.join('spec', 'fixtures', 'files', 'api_cojo', "accreditation_#{response_type}.json").read }
  let(:status) { 200 }
  let(:response_type) { 'yes' }
  let(:accreditation_number) { '123456' }
  let(:accreditation_birthdate) { '21/12/1959' }

  describe 'fetch_external_data' do
    subject { stub; champ.fetch_external_data }

    context 'success (yes)' do
      it { expect(subject.value!).to eq({ accreditation_success: true, accreditation_first_name: 'Florence', accreditation_last_name: 'Griffith-Joyner' }) }
    end

    context 'success (no)' do
      let(:response_type) { 'no' }
      it { expect(subject.value!).to eq({ accreditation_success: false, accreditation_first_name: nil, accreditation_last_name: nil }) }
    end

    context 'failure (schema)' do
      let(:response_type) { 'invalid' }
      it {
        expect(subject.failure.retryable).to be_falsey
        expect(subject.failure.reason).to be_a(API::Client::SchemaError)
      }
    end

    context 'failure (http 500)' do
      let(:status) { 500 }
      let(:response_type) { 'invalid' }
      it {
        expect(subject.failure.retryable).to be_truthy
        expect(subject.failure.reason).to be_a(API::Client::HTTPError)
      }
    end

    context 'failure (http 401)' do
      let(:status) { 401 }
      let(:response_type) { 'invalid' }
      it {
        expect(subject.failure.retryable).to be_falsey
        expect(subject.failure.reason).to be_a(API::Client::HTTPError)
      }
    end
  end

  describe 'fill champ' do
    let(:champ) { create(:champ_cojo, accreditation_number:, accreditation_birthdate:) }

    subject { stub; champ.touch; perform_enqueued_jobs; champ.reload }

    it 'success (yes)' do
      expect(subject.blank?).to be_falsey
    end

    context 'success (no)' do
      let(:response_type) { 'no' }

      it { expect(subject.blank?).to be_truthy }
    end

    context 'failure (schema)' do
      let(:response_type) { 'invalid' }

      it { expect(subject.blank?).to be_truthy }
    end

    context 'failure (http 401)' do
      let(:status) { 401 }
      let(:response_type) { 'invalid' }

      it { expect(subject.blank?).to be_truthy }
    end
  end
end
