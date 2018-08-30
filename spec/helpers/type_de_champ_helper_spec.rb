require 'rails_helper'

RSpec.describe TypeDeChampHelper, type: :helper do
  describe ".tdc_options" do
    let(:pj_option) { ["Pièce justificative", TypeDeChamp.type_champs.fetch(:piece_justificative)] }

    subject { tdc_options }

    context "when the champ_pj is enabled" do
      before do
        Flipflop::FeatureSet.current.test!.switch!(:champ_pj, true)
      end

      it { is_expected.to include(pj_option) }
    end

    context "when the champ_pj is disabled" do
      before do
        Flipflop::FeatureSet.current.test!.switch!(:champ_pj, false)
      end

      it { is_expected.not_to include(pj_option) }
    end
  end
end
