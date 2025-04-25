# frozen_string_literal: true

describe Referentiel do
  describe 'validation' do
    describe "referentiel" do
      it 'validates type as csv/url or nil' do
        expect(build(:referentiel, type: 'Referentiels::APIReferentiel').tap(&:validate).errors.map(&:attribute)).not_to include(:type)
        expect(build(:referentiel, type: 'Referentiels::CsvReferentiel').tap(&:validate).errors.map(&:attribute)).not_to include(:type)
      end

      describe 'APIReferentiel' do
        let(:whitelist) { %w[https://example.com https://allowed.com] }
        before do
          allow(ENV).to receive(:fetch).and_call_original
          allow(ENV).to receive(:fetch).with('ALLOWED_API_DOMAINS_FROM_FRONTEND', '').and_return(whitelist.join(','))
        end
        it 'validates presentater as exact_match/autocomplete or nil' do
          expect(build(:api_referentiel, mode: 'exact_match').tap(&:validate).errors.map(&:attribute)).not_to include(:mode)
          expect(build(:api_referentiel, mode: 'autocomplete').tap(&:validate).errors.map(&:attribute)).not_to include(:mode)
          expect(build(:api_referentiel, mode: nil).tap(&:validate).errors.map(&:attribute)).not_to include(:mode)
        end

        describe 'configured?' do
          context 'when adapter is url' do
            it 'tests url params' do
              referentiel = build(:api_referentiel, url: whitelist)
              expect(referentiel).to receive(:mode).and_return(double(present?: true))
              expect(referentiel).to receive(:url).and_return(double(present?: true))
              expect(referentiel).to receive(:test_data).and_return(double(present?: true))

              expect(referentiel.configured?).to eq(true)
            end
          end
        end

        describe 'url_in_whitelist?' do
          let(:referentiel) { build(:api_referentiel, url:) }
          let(:whitelist) { %w[https://example.com https://allowed.com] }

          context 'when the URL is in the whitelist' do
            let(:url) { whitelist.first }

            it 'does not add an error' do
              referentiel.validate
              expect(referentiel.errors[:url]).to be_empty
            end
          end

          context 'when the URL is not in the whitelist' do
            let(:url) { "https://api.untrusted.com/resource" }

            it 'adds an error' do
              referentiel.validate
              expect(referentiel.errors[:url]).to include("L'URL doit être autorisée par notre équipe, veuillez nous contacter")
            end
          end

          context 'when the URL is invalid' do
            let(:url) { "invalid_url" }

            it 'adds an invalid URL error' do
              referentiel.validate
              expect(referentiel.errors[:url]).to include("L'URL est invalide")
            end
          end

          context 'when the URL is blank' do
            let(:url) { nil }

            it 'does not add an error' do
              referentiel.validate
              expect(referentiel.errors[:url]).to be_empty
            end
          end

          context 'when the URL ends with .gouv.fr' do
            let(:url) { "https://ministere.gouv.fr/resource" }

            it 'does not add an error' do
              referentiel.validate
              expect(referentiel.errors[:url]).to be_empty
            end
          end

          context 'when the URL ends with .beta.gouv.fr' do
            let(:url) { "https://api.beta.gouv.fr/resource" }

            it 'adds an error' do
              referentiel.validate
              expect(referentiel.errors[:url]).to include("L'URL doit être autorisée par notre équipe, veuillez nous contacter")
            end
          end
        end
      end
    end
  end

  describe 'csv' do
    let(:referentiel) { create(:csv_referentiel, :with_items) }
    let(:item_ids) { referentiel.items.ids.map(&:to_s) }

    context 'with items' do
      it '#headers_with_path' do
        expect(referentiel.headers_with_path).to eq([["option", "option"], ["calorie (kcal)", "calorie_kcal"], ["poids (g)", "poids_g"]])
      end

      it '#options_for_select' do
        expect(referentiel.options_for_select).to eq([["fromage", item_ids.first], ["dessert", item_ids.second], ["fruit", item_ids.third]])
      end

      it '#drop_down_options' do
        expect(referentiel.drop_down_options).to eq(["fromage", "dessert", "fruit"])
      end

      it '#options_for_path' do
        expect(referentiel.options_for_path('calorie_kcal')).to eq([["100", "100"], ["145", "145"], ["170", "170"]])
      end
    end

    context 'with missing option' do
      before do
        item = referentiel.items.first
        data = item.data
        data['row']['option'] = nil
        item.update(data:)
      end

      it '#headers_with_path' do
        expect(referentiel.headers_with_path).to match_array([["option", "option"], ["calorie (kcal)", "calorie_kcal"], ["poids (g)", "poids_g"]])
      end

      it '#options_for_select' do
        expect(referentiel.options_for_select).to match_array([["dessert", item_ids.second], ["fruit", item_ids.third]])
      end

      it '#drop_down_options' do
        expect(referentiel.drop_down_options).to match_array(["dessert", "fruit"])
      end

      it '#options_for_path' do
        expect(referentiel.options_for_path('calorie_kcal')).to match_array([["100", "100"], ["170", "170"]])
      end
    end

    context 'with missing column' do
      before do
        item = referentiel.items.first
        data = item.data
        data['row']['calorie_kcal'] = nil
        item.update(data:)
      end

      it '#headers_with_path' do
        expect(referentiel.headers_with_path).to match_array([["option", "option"], ["calorie (kcal)", "calorie_kcal"], ["poids (g)", "poids_g"]])
      end

      it '#options_for_select' do
        expect(referentiel.options_for_select).to match_array([["fromage", item_ids.first], ["dessert", item_ids.second], ["fruit", item_ids.third]])
      end

      it '#drop_down_options' do
        expect(referentiel.drop_down_options).to match_array(["fromage", "dessert", "fruit"])
      end

      it '#options_for_path' do
        expect(referentiel.options_for_path('calorie_kcal')).to match_array([["100", "100"], ["170", "170"]])
      end
    end
  end
end
