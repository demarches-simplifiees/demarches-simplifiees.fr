describe EditableChamp::ChampsTreeComponent, type: :component do
  let(:component) { described_class.new(champs: champs, root_depth: 0) }
  subject { component.root }
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
      it 'chunk by uniq champs' do
        expect(subject.header_section).to eq(nil)
        expect(subject.nodes.size).to eq(champs.size)
        expect(subject.nodes).to eq(champs)
      end
    end

    context 'with sections only' do
      let(:champs) do
        [
          header_1,
          champ_explication,
          champ_text,
          header_2,
          champ_textarea
        ]
      end

      it 'chunk by uniq champs' do
        expect(subject.nodes.size).to eq(2)
        expect(subject.nodes[0].header_section).to eq(header_1)
        expect(subject.nodes[0].nodes).to eq([champ_explication, champ_text])
        expect(subject.nodes[1].header_section).to eq(header_2)
        expect(subject.nodes[1].nodes).to eq([champ_textarea])
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
        expect(subject.nodes.size).to eq(4)
        expect(subject.nodes[0]).to eq(champ_text)
        expect(subject.nodes[1]).to eq(champ_textarea)
        expect(subject.nodes[2].header_section).to eq(header_1)
        expect(subject.nodes[2].nodes).to eq([champ_explication, champ_communes])
        expect(subject.nodes[3].header_section).to eq(header_2)
        expect(subject.nodes[3].nodes).to eq([champ_textarea])
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
        expect(subject.nodes.size).to eq(2)
        expect(subject.nodes[0].header_section).to eq(header_1)
        expect(subject.nodes[0].nodes.size).to eq(2)
        expect(subject.nodes[0].nodes[1].header_section).to eq(header_1_2)
        expect(subject.nodes[0].nodes[1].nodes).to eq([champ_communes])
        expect(subject.nodes[1].header_section).to eq(header_2)
        expect(subject.nodes[1].nodes).to eq([champ_textarea])
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
         build(:champ_text),
         header_1_2_2,
         build(:champ_text),
         header_1_2_3,
         build(:champ_text)
       ]
     end
      it 'chunk by uniq champs' do
        expect(subject.nodes.size).to eq(1)
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
        expect(subject.nodes.size).to eq(2)
        expect(subject.nodes[0].header_section).to eq(header_1)
        expect(subject.nodes[0].nodes.size).to eq(2)
        expect(subject.nodes[0].nodes[1].header_section).to eq(header_1_2)
        expect(subject.nodes[0].nodes[1].nodes.size).to eq(2)
        expect(subject.nodes[0].nodes[1].nodes.first).to eq(champ_communes)
        expect(subject.nodes[0].nodes[1].nodes[1].header_section).to eq(header_1_2_3)
        expect(subject.nodes[0].nodes[1].nodes[1].nodes).to eq([champ_text])
        expect(subject.nodes[1].header_section).to eq(header_2)
        expect(subject.nodes[1].nodes).to eq([champ_textarea])
      end
    end
  end
end
