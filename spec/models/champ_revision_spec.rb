describe ChampRevision do
  describe "associations" do
    it {
      is_expected.to belong_to(:champ)
      is_expected.to belong_to(:instructeur)
      is_expected.to belong_to(:etablissement).optional
    }
  end

  describe "create_or_update_revision" do
    let(:dossier) { create(:dossier) }
    let(:champ) { Champs::TextChamp.new(value: 'my_string', dossier: dossier).tap(&:save!) }
    before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_numero_dn)) }

    let!(:instructeur) { create(:instructeur) }

    context "when champ is not a Textarea" do
      context "when no champ_revision yet for current_champ" do
        it "create a new champ_revision" do
          ChampRevision.create_or_update_revision(champ, instructeur.id)
          expect(ChampRevision.where(champ_id: champ.id).count).to eq(1)
        end
      end

      context "When there's already a revision" do
        before {
          ChampRevision.create_or_update_revision(champ, instructeur.id)
          ChampRevision.last.update(updated_at: delay)
          champ.update(value: 'my_string2')
        }
        context "when existing champ_revision is recent" do
          let(:delay) { 4.seconds.ago }
          it "does not create a new champ_revision" do
            ChampRevision.create_or_update_revision(champ, instructeur.id)
            expect(ChampRevision.where(champ_id: champ).count).to eq(1)
          end
        end

        context "when existing champ_revision is old" do
          let(:delay) { 10.seconds.ago }
          it "does create a new champ_revision" do
            ChampRevision.create_or_update_revision(champ, instructeur.id)
            expect(ChampRevision.where(champ_id: champ).count).to eq(2)
          end
        end
      end
    end

    context "when champ is a Textarea" do
      let(:champ) { Champs::TextareaChamp.new(value: 'my_string', dossier: dossier).tap(&:save!) }
      context "When there's already a revision" do
        before {
          ChampRevision.create_or_update_revision(champ, instructeur.id)
          ChampRevision.last.update(updated_at: delay)
          champ.update(value: 'my_string2')
        }
        context "when already champ_revision recent" do
          let(:delay) { 110.seconds.ago }
          it "does not create a new champ_revision" do
            ChampRevision.create_or_update_revision(champ, instructeur.id)
            expect(ChampRevision.where(champ_id: champ).count).to eq(1)
          end
        end

        context "when existing champ_revision is old" do
          let(:delay) { 130.seconds.ago }
          it "does create a new champ_revision" do
            ChampRevision.create_or_update_revision(champ, instructeur.id)
            expect(ChampRevision.where(champ_id: champ).count).to eq(2)
          end
        end
      end
    end
  end
end
