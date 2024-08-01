# frozen_string_literal: true

describe FalsifyOpendataService do
  before(:each) do
  end

  after(:each) do
  end

  describe '#call' do
    let(:procedure1) { create(:procedure, opendata: true) }
    let(:procedure2) { create(:procedure, opendata: true) }

    subject { described_class.call(lines) }

    context 'nominal case' do
      let(:lines) do
        [
          { "id" => procedure1.id },
          { "id" => procedure2.id }
        ]
      end

      it 'falsifies opendatas' do
        errors = subject

        expect(errors).to eq []
        expect(procedure1.reload.opendata).to be_falsey
        expect(procedure2.reload.opendata).to be_falsey
      end
    end

    context 'with unknown procedure' do
      let(:lines) do
        [
          { "id" => procedure1.id + procedure2.id }
        ]
      end
      it 'returns errors' do
        errors = subject
        expect(errors).to eq ["Procedure #{procedure1.id + procedure2.id} introuvable"]
      end
    end
  end
end
