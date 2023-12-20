RSpec.describe TiptapService do
  describe '.to_html' do
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
            attrs: { level: 1 },
            content: [{ type: 'text', text: 'Heading 1' }]
          },
          {
            type: 'heading',
            attrs: { level: 2, textAlign: 'center' },
            content: [{ type: 'text', text: 'Heading 2' }]
          },
          {
            type: 'heading',
            attrs: { level: 3 },
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
                attrs: { id: 'name' },
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
    let(:tags) { { 'name' => 'Paul' } }
    let(:html) do
      [
        '<header><div>Left</div><div>Right</div></header>',
        '<h1>Title</h1>',
        '<h1>Heading 1</h1>',
        '<h2 style="text-align: center">Heading 2</h2>',
        '<h3>Heading 3</h3>',
        '<p class="body-start" style="text-align: right">First paragraph</p>',
        '<p><s><em>Bonjour </em></s><u><strong>Paul</strong></u> <mark>!</mark></p>',
        '<ul><li><p>Item 1</p></li><li><p>Item 2</p></li></ul>',
        '<ol><li><p>Item 1</p></li><li><p>Item 2</p></li></ol>',
        '<footer>Footer</footer>'
      ].join
    end

    it 'returns html' do
      expect(described_class.new.to_html(json, tags)).to eq(html)
    end
  end
end
