describe TreeableConcern do
  class ChampsToTree
    include TreeableConcern

    attr_reader :root
    def initialize(types_de_champ:)
      @root = to_tree(types_de_champ:)
    end
  end

  subject { ChampsToTree.new(types_de_champ:).root }
  describe "to_tree" do
    let(:header_1) { build(:champ_header_section_level_1).type_de_champ }
    let(:header_1_2) { build(:champ_header_section_level_2).type_de_champ }
    let(:header_2) { build(:champ_header_section_level_1).type_de_champ }
    let(:champ_text) { build(:champ_text).type_de_champ }
    let(:champ_textarea) { build(:champ_textarea).type_de_champ }
    let(:champ_explication) { build(:champ_explication).type_de_champ }
    let(:champ_communes) { build(:champ_communes).type_de_champ }

    context 'without section' do
      let(:types_de_champ) do
        [
          champ_text, champ_textarea
        ]
      end
      it 'inlines champs at root level' do
        expect(subject.size).to eq(types_de_champ.size)
        expect(subject).to eq(types_de_champ)
      end
    end

    context 'with header_section and champs' do
      let(:types_de_champ) do
        [
          header_1,
          champ_explication,
          champ_text,
          header_2,
          champ_textarea
        ]
      end

      it 'wraps champs within preview header section' do
        expect(subject.size).to eq(2)
        expect(subject).to eq([
          [header_1, champ_explication, champ_text],
          [header_2, champ_textarea]
        ])
      end
    end

    context 'leading champs, and in between sections only' do
      let(:types_de_champ) do
        [
          champ_text,
          champ_textarea,
          header_1,
          champ_explication,
          champ_communes,
          header_2,
          champ_textarea
        ]
      end
      it 'chunk by uniq champs' do
        expect(subject.size).to eq(4)
        expect(subject).to eq([
          champ_text,
          champ_textarea,
          [header_1, champ_explication, champ_communes],
          [header_2, champ_textarea]
        ])
      end
    end

    context 'with one sub sections' do
      let(:types_de_champ) do
        [
          header_1,
          champ_explication,
          header_1_2,
          champ_communes,
          header_2,
          champ_textarea
        ]
      end
      it 'chunk by uniq champs' do
        expect(subject.size).to eq(2)
        expect(subject).to eq([
          [header_1, champ_explication, [header_1_2, champ_communes]],
          [header_2, champ_textarea]
        ])
      end
    end

    context 'with consecutive subsection' do
      let(:header_1) { build(:champ_header_section_level_1).type_de_champ }
      let(:header_1_2_1) { build(:champ_header_section_level_2).type_de_champ }
      let(:header_1_2_2) { build(:champ_header_section_level_2).type_de_champ }
      let(:header_1_2_3) { build(:champ_header_section_level_2).type_de_champ }
      let(:types_de_champ) do
       [
         header_1,
         header_1_2_1,
         champ_text,
         header_1_2_2,
         champ_textarea,
         header_1_2_3,
         champ_communes
       ]
     end
      it 'chunk by uniq champs' do
        expect(subject.size).to eq(1)
        expect(subject).to eq([
          [
            header_1,
            [header_1_2_1, champ_text],
            [header_1_2_2, champ_textarea],
            [header_1_2_3, champ_communes]
          ]
        ])
      end
    end

    context 'with one sub sections and one subsub section' do
      let(:header_1_2_3) { build(:champ_header_section_level_3).type_de_champ }

      let(:types_de_champ) do
        [
          header_1,
          champ_explication,
          header_1_2,
          champ_communes,
          header_1_2_3,
          champ_text,
          header_2,
          champ_textarea
        ]
      end

      it 'chunk by uniq champs' do
        expect(subject.size).to eq(2)
        expect(subject).to eq([
          [
            header_1,
            champ_explication,
            [
              header_1_2,
              champ_communes,
              [
                header_1_2_3, champ_text
              ]
            ]
          ],
          [
            header_2,
            champ_textarea
          ]
        ])
      end
    end
  end
end
