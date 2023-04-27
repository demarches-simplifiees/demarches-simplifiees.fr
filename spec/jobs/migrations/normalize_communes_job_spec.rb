describe Migrations::NormalizeCommunesJob, type: :job do
  let(:champ) { create(:champ_communes, external_id: code_insee, code_departement:) }
  let(:code_insee) { '97209' }
  let(:value) { 'Fort-de-France (97200)' }
  let(:code_departement) { nil }

  before { champ.update_column(:value, value) }

  subject { described_class.perform_now([champ.id]) }

  context 'Fort-de-France' do
    it 'assign code_departement and code_postal' do
      expect(champ.reload.code_postal).to be_nil
      expect(champ.reload.code_departement).to be_nil
      subject
      expect(champ.reload.code_postal).to eq('97200')
      expect(champ.reload.code_departement).to eq('972')
    end
  end

  context 'Ajaccio' do
    let(:code_insee) { '2A004' }
    let(:value) { 'Ajaccio (20000)' }

    it 'assign code_departement and code_postal' do
      expect(champ.reload.code_postal).to be_nil
      expect(champ.reload.code_departement).to be_nil
      subject
      expect(champ.reload.code_postal).to eq('20000')
      expect(champ.reload.code_departement).to eq('2A')
    end
  end

  context 'undefined' do
    let(:code_insee) { '2A004' }
    let(:value) { 'Ajaccio (20000)' }
    let(:code_departement) { 'undefined' }

    it 'assign code_departement and code_postal' do
      expect(champ.reload.code_postal).to be_nil
      expect(champ.reload.code_departement).to eq('undefined')
      subject
      expect(champ.reload.code_postal).to eq('20000')
      expect(champ.reload.code_departement).to eq('2A')
    end
  end
end
