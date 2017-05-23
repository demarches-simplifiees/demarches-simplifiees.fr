require 'rails_helper'

RSpec.describe Avis, type: :model do

  describe '.by_latest' do
    context 'with 3 avis' do
      let!(:avis){ create(:avis) }
      let!(:avis2){ create(:avis, updated_at: 4.hours.ago) }
      let!(:avis3){ create(:avis, updated_at: 3.hours.ago) }

      subject { Avis.by_latest }

      it { expect(subject).to eq([avis, avis3, avis2])}
    end
  end

end
