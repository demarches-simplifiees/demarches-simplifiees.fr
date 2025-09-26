# frozen_string_literal: true

describe EditableChamp::RepetitionComponent, type: :component do
  describe "aria-labelledby" do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, libelle: 'Répétition', children: }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
    let(:repetition_champ) { dossier.project_champs_public.first }

    subject(:render) do
      component = nil
      ActionView::Base.empty.form_for(repetition_champ, url: '/') do |form|
        component = described_class.new(champ: repetition_champ, form:)
      end

      render_inline(component)
    end

    context "when the procedure has only one champ per row" do
      let(:champ) { repetition_champ.rows.first.first }

      context "for type text" do
        let(:children) { [{ type: :text, libelle: 'Prénom', mandatory: false }] }

        it do
          # we should match
          # aria-labelledby="champ-66-legend champ-67-01JWAZPQ0MZFCTPJ4SRV8YSGP2-label"
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end

        it "should have a fieldset legend for the repetition" do
          expect(subject).to have_selector("legend[id='#{repetition_champ.html_id}-legend']", text: "Répétition")
        end

        it "should not have a fieldset legend for the row" do
          expect(subject).not_to have_selector("legend[id='#{champ.parent.html_id(champ.row_id)}-legend']")
        end

        it "the label in the rows should contain the row number" do
          expect(subject).to have_selector("label[id='#{champ.html_id}-label']", text: "Prénom\n1")
        end
      end

      context "for textarea" do
        let(:children) { [{ type: :textarea }] }

        it do
          expect(subject).to have_selector("textarea[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type email" do
        let(:children) { [{ type: :email }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type date" do
        let(:children) { [{ type: :date }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type datetime" do
        let(:children) { [{ type: :datetime }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type dossier_link" do
        let(:children) { [{ type: :dossier_link }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type civilite" do
        let(:children) { [{ type: :civilite }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label #{champ.html_id}-input-female-label']")
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label #{champ.html_id}-input-male-label']")
        end
      end

      context "for type phone" do
        let(:children) { [{ type: :phone }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type number" do
        let(:children) { [{ type: :number }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type decimal_number" do
        let(:children) { [{ type: :decimal_number }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type integer_number" do
        let(:children) { [{ type: :integer_number }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type iban" do
        let(:children) { [{ type: :iban }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type checkbox" do
        let(:children) { [{ type: :checkbox }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type drop_down_list" do
        context "as radio button" do
          let(:children) { [{ type: :drop_down_list, drop_down_options: ["Option 1", "Option 2"] }] }

          it do
            champ.options_for_select_with_other.each do |_option, value|
              expect(subject).to have_selector("input[type='radio'][aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label #{champ.radio_label_id(value)}']")
            end
          end
        end

        context "as select" do
          let(:children) { [{ type: :drop_down_list, drop_down_options: Array.new(6) { "Option #{it + 1}" } }] }

          it do
            expect(subject).to have_selector("select[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
          end
        end

        context "as combobox" do
          let(:children) { [{ type: :drop_down_list, drop_down_options: Array.new(30) { "Option #{it + 1}" } }] }
          it do
            subject

            props = JSON.parse(page.first('react-component')['props'])
            expect(props['ariaLabelledbyPrefix']).to eq("#{repetition_champ.html_id}-legend")
            expect(props['labelId']).to eq("#{champ.html_id}-label")
          end
        end
      end

      context "for type engagement_juridique" do
        let(:children) { [{ type: :engagement_juridique }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type yes_no" do
        let(:children) { [{ type: :yes_no }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label #{champ.html_id}-input-yes-label']")
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label #{champ.html_id}-input-no-label']")
        end
      end

      context "for type siret" do
        let(:children) { [{ type: :siret }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type rna" do
        let(:children) { [{ type: :rna }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type rnf" do
        let(:children) { [{ type: :rnf }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type cnaf" do
        let(:children) { [{ type: :cnaf }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']", count: 2)
        end
      end

      context "for type dgfip" do
        let(:children) { [{ type: :dgfip }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']", count: 2)
        end
      end

      context "for type pole_emploi" do
        let(:children) { [{ type: :pole_emploi }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type mesri" do
        let(:children) { [{ type: :mesri }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type regions" do
        let(:children) { [{ type: :regions }] }

        it do
          expect(subject).to have_selector("select[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type pays" do
        let(:children) { [{ type: :pays }] }

        it do
          expect(subject).to have_selector("select[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type epci" do
        let(:children) { [{ type: :epci }] }

        before do
          champ.code_departement = '75'
          champ.save!
        end

        it do
          expect(subject).to have_selector("select[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label #{champ.html_id}-input-code_departement-label']")
          expect(subject).to have_selector("select[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label #{champ.html_id}-input-value-label']")
        end
      end

      context "for type departements" do
        let(:children) { [{ type: :departements }] }

        it do
          expect(subject).to have_selector("select[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type formatted" do
        let(:children) { [{ type: :formatted }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      xcontext "for type referentiel" do
        let!(:referentiel) { create(:referentiel, :configured, name: 'test') }
        let(:children) { [{ type: :referentiel, referentiel_id: referentiel.id }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type communes" do
        let(:children) { [{ type: :communes }] }

        it do
          subject
          props = JSON.parse(page.first('react-component')['props'])
          expect(props['ariaLabelledbyPrefix']).to eq("#{repetition_champ.html_id}-legend")
          expect(props['labelId']).to eq("#{champ.html_id}-label")
        end
      end

      context "for type multiple_drop_down_list" do
        context "as checkbox" do
          let(:children) { [{ type: :multiple_drop_down_list, drop_down_options: Array.new(3) { "Option #{it + 1}" } }] }

          it do
            champ.options_for_select_with_other.each do |_option, value|
              expect(subject).to have_selector("input[type='checkbox'][aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label #{champ.checkbox_label_id(value)}']")
            end
          end
        end

        context "as combobox" do
          let(:children) { [{ type: :multiple_drop_down_list, drop_down_options: Array.new(30) { "Option #{it + 1}" } }] }

          it do
            subject
            props = JSON.parse(page.first('react-component')['props'])
            expect(props['ariaLabelledbyPrefix']).to eq("#{repetition_champ.html_id}-legend")
            expect(props['labelId']).to eq("#{champ.html_id}-label")
          end
        end
      end

      xcontext "for type linked_drop_down_list" do
        let(:children) { [{ type: :linked_drop_down_list }] }

        # TODO: à voir avec Corinne, fieldset legend manquant ?
        it do
          expect(subject).to have_selector("select[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type piece_justificative" do
        before do
          allow_any_instance_of(ApplicationController).to receive(:administrateur_signed_in?).and_return(false)
        end

        let(:children) { [{ type: :piece_justificative }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type titre_identite" do
        let(:children) { [{ type: :titre_identite }] }

        it do
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-label']")
        end
      end

      context "for type annuaire_education" do
        let(:children) { [{ type: :annuaire_education }] }

        it do
          subject
          props = JSON.parse(page.first('react-component')['props'])
          expect(props['ariaLabelledbyPrefix']).to eq("#{repetition_champ.html_id}-legend")
          expect(props['labelId']).to eq("#{champ.html_id}-label")
        end
      end

      context "for type address" do
        let(:children) { [{ type: :address }] }

        it do
          # first legend of the repetition
          expect(subject).to have_selector("legend[id='#{repetition_champ.html_id}-legend']")

          # label
          expect(subject).to have_selector("label[id='#{champ.html_id}-label']")

          # input
          props = JSON.parse(page.first("react-component")['props'])
          expect(props['ariaLabelledbyPrefix']).to eq("#{repetition_champ.html_id}-legend")
          expect(props['labelId']).to eq("#{champ.html_id}-label")

          # not in ban checkbox
          expect(subject).to have_selector("label[id='#{champ.input_label_id(:not_in_ban)}']")

          # input of the not in ban checkbox
          expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.input_label_id(:not_in_ban)}']")
        end

        context "when the address is not in the BAN" do
          context "not in France" do
            before do
              champ.country_code = 'US'
              champ.not_in_ban = 'true'
              champ.save!
            end

            it do
              # first legend of the repetition
              expect(subject).to have_selector("legend[id='#{repetition_champ.html_id}-legend']")
              # second legend of the champ address
              expect(subject).to have_selector("legend[id='#{champ.html_id}-legend']")

              # label of the country select
              expect(subject).to have_selector("label[id='#{champ.input_label_id(:country_code)}']")
              # select of the country
              expect(subject).to have_selector("select[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-legend #{champ.input_label_id(:country_code)}']")

              # label of the street address
              expect(subject).to have_selector("label[id='#{champ.input_label_id(:street_address)}']")
              # input of the street address
              expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-legend #{champ.input_label_id(:street_address)}']")

              # label of the city input
              expect(subject).to have_selector("label[id='#{champ.input_label_id(:city_name)}']")
              # input of the city
              expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-legend #{champ.input_label_id(:city_name)}']")

              # label of the postal code input
              expect(subject).to have_selector("label[id='#{champ.input_label_id(:postal_code)}']")
              # input of the postal code
              expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{champ.html_id}-legend #{champ.input_label_id(:postal_code)}']")
            end
          end

          context "in France" do
            before do
              champ.country_code = 'FR'
              champ.not_in_ban = 'true'
              champ.save!
            end

            it do
              # label of the commune input
              expect(subject).to have_selector("label[id='#{champ.input_label_id(:commune_name)}']")
              # input of the commune
              props = JSON.parse(page.first(".not-in-ban-fieldset react-component")['props'])
              expect(props['ariaLabelledbyPrefix']).to eq("#{repetition_champ.html_id}-legend #{champ.html_id}-legend")
              expect(props['labelId']).to eq(champ.input_label_id(:commune_name))
            end
          end
        end
      end

      context "for type carte" do
        let(:children) { [{ type: :carte }] }

        it do
          subject
          attribute = JSON.parse(page.first("react-component")['props'])['ariaLabelledbyPrefix']
          expect(attribute).to eq("#{repetition_champ.html_id}-legend #{champ.html_id}-label")
        end
      end
    end

    context "when the procedure has multiple champs per row" do
      let(:children) { [{ type: :text, libelle: 'Prénom' }, { type: :text, libelle: 'Nom' }] }
      let(:text_champ) { repetition_champ.rows.first.first }
      let(:text_champ_2) { repetition_champ.rows.first.last }

      it "should have a fieldset legend for the repetition" do
        expect(subject).to have_selector("legend[id='#{repetition_champ.html_id}-legend']", text: "Répétition")
      end

      it "should have a fieldset legend for the row with the row number" do
        expect(subject).to have_selector("legend[id='#{text_champ.parent.html_id(text_champ.row_id)}-legend']", text: "Répétition 1")
      end

      it "the label in the rows should not contain the row number" do
        expect(subject).to have_selector("label[id='#{text_champ.html_id}-label']", text: "Prénom")
        expect(subject).to have_selector("label[id='#{text_champ_2.html_id}-label']", text: "Nom")
      end

      it "should have an aria-labelledby that contains the id of the row fieldset and the label id" do
        # we should match
        # aria-labelledby='champ-110-01JWB4MXPDCFFKMBBGA01FY0M6-legend champ-111-01JWB4MXPDCFFKMBBGA01FY0M6-label'
        expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.type_de_champ.html_id(text_champ.row_id)}-legend #{text_champ.html_id}-label']")
        expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.type_de_champ.html_id(text_champ_2.row_id)}-legend #{text_champ_2.html_id}-label']")
      end
    end
  end
end
