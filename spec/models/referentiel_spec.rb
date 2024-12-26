# frozen_string_literal: true

describe Referentiel do
  describe 'validation' do
    describe "referentiel" do
      it 'validates type as csv/url or nil' do
        expect(build(:referentiel, type: 'Referentiels::APIReferentiel').tap(&:validate).errors.map(&:attribute)).not_to include(:type)
        expect(build(:referentiel, type: 'Referentiels::CsvReferentiel').tap(&:validate).errors.map(&:attribute)).not_to include(:type)
      end

      describe 'APIReferentiel' do
        it 'validates presentater as exact_match/autocomplete or nil' do
          expect(build(:api_referentiel, mode: 'exact_match').tap(&:validate).errors.map(&:attribute)).not_to include(:mode)
          expect(build(:api_referentiel, mode: 'autocomplete').tap(&:validate).errors.map(&:attribute)).not_to include(:mode)
          expect(build(:api_referentiel, mode: nil).tap(&:validate).errors.map(&:attribute)).not_to include(:mode)
          expect(build(:api_referentiel, mode: 'wrong').tap(&:validate).errors.map(&:attribute)).to include(:mode)
        end

        describe 'configured?' do
          context 'when adapter is url' do
            it 'tests url params' do
              referentiel = build(:api_referentiel)
              expect(referentiel).to receive(:mode).and_return(double(present?: true))
              expect(referentiel).to receive(:url).and_return(double(present?: true))
              expect(referentiel).to receive(:test_data).and_return(double(present?: true))

              expect(referentiel.configured?).to eq(true)
            end
          end
        end
      end
    end
  end
end
