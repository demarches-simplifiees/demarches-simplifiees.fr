import type { ReactNode } from 'react';
import * as s from 'superstruct';

import type { Loader } from './hooks';

export const Item = s.object({
  label: s.string(),
  value: s.string(),
  data: s.any()
});
export type Item = s.Infer<typeof Item>;

const ArrayOfTuples = s.coerce(
  s.array(Item),
  s.array(s.tuple([s.string(), s.union([s.string(), s.number()])])),
  (items) =>
    items.map<Item>(([label, value]) => ({
      label,
      value: String(value)
    }))
);

const ArrayOfStrings = s.coerce(s.array(Item), s.array(s.string()), (items) =>
  items.map<Item>((label) => ({ label, value: label }))
);

const ComboBoxPropsSchema = s.partial(
  s.object({
    id: s.string(),
    className: s.string(),
    name: s.string(),
    label: s.string(),
    description: s.string(),
    isRequired: s.boolean(),
    'aria-label': s.string(),
    'aria-labelledby': s.string(),
    'aria-describedby': s.string(),
    items: s.union([s.array(Item), ArrayOfStrings, ArrayOfTuples]),
    formValue: s.enums(['text', 'key']),
    form: s.string(),
    data: s.record(s.string(), s.string())
  })
);
export const SingleComboBoxProps = s.assign(
  ComboBoxPropsSchema,
  s.partial(
    s.object({
      selectedKey: s.nullable(s.string()),
      emptyFilterKey: s.nullable(s.string())
    })
  )
);
export const MultiComboBoxProps = s.assign(
  ComboBoxPropsSchema,
  s.partial(
    s.object({
      selectedKeys: s.array(s.string()),
      allowsCustomValue: s.boolean(),
      valueSeparator: s.string()
    })
  )
);
export const RemoteComboBoxProps = s.assign(
  ComboBoxPropsSchema,
  s.partial(
    s.object({
      selectedKey: s.nullable(s.string()),
      minimumInputLength: s.number(),
      limit: s.number(),
      allowsCustomValue: s.boolean()
    })
  )
);
export type SingleComboBoxProps = s.Infer<typeof SingleComboBoxProps> & {
  children?: ReactNode;
};
export type MultiComboBoxProps = s.Infer<typeof MultiComboBoxProps>;
export type RemoteComboBoxProps = s.Infer<typeof RemoteComboBoxProps> & {
  children?: ReactNode;
  loader: Loader | string;
  onChange?: (item: Item | null) => void;
};
