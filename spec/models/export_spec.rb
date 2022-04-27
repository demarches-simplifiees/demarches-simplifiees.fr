RSpec.describe Export, type: :model do
  describe 'validations' do
    let(:groupe_instructeur) { create(:groupe_instructeur) }

    context 'when everything is ok' do
      let(:export) { build(:export, groupe_instructeurs: [groupe_instructeur]) }

      it { expect(export.save).to be true }
    end

    context 'when groupe instructeurs are missing' do
      let(:export) { build(:export, groupe_instructeurs: []) }

      it { expect(export.save).to be false }
    end

    context 'when format is missing' do
      let(:export) { build(:export, format: nil, groupe_instructeurs: [groupe_instructeur]) }

      it { expect(export.save).to be false }
    end
  end

  describe '.stale' do
    let!(:export) { create(:export) }
    let(:stale_date) { Time.zone.now() - (Export::MAX_DUREE_CONSERVATION_EXPORT + 1.minute) }
    let!(:stale_export) { create(:export, updated_at: stale_date) }

    it { expect(Export.stale).to match_array([stale_export]) }
  end

  describe '.destroy' do
    let!(:groupe_instructeur) { create(:groupe_instructeur) }
    let!(:export) { create(:export, groupe_instructeurs: [groupe_instructeur]) }

    before { export.destroy! }

    it { expect(Export.count).to eq(0) }
    it { expect(groupe_instructeur.reload).to be_present }
  end

  describe '.find_by groupe_instructeurs' do
    let!(:procedure) { create(:procedure) }
    let!(:gi_1) { create(:groupe_instructeur, procedure: procedure) }
    let!(:gi_2) { create(:groupe_instructeur, procedure: procedure) }
    let!(:gi_3) { create(:groupe_instructeur, procedure: procedure) }

    context 'when an export is made for one groupe instructeur' do
      let!(:export) { create(:export, groupe_instructeurs: [gi_1, gi_2]) }

      it { expect(Export.find_for_groupe_instructeurs([gi_1.id], nil)).to eq({ csv: { statut: {}, time_span_type: {} }, xlsx: { statut: {}, time_span_type: {} }, ods: { statut: {}, time_span_type: {} }, zip: { statut: {}, time_span_type: {} } }) }
      it { expect(Export.find_for_groupe_instructeurs([gi_2.id, gi_1.id], nil)).to eq({ csv: { statut: {}, time_span_type: { 'everything' => export } }, xlsx: { statut: {}, time_span_type: {} }, ods: { statut: {}, time_span_type: {} }, zip: { statut: {}, time_span_type: {} } }) }
      it { expect(Export.find_for_groupe_instructeurs([gi_1.id, gi_2.id, gi_3.id], nil)).to eq({ csv: { statut: {}, time_span_type: {} }, xlsx: { statut: {}, time_span_type: {} }, ods: { statut: {}, time_span_type: {} }, zip: { statut: {}, time_span_type: {} } }) }
    end
  end
end
