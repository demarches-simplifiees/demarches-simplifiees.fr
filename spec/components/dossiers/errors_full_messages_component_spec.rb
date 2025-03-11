# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dossiers::ErrorsFullMessagesComponent, type: :component do
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:types_de_champ_public) { [type: :text] }
  let(:dossier) { create(:dossier, procedure:) }
  let(:component) { described_class.new(dossier:) }
  subject { render_inline(component).to_html }

  describe 'render' do
    context 'when dossier does not have any error' do
      it 'does not render' do
        expect(subject).to eq("")
      end
    end

    context 'when dossier have error' do
      let(:champ) { dossier.champs.first }

      before do
        dossier.validate(:champs_public_value)
        dossier.check_mandatory_and_visible_champs
      end

      context 'when champ is repetition' do
        let(:champ_repetition) { dossier.champs.first }
        let(:rows) { champ_repetition.rows }
        let(:champ_child) { rows.first.first }

        let(:types_de_champ_public) { [{ type: :repetition, children: [{ type: :text }] }] }

        it 'focuses on focusable_input_id' do
          expect(subject).to have_link(champ_child.libelle, href: "##{champ_child.focusable_input_id}")
        end
      end

      context 'when champ is civilite' do
        let(:types_de_champ_public) { [{ type: :civilite }] }
        it 'focuses on focusable_input_id' do
          expect(subject).to have_link(champ.libelle, href: "##{champ.focusable_input_id}")
        end
      end

      context 'when champ is epci' do
        let(:types_de_champ_public) { [{ type: :epci }] }
        it 'focuses on focusable_input_id' do
          expect(subject).to have_link(champ.libelle, href: "##{champ.focusable_input_id}")
        end
      end

      context 'when champ is multiple_drop_down_list' do
        let(:types_de_champ_public) { [{ type: :multiple_drop_down_list }] }
        it 'focuses on focusable_input_id' do
          expect(subject).to have_link(champ.libelle, href: "##{champ.focusable_input_id}")
        end
      end

      context 'when champ is yes_no' do
        let(:types_de_champ_public) { [{ type: :yes_no }] }
        it 'focuses on focusable_input_id' do
          expect(subject).to have_link(champ.libelle, href: "##{champ.focusable_input_id}")
        end
      end

      context 'when the champ is simple text' do
        it 'does render' do
          expect(subject).to have_link(champ.type_de_champ.libelle, href: "##{champ.focusable_input_id}")
        end
      end
    end
  end
end
