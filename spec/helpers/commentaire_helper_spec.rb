# frozen_string_literal: true

RSpec.describe CommentaireHelper, type: :helper do
  let(:commentaire) { create(:commentaire, email: "michel@pref.fr") }

  describe ".commentaire_is_from_me_class" do
    subject { commentaire_is_from_me_class(commentaire, me) }

    context "when commentaire is from me" do
      let(:me) { User.new(email: "michel@pref.fr") }
      it { is_expected.to eq("from-me") }
    end

    context "when commentaire is not from me" do
      let(:me) { User.new(email: "roger@usager.fr") }
      it { is_expected.to eq nil }
    end
  end

  describe '.commentaire_answer_action' do
    subject { commentaire_answer_action(commentaire, me) }

    context "when commentaire is from me" do
      let(:me) { User.new(email: "michel@pref.fr") }
      it { is_expected.to include('Envoyer') }
    end

    context "when commentaire is not from me" do
      let(:me) { User.new(email: "roger@usager.fr") }
      it { is_expected.to include('Répondre') }
    end
  end
end
