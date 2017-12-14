require 'rails_helper'

RSpec.describe CommentaireHelper, type: :helper do
  describe ".commentaire_is_from_me_class" do
    let(:commentaire) { create(:commentaire, email: "michel@pref.fr") }

    subject { commentaire_is_from_me_class(commentaire, me) }

    context "when commentaire is from me" do
      let(:me) { "michel@pref.fr" }

      it { is_expected.to eq("from-me") }
    end

    context "when commentaire is not from me" do
      let(:me) { "roger@usager.fr" }

      it { is_expected.to eq nil }
    end
  end
end
