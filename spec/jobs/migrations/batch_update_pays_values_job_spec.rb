describe Migrations::BatchUpdatePaysValuesJob, type: :job do
  subject { described_class.perform_now([pays_champ.id]) }

  context "the value is correct" do
    let(:pays_champ) { create(:champ_pays).tap { _1.update_columns(value: 'France', external_id: 'FR') } }

    it 'does not change it' do
      subject
      expect(pays_champ.reload.value).to eq('France')
      expect(pays_champ.reload.external_id).to eq('FR')
    end
  end

  context "the value is incorrect" do
    before do
      pays_champ.type_de_champ.update!(mandatory: false)
    end

    let(:pays_champ) { create(:champ_pays).tap { _1.update_columns(value: 'Incorrect') } }

    it 'updates value to nil' do
      subject
      expect(pays_champ.reload.value).to be_nil
      expect(pays_champ.reload.external_id).to be_nil
    end
  end

  context "the value is easily cleanable" do
    let(:pays_champ) { create(:champ_pays).tap { _1.update_columns(value: 'Vietnam') } }

    it 'cleans the value' do
      subject
      expect(pays_champ.reload.value).to eq('Viêt Nam')
      expect(pays_champ.reload.external_id).to eq('VN')
    end
  end

  context "the value is hard to clean" do
    let(:pays_champ) { create(:champ_pays).tap { _1.update_columns(value: 'CHRISTMAS (ILE)') } }

    it 'cleans the value' do
      subject
      expect(pays_champ.reload.value).to eq('Christmas, Île')
      expect(pays_champ.reload.external_id).to eq('CX')
    end
  end
end
