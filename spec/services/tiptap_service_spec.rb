RSpec.describe TiptapService do
  let(:json) do
    {
      type: 'doc',
      content: [
        {
          type: 'header',
          content: [
            {
              type: 'headerColumn',
              content: [{ type: 'text', text: 'Left' }]
            },
            {
              type: 'headerColumn',
              content: [{ type: 'text', text: 'Right' }]
            }
          ]
        },
        {
          type: 'title',
          content: [{ type: 'text', text: 'Title' }]
        },
        {
          type: 'title' # remained empty in editor
        },
        {
          type: 'heading',
          attrs: { level: 2, textAlign: 'center' },
          content: [{ type: 'text', text: 'Heading 2' }]
        },
        {
          type: 'heading',
          attrs: { level: 3, textAlign: 'center' },
          content: [{ type: 'text', text: 'Heading 3' }]
        },
        {
          type: 'heading',
          attrs: { level: 3 } # remained empty in editor
        },
        {
          type: 'paragraph',
          attrs: { textAlign: 'right' },
          content: [{ type: 'text', text: 'First paragraph' }]
        },
        {
          type: 'paragraph',
          content: [
            {
              type: 'text',
              text: 'Bonjour ',
              marks: [{ type: 'italic' }, { type: 'strike' }]
            },
            {
              type: 'mention',
              attrs: { id: 'name', label: 'Nom' },
              marks: [{ type: 'bold' }, { type: 'underline' }]
            },
            {
              type: 'text',
              text: ' '
            },
            {
              type: 'text',
              text: '!',
              marks: [{ type: 'highlight' }]
            }
          ]
        },
        {
          type: 'paragraph'
          # no content, empty line
        },
        {
          type: 'bulletList',
          content: [
            {
              type: 'listItem',
              content: [
                {
                  type: 'paragraph',
                  content: [
                    {
                      type: 'text',
                      text: 'Item 1'
                    }
                  ]
                }
              ]
            },
            {
              type: 'listItem',
              content: [
                {
                  type: 'paragraph',
                  content: [
                    {
                      type: 'text',
                      text: 'Item 2'
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          type: 'orderedList',
          content: [
            {
              type: 'listItem',
              content: [
                {
                  type: 'paragraph',
                  content: [
                    {
                      type: 'text',
                      text: 'Item 1'
                    }
                  ]
                }
              ]
            },
            {
              type: 'listItem',
              content: [
                {
                  type: 'paragraph',
                  content: [
                    {
                      type: 'text',
                      text: 'Item 2'
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          type: 'footer',
          content: [{ type: 'text', text: 'Footer' }]
        }
      ]
    }
  end

  describe '.to_html' do
    let(:substitutions) { { 'name' => 'Paul' } }
    let(:html) do
      [
        '<header><div>Left</div><div>Right</div></header>',
        '<h1>Title</h1>',
        '<h2 class="body-start" style="text-align: center">Heading 2</h2>',
        '<h3 style="text-align: center">Heading 3</h3>',
        '<p style="text-align: right">First paragraph</p>',
        '<p><s><em>Bonjour </em></s><u><strong>Paul</strong></u> <mark>!</mark></p>',
        '<ul><li><p>Item 1</p></li><li><p>Item 2</p></li></ul>',
        '<ol><li><p>Item 1</p></li><li><p>Item 2</p></li></ol>',
        '<footer>Footer</footer>'
      ].join
    end

    it 'returns html' do
      expect(described_class.new.to_html(json, substitutions)).to eq(html)
    end

    context 'body start on paragraph' do
      let(:json) do
        {
          type: 'doc',
          content: [
            {
              type: 'title',
              content: [{ type: 'text', text: 'The Title' }]
            },
            {
              type: 'paragraph',
              content: [{ type: 'text', text: 'First paragraph' }]
            }
          ]
        }
      end

      it 'defines stat body on first paragraph' do
        expect(described_class.new.to_html(json, substitutions)).to eq("<h1>The Title</h1><p class=\"body-start\">First paragraph</p>")
      end
    end
  end

  describe '#used_tags' do
    it 'returns used tags' do
      expect(described_class.new.used_tags_and_libelle_for(json)).to eq(Set.new([['name', 'Nom']]))
    end
  end

  describe '.to_path' do
    let(:substitutions) { { "dossier_number" => "42" } }
    let(:json) do
      {
        "content" => [
          { "type" => "paragraph", "content" => [{ "text" => "export_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }, { "text" => " .pdf", "type" => "text" }] }
        ]

      }.deep_symbolize_keys
    end

    it 'returns path' do
      expect(described_class.new.to_path(json, substitutions)).to eq("export_42.pdf")
    end
  end
end
