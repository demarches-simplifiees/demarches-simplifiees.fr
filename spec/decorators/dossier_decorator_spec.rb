require 'spec_helper'

describe DossierDecorator do
  let(:dossier) do
    dossier = create(:dossier, created_at: Time.new(2015, 12, 24, 14, 10))
    dossier.update_column('updated_at', Time.new(2015, 12, 24, 14, 10))
    dossier
  end

  subject { dossier.decorate }

  describe 'first_creation' do
    subject { super().first_creation }
    it { is_expected.to eq('24/12/2015 14:10') }
  end

  describe 'last_update' do
    subject { super().last_update }
    it { is_expected.to eq('24/12/2015 14:10') }
  end

  describe 'state_fr' do
    subject{ super().display_state }

    it 'brouillon is brouillon' do
      dossier.brouillon!
      expect(subject).to eq('Brouillon')
    end

    it 'en_construction is En construction' do
      dossier.en_construction!
      expect(subject).to eq('En construction')
    end

    it 'closed is traité' do
      dossier.closed!
      expect(subject).to eq('Accepté')
    end

    it 'en_instruction is reçu' do
      dossier.en_instruction!
      expect(subject).to eq('En instruction')
    end

    it 'without_continuation is traité' do
      dossier.without_continuation!
      expect(subject).to eq('Sans suite')
    end

    it 'refused is traité' do
      dossier.refused!
      expect(subject).to eq('Refusé')
    end
  end

  describe '#url' do
    context "when a gestionnaire is signed_in" do
      subject { super().url(true) }

      it { is_expected.to eq("/backoffice/dossiers/#{dossier.id}") }
    end

    context "when a gestionnaire is not signed_in" do
      context "when the dossier is in brouillon state" do
        before do
          dossier.state = 'brouillon'
          dossier.save
        end

        subject { super().url(false) }

        it { is_expected.to eq("/users/dossiers/#{dossier.id}/description") }
      end

      context "when the dossier is not in brouillon state" do
        before do
          dossier.state = 'en_construction'
          dossier.save
        end

        subject { super().url(false) }

        it { is_expected.to eq("/users/dossiers/#{dossier.id}/recapitulatif") }
      end
    end
  end
end
