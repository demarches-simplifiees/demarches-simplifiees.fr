# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dossiers::ErrorsFullMessagesComponent, type: :component do
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:types_de_champ_public) { [type: :text] }
  let(:dossier) { create(:dossier, procedure:) }
  let(:component) { described_class.new(dossier:) }

  describe 'render' do
    context 'when dossier does not have any error' do
      subject { render_inline(component).to_html }
      it 'does not render' do
        expect(subject).to eq("")
      end
    end

    context 'when dossier have error' do
      let(:champ) { dossier.champs.first }

      subject do
        dossier.validate(:champs_public_value)
        dossier.check_mandatory_and_visible_champs
        render_inline(component).to_html
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

      context 'when champ is drop_down_list as radio' do
        let(:types_de_champ_public) { [{ type: :drop_down_list, options: %w[first_option other ones] }] }
        it 'focuses on focusable_input_id (first option)' do
          expect(subject).to have_link(champ.libelle, href: "##{champ.input_id}-#{Digest::MD5.hexdigest("first_option")}")
        end
      end

      context 'when champ is drop_down_list as combobox' do
        let(:types_de_champ_public) { [{ type: :drop_down_list, options: %w[a b c d e f] }] }
        it 'focuses on focusable_input_id (first option)' do
          expect(subject).to have_link(champ.libelle, href: "##{champ.input_id}")
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

      context 'when champ is referentiel required and not filled' do
        let(:referentiel) { create(:api_referentiel, :exact_match) }
        let(:types_de_champ_public) { [{ type: :referentiel, referentiel:, mandatory: true }] }
        before { champ.update(external_id: 'kthxbye') }

        it 'focuses on focusable_input_id' do
          expect(subject).to have_link(champ.libelle, href: "##{champ.focusable_input_id}", count: 1)
        end
      end
    end
  end
end
