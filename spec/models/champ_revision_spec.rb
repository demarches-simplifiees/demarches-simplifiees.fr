describe ChampRevision do
  describe "associations" do
    it {
      is_expected.to belong_to(:champ)
      is_expected.to belong_to(:instructeur)
      is_expected.to belong_to(:etablissement).optional
    }
  end

  describe "create_or_update_revision" do
    let!(:champ) { create(:champ_text, value: 'my_string') }
    let!(:another_champ) { create(:champ_text, value: 'my_string') }
    let!(:instructeur) { create(:instructeur) }
    let!(:champ_revision) { ChampRevision.create_or_update_revision(another_champ, instructeur.id) }

    context "when no champ_revision yet for current_champ" do
      it "create a new champ_revision" do
        ChampRevision.create_or_update_revision(champ, instructeur.id)
        expect(ChampRevision.where(champ_id: champ.id).count).to eq(1)
      end
    end

    context "when already champ_revision recent" do
      before {
        ChampRevision.create_or_update_revision(champ, instructeur.id)
        champ.update(value: 'my_string2')
      }

      it "does not create a new champ_revision" do
        ChampRevision.create_or_update_revision(champ, instructeur.id)
        expect(ChampRevision.where(champ_id: champ).count).to eq(1)
      end
    end

    context "when already champ_revision old" do
      before {
        ChampRevision.create_or_update_revision(champ, instructeur.id)
        ChampRevision.last.update(updated_at: 8.minutes.ago)
        champ.update(value: 'my_string2')
      }

      it "does not create a new champ_revision" do
        ChampRevision.create_or_update_revision(champ, instructeur.id)
        expect(ChampRevision.where(champ_id: champ).count).to eq(2)
      end
    end
  end
end
