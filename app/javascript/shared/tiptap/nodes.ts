import { Node, mergeAttributes } from '@tiptap/core';

export const DocumentWithHeader = Node.create({
  name: 'doc',
  topNode: true,
  content: 'header title block+'
});

export const Title = Node.create({
  name: 'title',
  content: 'inline*',
  defining: true,
  marks: 'italic underline',

  parseHTML() {
    return [{ tag: `h1`, attrs: { level: 1 } }];
  },
  renderHTML({ HTMLAttributes }) {
    return ['h1', HTMLAttributes, 0];
  }
});

export const Header = Node.create({
  name: 'header',
  content: 'headerColumn headerColumn',
  defining: true,

  parseHTML() {
    return [{ tag: `header` }];
  },
  renderHTML({ HTMLAttributes }) {
    return [
      'header',
      mergeAttributes(HTMLAttributes, { class: 'header flex flex-gap-1' }),
      0
    ];
  }
});

export const HeaderColumn = Node.create({
  name: 'headerColumn',
  content: 'paragraph{1,2}',
  defining: true,

  parseHTML() {
    return [{ tag: `div` }];
  },
  renderHTML({ HTMLAttributes }) {
    return ['div', mergeAttributes(HTMLAttributes, { class: 'flex-1' }), 0];
  }
});
