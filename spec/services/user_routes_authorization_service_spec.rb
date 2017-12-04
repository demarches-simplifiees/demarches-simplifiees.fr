require 'spec_helper'

describe UserRoutesAuthorizationService do
  describe '#authorize_route?' do
    let(:module_api_carto) { create :module_api_carto, use_api_carto: use_api_carto }
    let(:procedure) { create :procedure, module_api_carto: module_api_carto }
    let(:dossier) { create :dossier, procedure: procedure, state: state }

    let(:use_api_carto) { false }

    subject { described_class.authorized_route? controller, dossier }

    describe 'Users::DossiersController' do
      let(:controller) { Users::DossiersController }

      describe 'brouillon' do
        let(:state) { 'brouillon' }
        it { is_expected.to be_truthy }
      end

      describe 'en_construction' do
        let(:state) { 'en_construction' }
        it { is_expected.to be_falsey }
      end

      describe 'accepte' do
        let(:state) { 'accepte' }
        it { is_expected.to be_falsey }
      end
    end

    describe 'carte' do
      let(:controller) { Users::CarteController }

      context 'when use_api_carto is false' do
        describe 'brouillon' do
          let(:state) { 'brouillon' }
          it { is_expected.to be_falsey }
        end

        describe 'en_construction' do
          let(:state) { 'en_construction' }
          it { is_expected.to be_falsey }
        end

        describe 'accepte' do
          let(:state) { 'accepte' }
          it { is_expected.to be_falsey }
        end
      end

      context 'when use_api_carto is true' do
        let(:use_api_carto) { true }

        describe 'brouillon' do
          let(:state) { 'brouillon' }
          it { is_expected.to be_truthy }
        end

        describe 'en_construction' do
          let(:state) { 'en_construction' }
          it { is_expected.to be_truthy }
        end

        describe 'accepte' do
          let(:state) { 'accepte' }
          it { is_expected.to be_falsey }
        end
      end
    end

    describe 'Users::DescriptionController' do
      let(:controller) { Users::DescriptionController }

      describe 'brouillon' do
        let(:state) { 'brouillon' }
        it { is_expected.to be_truthy }
      end

      describe 'en_construction' do
        let(:state) { 'en_construction' }
        it { is_expected.to be_truthy }
      end

      describe 'accepte' do
        let(:state) { 'accepte' }
        it { is_expected.to be_falsey }
      end
    end

    describe 'recapitulatif' do
      let(:controller) { Users::RecapitulatifController }

      describe 'brouillon' do
        let(:state) { 'brouillon' }
        it { is_expected.to be_falsey }
      end

      describe 'en_construction' do
        let(:state) { 'en_construction' }
        it { is_expected.to be_truthy }
      end

      describe 'accepte' do
        let(:state) { 'accepte' }
        it { is_expected.to be_truthy }
      end
    end
  end
end
