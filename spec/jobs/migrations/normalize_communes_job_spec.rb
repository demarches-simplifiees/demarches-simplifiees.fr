describe Migrations::NormalizeCommunesJob, type: :job do
  context 'when value is "", external_id is "", and code_departement is "undefined"' do
    let(:champ) { create(:champ_communes) }
    before { champ.update_columns(external_id: "", value: "", value_json: { code_departement: 'undefined', departement: 'undefined' }) }
    subject { described_class.perform_now([champ.id]) }
    it 'empty the champs' do
      subject
      champ.reload
      expect(champ.code_postal).to be_nil
      expect(champ.code_departement).to be_nil
    end
  end
end
