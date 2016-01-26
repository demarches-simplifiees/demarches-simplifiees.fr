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

      describe 'draft' do
        let(:state) { 'draft' }
        it { is_expected.to be_truthy }
      end

      describe 'initiated' do
        let(:state) { 'initiated' }
        it { is_expected.to be_falsey }
      end

      describe 'replied' do
        let(:state) { 'replied' }
        it { is_expected.to be_falsey }
      end

      describe 'updated' do
        let(:state) { 'updated' }
        it { is_expected.to be_falsey }
      end

      describe 'validated' do
        let(:state) { 'validated' }
        it { is_expected.to be_falsey }
      end

      describe 'submitted' do
        let(:state) { 'submitted' }
        it { is_expected.to be_falsey }
      end

      describe 'closed' do
        let(:state) { 'closed' }
        it { is_expected.to be_falsey }
      end
    end

    describe 'carte' do
      let(:controller) { Users::CarteController }

      context 'when use_api_carto is false' do

        describe 'draft' do
          let(:state) { 'draft' }
          it { is_expected.to be_falsey }
        end

        describe 'initiated' do
          let(:state) { 'initiated' }
          it { is_expected.to be_falsey }
        end

        describe 'replied' do
          let(:state) { 'replied' }
          it { is_expected.to be_falsey }
        end

        describe 'updated' do
          let(:state) { 'updated' }
          it { is_expected.to be_falsey }
        end

        describe 'validated' do
          let(:state) { 'validated' }
          it { is_expected.to be_falsey }
        end

        describe 'submitted' do
          let(:state) { 'submitted' }
          it { is_expected.to be_falsey }
        end

        describe 'closed' do
          let(:state) { 'closed' }
          it { is_expected.to be_falsey }
        end
      end

      context 'when use_api_carto is true' do
        let(:use_api_carto) { true }

        describe 'draft' do
          let(:state) { 'draft' }
          it { is_expected.to be_truthy }
        end

        describe 'initiated' do
          let(:state) { 'initiated' }
          it { is_expected.to be_truthy }
        end

        describe 'replied' do
          let(:state) { 'replied' }
          it { is_expected.to be_truthy }
        end

        describe 'updated' do
          let(:state) { 'updated' }
          it { is_expected.to be_truthy }
        end

        describe 'validated' do
          let(:state) { 'validated' }
          it { is_expected.to be_falsey }
        end

        describe 'submitted' do
          let(:state) { 'submitted' }
          it { is_expected.to be_falsey }
        end

        describe 'closed' do
          let(:state) { 'closed' }
          it { is_expected.to be_falsey }
        end
      end
    end

    describe 'Users::DescriptionController' do
      let(:controller) { Users::DescriptionController }

      describe 'draft' do
        let(:state) { 'draft' }
        it { is_expected.to be_truthy }
      end

      describe 'initiated' do
        let(:state) { 'initiated' }
        it { is_expected.to be_truthy }
      end

      describe 'replied' do
        let(:state) { 'replied' }
        it { is_expected.to be_truthy }
      end

      describe 'updated' do
        let(:state) { 'updated' }
        it { is_expected.to be_truthy }
      end

      describe 'validated' do
        let(:state) { 'validated' }
        it { is_expected.to be_falsey }
      end

      describe 'submitted' do
        let(:state) { 'submitted' }
        it { is_expected.to be_falsey }
      end

      describe 'closed' do
        let(:state) { 'closed' }
        it { is_expected.to be_falsey }
      end
    end

    describe 'recapitulatif' do
      let(:controller) { Users::RecapitulatifController }

      describe 'draft' do
        let(:state) { 'draft' }
        it { is_expected.to be_falsey }
      end

      describe 'initiated' do
        let(:state) { 'initiated' }
        it { is_expected.to be_truthy }
      end

      describe 'replied' do
        let(:state) { 'replied' }
        it { is_expected.to be_truthy }
      end

      describe 'updated' do
        let(:state) { 'updated' }
        it { is_expected.to be_truthy }
      end

      describe 'validated' do
        let(:state) { 'validated' }
        it { is_expected.to be_truthy }
      end

      describe 'submitted' do
        let(:state) { 'submitted' }
        it { is_expected.to be_truthy }
      end

      describe 'closed' do
        let(:state) { 'closed' }
        it { is_expected.to be_truthy }
      end
    end
  end
end