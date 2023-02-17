describe UpdateZoneToProceduresService do
  before(:each) do
    Flipper.enable :zonage
    Rake::Task['after_party:populate_zones'].invoke
  end

  after(:each) do
    Rake::Task['after_party:populate_zones'].reenable
  end

  describe '#call' do
    let(:procedure1) { create(:procedure, zone: nil) }
    let(:procedure2) { create(:procedure, zone: nil) }

    subject { described_class.call(lines) }

    context 'nominal case' do
      let(:lines) do
        [
          { "id" => procedure1.id, "POL_PUB_MINISTERE RATTACHEMENT" => "PM" },
          { "id" => procedure2.id, "POL_PUB_MINISTERE RATTACHEMENT" => "MI" }
        ]
      end

      it 'updates zone to procedures' do
        errors = subject

        expect(errors).to eq []
        expect(procedure1.reload.zone.acronym).to eq("PM")
        expect(procedure2.reload.zone.acronym).to eq("MI")
      end
    end

    context 'with unknown procedure' do
      let(:lines) do
        [
          { "id" => procedure1.id + procedure2.id, "POL_PUB_MINISTERE RATTACHEMENT" => "PM" }
        ]
      end
      it 'returns errors' do
        errors = subject
        expect(errors).to eq ["Procedure #{procedure1.id + procedure2.id} introuvable"]
      end
    end

    context 'with unknown zone' do
      let(:lines) do
        [
          { "id" => procedure1.id, "POL_PUB_MINISTERE RATTACHEMENT" => "YOUPI" }
        ]
      end
      it 'returns errors' do
        errors = subject
        expect(errors).to eq ["Zone YOUPI introuvable"]
      end
    end
  end
end
