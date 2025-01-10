# frozen_string_literal: true

describe Champs::FormattedChamp do
  describe 'validation' do
    let(:champ) do
      described_class.new(dossier: build(:dossier), value:)
    end

    before do
      allow(champ).to receive(:type_de_champ).and_return(type_de_champ)
      allow(champ).to receive(:in_dossier_revision?).and_return(true)
    end

    subject { champ.validate(:champs_public_value) }

    context 'with simple mode' do
      context 'only numbers accepted' do
        let(:type_de_champ) { build(:type_de_champ_formatted, :numbers_accepted) }

        context 'with value' do
          let(:value) { "2534" }

          it { is_expected.to be_truthy }
        end
        context 'with invalid value' do
          let(:type_de_champ) { build(:type_de_champ_formatted, :numbers_accepted) }
          let(:value) { "cou3872cou" }

          it { is_expected.to be_falsey }
        end
      end
    end
    context 'with advanced mode' do
      context 'with invalid value' do
        let(:value) { "blop" }
        context 'with expression reguliere error message defined' do
          let(:type_de_champ) do
            build(:type_de_champ_formatted, :advanced).tap do |tdc|
              tdc.options[:expression_reguliere_error_message] = "certainement pas"
              tdc.options[:expression_reguliere] = "/coucou/"
            end
          end

          it { is_expected.to be_falsey }
          it 'has specific error message defined' do
            subject
            expect(champ.errors.full_messages_for(:value).first).to eq "certainement pas"
          end
        end
        context 'without expression reguliere error message defined' do
          let(:type_de_champ) do
            build(:type_de_champ_formatted, :advanced).tap do |tdc|
              tdc.options[:expression_reguliere] = "/coucou/"
            end
          end
          it 'has default error message' do
            subject
            expect(champ.errors.full_messages_for(:value).first).to eq "n'est pas valide"
          end
        end
      end
    end
  end
end
