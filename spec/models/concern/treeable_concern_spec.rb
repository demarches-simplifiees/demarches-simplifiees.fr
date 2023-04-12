describe TreeableConcern do
  class ChampsToTree
    include TreeableConcern

    attr_reader :root
    def initialize(champs:, root_depth:)
      @root = to_tree(champs:, root_depth:)
    end
  end

  subject { ChampsToTree.new(champs: champs, root_depth: 0).root }
  describe "to_tree" do
    let(:header_1) { build(:champ_header_section_level_1) }
    let(:header_1_2) { build(:champ_header_section_level_2) }
    let(:header_2) { build(:champ_header_section_level_1) }
    let(:champ_text) { build(:champ_text) }
    let(:champ_textarea) { build(:champ_textarea) }
    let(:champ_explication) { build(:champ_explication) }
    let(:champ_communes) { build(:champ_communes) }

    context 'without section' do
      let(:champs) do
        [
          champ_text, champ_textarea
        ]
      end
      it 'inlines champs at root level' do
        expect(subject.size).to eq(champs.size)
        expect(subject).to eq(champs)
      end
    end

    context 'with header_section and champs' do
      let(:champs) do
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
      let(:champs) do
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
      let(:champs) do
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
      let(:header_1) { build(:champ_header_section_level_1) }
      let(:header_1_2_1) { build(:champ_header_section_level_2) }
      let(:header_1_2_2) { build(:champ_header_section_level_2) }
      let(:header_1_2_3) { build(:champ_header_section_level_2) }
      let(:champs) do
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
      let(:header_1_2_3) { build(:champ_header_section_level_3) }

      let(:champs) do
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
