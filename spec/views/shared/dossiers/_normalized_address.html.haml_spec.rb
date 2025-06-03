# frozen_string_literal: true

describe 'shared/dossiers/normalized_address', type: :view do
  before { render 'shared/dossiers/normalized_address', address: }

  context 'given an champ' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :siret }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
    let(:address) { AddressProxy.new(dossier.champs.first) }

    it 'render address' do
      AddressProxy::ADDRESS_PARTS.each do |address_part|
        expect(rendered).to have_text(address_part)
      end
    end
  end

  context 'given an etablissement' do
    let(:etablissement) { create(:etablissement) }
    let(:address) { AddressProxy.new(etablissement) }

    it 'render address' do
      expect(rendered).to have_text("6 RUE RAOUL NORDLING")
      expect(rendered).to have_text("BOIS COLOMBES 92270")
      expect(rendered).to have_text("92009")
      expect(rendered).to have_text("92270")
      expect(rendered).to have_text("Hauts-de-Seine – 92")
      expect(rendered).to have_text("Île-de-France – 11")
    end
  end
end
