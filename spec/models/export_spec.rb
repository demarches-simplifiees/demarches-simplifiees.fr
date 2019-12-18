require 'rails_helper'

RSpec.describe Export, type: :model do
  describe 'validations' do
    let(:groupe_instructeur) { create(:groupe_instructeur) }

    context 'when everything is ok' do
      let(:export) { build(:export) }

      it { expect(export.save).to be true }
    end

    context 'when groupe instructeurs are missing' do
      let(:export) { build(:export, groupe_instructeurs: []) }

      it { expect(export.save).to be false }
    end

    context 'when format is missing' do
      let(:export) { build(:export, format: nil) }

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
      let!(:export) { Export.create(format: :csv, groupe_instructeurs: [gi_1, gi_2]) }

      it { expect(Export.find_for_format_and_groupe_instructeurs(:csv, [gi_1])).to eq(nil) }
      it { expect(Export.find_for_format_and_groupe_instructeurs(:csv, [gi_2, gi_1])).to eq(export) }
      it { expect(Export.find_for_format_and_groupe_instructeurs(:csv, [gi_1, gi_2, gi_3])).to eq(nil) }
    end
  end
end
