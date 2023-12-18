import Document from '@tiptap/extension-document';
import Hystory from '@tiptap/extension-history';
import TextAlign from '@tiptap/extension-text-align';
import Gapcursor from '@tiptap/extension-gapcursor';

import Paragraph from '@tiptap/extension-paragraph';
import BulletList from '@tiptap/extension-bullet-list';
import OrderedList from '@tiptap/extension-ordered-list';
import ListItem from '@tiptap/extension-list-item';

import Text from '@tiptap/extension-text';
import Highlight from '@tiptap/extension-highlight';
import Underline from '@tiptap/extension-underline';
import Bold from '@tiptap/extension-bold';
import Italic from '@tiptap/extension-italic';
import Strike from '@tiptap/extension-strike';
import Mention from '@tiptap/extension-mention';
import Typography from '@tiptap/extension-typography';
import Heading from '@tiptap/extension-heading';

import {
  Editor,
  type EditorOptions,
  type JSONContent,
  type Extensions
} from '@tiptap/core';

import {
  DocumentWithHeader,
  Title,
  Header,
  Footer,
  HeaderColumn
} from './nodes';
import { createSuggestionMenu, type TagSchema } from './tags';

export function createEditor({
  editorElement,
  content,
  tags,
  buttons,
  onChange
}: {
  editorElement: Element;
  content?: JSONContent;
  tags: TagSchema[];
  buttons: string[];
  onChange(change: { editor: Editor }): void;
}): Editor {
  const options = getEditorOptions(editorElement, tags, buttons, content);
  const editor = new Editor(options);
  editor.on('transaction', onChange);
  return editor;
}

function getEditorOptions(
  element: Element,
  tags: TagSchema[],
  actions: string[],
  content?: JSONContent
): Partial<EditorOptions> {
  const extensions: Extensions = [];
  for (const action of actions) {
    switch (action) {
      case 'bold':
        extensions.push(Bold);
        break;
      case 'italic':
        extensions.push(Italic);
        break;
      case 'underline':
        extensions.push(Underline);
        break;
      case 'strike':
        extensions.push(Strike);
        break;
      case 'highlight':
        extensions.push(Highlight);
        break;
      case 'bulletList':
        extensions.push(BulletList);
        break;
      case 'orderedList':
        extensions.push(OrderedList);
        break;
      case 'left':
      case 'center':
      case 'right':
      case 'justify':
        extensions.push(
          TextAlign.configure({
            types: actions.includes('title')
              ? ['headerColumn', 'title', 'footer', 'heading', 'paragraph']
              : ['heading', 'paragraph']
          })
        );
        break;
      case 'title':
        extensions.push(Header, HeaderColumn, Title, Footer);
        break;
      case 'heading2':
      case 'heading3':
        extensions.push(Heading.configure({ levels: [2, 3] }));
        break;
    }
  }

  if (actions.includes('bulletList') || actions.includes('orderedList')) {
    extensions.push(ListItem);
  }
  if (tags.length > 0) {
    extensions.push(
      Mention.configure({
        renderLabel({ node }) {
          return `--${node.attrs.label}--`;
        },
        HTMLAttributes: {
          class: 'fr-badge fr-badge--sm fr-badge--info fr-badge--no-icon'
        },
        suggestion: createSuggestionMenu(tags, element)
      })
    );
  }

  return {
    element,
    content,
    editorProps: { attributes: { class: 'fr-input' } },
    extensions: [
      actions.includes('title') ? DocumentWithHeader : Document,
      Hystory,
      Typography.configure({
        emDash: false
      }),
      Gapcursor,
      Paragraph,
      Text,
      ...extensions
    ]
  };
}
