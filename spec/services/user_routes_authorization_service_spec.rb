require 'spec_helper'

describe UserRoutesAuthorizationService do

  describe '#authorize_route?' do
    let(:api_carto) { false }

    subject { described_class.authorized_route? path, state, api_carto }

    context 'when path is not recognized' do
      let(:state) { 'blabla' }
      let(:path) { 'blabla' }

      it { expect { subject }.to raise_error 'Not a valid path' }
    end

    context 'when state is not recognized' do
      let(:state) { 'blabla' }
      let(:path) { '' }

      it { expect { subject }.to raise_error 'Not a valid state' }
    end

    context 'when path and state are recognized' do
      describe 'root' do
        let(:path) { '' }

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
        let(:path) { '/carte' }
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
          let(:api_carto) { true }

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

      describe 'description' do
        let(:path) { '/description' }

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
        let(:path) { '/recapitulatif' }

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
end