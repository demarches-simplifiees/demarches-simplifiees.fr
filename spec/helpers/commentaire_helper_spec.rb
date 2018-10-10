require 'rails_helper'

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

  describe '.commentaire_is_from_guest' do
    let(:dossier) { create(:dossier) }
    let!(:guest) { create(:invite, dossier: dossier) }

    subject { commentaire_is_from_guest(commentaire) }

    context 'when the commentaire sender is not a guest' do
      let(:commentaire) { create(:commentaire, dossier: dossier, email: "michel@pref.fr") }
      it { is_expected.to be false }
    end

    context 'when the commentaire sender is a guest on this dossier' do
      let(:commentaire) { create(:commentaire, dossier: dossier, email: guest.email) }
      it { is_expected.to be true }
    end
  end

  describe '.commentaire_date' do
    let(:present_date) { Time.local(2018, 9, 2, 10, 5, 0) }
    let(:creation_date) { present_date }
    let(:commentaire) do
      Timecop.freeze(creation_date) { create(:commentaire, email: "michel@pref.fr") }
    end

    subject do
      Timecop.freeze(present_date) { commentaire_date(commentaire) }
    end

    it 'doesn’t include the creation year' do
      expect(subject).to eq 'le 2 septembre à 10 h 05'
    end

    context 'when displaying a commentaire created on a previous year' do
      let(:creation_date) { present_date.prev_year }
      it 'includes the creation year' do
        expect(subject).to eq 'le 2 septembre 2017 à 10 h 05'
      end
    end

    context 'when formatting the first day of the month' do
      let(:present_date) { Time.local(2018, 9, 1, 10, 5, 0) }
      it 'includes the ordinal' do
        expect(subject).to eq 'le 1er septembre à 10 h 05'
      end
    end
  end
end
