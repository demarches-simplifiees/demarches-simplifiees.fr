require 'rails_helper'

RSpec.describe TypeDeChampHelper, type: :helper do
  describe ".tdc_options" do
    let(:current_administrateur) { create(:administrateur) }
    let(:pj_option) { ["Pièce justificative", "piece_justificative"] }

    subject { tdc_options(current_administrateur) }

    context "when the champ_pj_allowed_for_admin_id matches the current_administrateur's id" do
      before { allow(Features).to receive(:champ_pj_allowed_for_admin_ids).and_return([current_administrateur.id]) }

      it { is_expected.to include(pj_option) }
    end

    context "when the champ_pj_allowed_for_admin_id does not match the current_administrateur's id" do
      before { allow(Features).to receive(:champ_pj_allowed_for_admin_ids).and_return([1000]) }

      it { is_expected.not_to include(pj_option) }
    end
  end
end
