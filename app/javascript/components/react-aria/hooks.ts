import type {
  ComboBoxProps as AriaComboBoxProps,
  TagGroupProps
} from 'react-aria-components';
import { useAsyncList, type AsyncListOptions } from 'react-stately';
import { useMemo, useRef, useState, useEffect } from 'react';
import type { Key } from 'react';
import { matchSorter } from 'match-sorter';
import { useDebounceCallback } from 'usehooks-ts';
import { useEvent } from 'react-use-event-hook';
import isEqual from 'react-fast-compare';
import * as s from 'superstruct';

import { Item } from './props';

export type Loader = AsyncListOptions<Item, string>['load'];

export interface ComboBoxProps
  extends Omit<AriaComboBoxProps<Item>, 'children'> {
  children: React.ReactNode | ((item: Item) => React.ReactNode);
  label?: string;
  description?: string;
}

const inputMap = new WeakMap<HTMLInputElement, string>();
export function useDispatchChangeEvent() {
  const ref = useRef<HTMLSpanElement>(null);

  return {
    ref,
    dispatch: () => {
      requestAnimationFrame(() => {
        const input = ref.current?.querySelector('input');
        if (input) {
          const value = input.value;
          const prevValue = inputMap.get(input) || '';
          if (value != prevValue) {
            inputMap.set(input, value);
            input.dispatchEvent(new Event('change', { bubbles: true }));
          }
        }
      });
    }
  };
}

export function useSingleList({
  defaultItems,
  defaultSelectedKey,
  emptyFilterKey,
  onChange
}: {
  defaultItems?: Item[];
  defaultSelectedKey?: string | null;
  emptyFilterKey?: string | null;
  onChange?: (item: Item | null) => void;
}) {
  const [selectedKey, setSelectedKey] = useState(defaultSelectedKey);
  const items = useMemo(
    () => (defaultItems ? distinctBy(defaultItems, 'value') : []),
    [defaultItems]
  );
  const selectedItem = useMemo(
    () => items.find((item) => item.value == selectedKey) ?? null,
    [items, selectedKey]
  );
  const [inputValue, setInputValue] = useState(() => selectedItem?.label ?? '');
  // show fallback item when input value is not matching any items
  const fallbackItem = useMemo(
    () => items.find((item) => item.value == emptyFilterKey),
    [items, emptyFilterKey]
  );
  const filteredItems = useMemo(() => {
    if (inputValue == '') {
      return items;
    }
    const filteredItems = matchSorter(items, inputValue, { keys: ['label'] });
    if (filteredItems.length == 0 && fallbackItem) {
      return [fallbackItem];
    } else {
      return filteredItems;
    }
  }, [items, inputValue, fallbackItem]);

  const initialSelectedKeyRef = useRef(defaultSelectedKey);

  const setSelection = useEvent((key?: string | null) => {
    const inputValue = key
      ? items.find((item) => item.value == key)?.label
      : '';
    setSelectedKey(key);
    setInputValue(inputValue ?? '');
  });
  const onSelectionChange = useEvent<
    NonNullable<ComboBoxProps['onSelectionChange']>
  >((key) => {
    setSelection(key ? String(key) : null);
    const item =
      typeof key != 'string'
        ? null
        : selectedItem?.value == key
          ? selectedItem
          : (items.find((item) => item.value == key) ?? null);
    onChange?.(item);
  });
  const onInputChange = useEvent<NonNullable<ComboBoxProps['onInputChange']>>(
    (value) => {
      setInputValue(value);
      if (value == '') {
        onSelectionChange(null);
      }
    }
  );
  const onReset = useEvent(() => {
    setSelectedKey(null);
    setInputValue('');
  });

  // reset default selected key when props change
  useEffect(() => {
    if (initialSelectedKeyRef.current != defaultSelectedKey) {
      initialSelectedKeyRef.current = defaultSelectedKey;
      setSelection(defaultSelectedKey);
    }
  }, [defaultSelectedKey, setSelection]);

  return {
    selectedItem,
    selectedKey,
    onSelectionChange,
    inputValue,
    onInputChange,
    items: filteredItems,
    onReset
  };
}

export function useMultiList({
  defaultItems,
  defaultSelectedKeys,
  allowsCustomValue,
  valueSeparator,
  onChange,
  focusInput,
  formValue
}: {
  defaultItems?: Item[];
  defaultSelectedKeys?: string[];
  allowsCustomValue?: boolean;
  valueSeparator?: string;
  onChange?: () => void;
  focusInput?: () => void;
  formValue?: 'text' | 'key';
}) {
  const valueSeparatorRegExp = useMemo(
    () => (valueSeparator ? new RegExp(valueSeparator) : /\s|,|;/),
    [valueSeparator]
  );
  const [selectedKeys, setSelectedKeys] = useState(
    () => new Set(defaultSelectedKeys ?? [])
  );
  const [inputValue, setInputValue] = useState('');
  const items = useMemo(
    () => (defaultItems ? distinctBy(defaultItems, 'value') : []),
    [defaultItems]
  );
  const itemsIndex = useMemo(() => {
    const index = new Map<string, Item>();
    for (const item of items) {
      index.set(item.value, item);
    }
    return index;
  }, [items]);
  const filteredItems = useMemo(
    () =>
      inputValue.length == 0
        ? items
        : matchSorter(items, inputValue, { keys: ['label'] }),
    [items, inputValue]
  );
  const selectedItems = useMemo(() => {
    const selectedItems: Item[] = [];
    for (const key of selectedKeys) {
      const item = itemsIndex.get(key);
      if (item) {
        selectedItems.push(item);
      } else if (allowsCustomValue) {
        selectedItems.push({ label: key, value: key });
      }
    }
    return selectedItems;
  }, [itemsIndex, selectedKeys, allowsCustomValue]);
  const hiddenInputValues = useMemo(() => {
    const values = selectedItems.map((item) =>
      formValue == 'text' || allowsCustomValue ? item.label : item.value
    );
    if (!allowsCustomValue || inputValue == '') {
      return values;
    }
    return [
      ...new Set([
        ...values,
        ...inputValue.split(valueSeparatorRegExp).filter(Boolean)
      ])
    ];
  }, [
    selectedItems,
    inputValue,
    valueSeparatorRegExp,
    allowsCustomValue,
    formValue
  ]);
  const isSelectionSetRef = useRef(false);
  const initialSelectedKeysRef = useRef(defaultSelectedKeys);

  // reset default selected keys when props change
  useEffect(() => {
    if (!isEqual(initialSelectedKeysRef.current, defaultSelectedKeys)) {
      initialSelectedKeysRef.current = defaultSelectedKeys;
      setSelectedKeys(new Set(defaultSelectedKeys));
    }
  }, [defaultSelectedKeys]);

  const onSelectionChange = useEvent<
    NonNullable<ComboBoxProps['onSelectionChange']>
  >((key) => {
    if (key) {
      isSelectionSetRef.current = true;
      setSelectedKeys((keys) => {
        const selectedKeys = new Set(keys.values());
        selectedKeys.add(String(key));
        return selectedKeys;
      });
      setInputValue('');
      onChange?.();
    }
  });

  const onInputChange = useEvent<NonNullable<ComboBoxProps['onInputChange']>>(
    (value) => {
      const isSelectionSet = isSelectionSetRef.current;
      isSelectionSetRef.current = false;
      if (isSelectionSet) {
        setInputValue('');
        return;
      }
      if (allowsCustomValue) {
        const values = value.split(valueSeparatorRegExp);
        // if input contains a separator, add all values
        if (values.length > 1) {
          const addedKeys = values.filter(Boolean);
          setSelectedKeys((keys) => {
            const selectedKeys = new Set(keys.values());
            for (const key of addedKeys) {
              selectedKeys.add(key);
            }
            return selectedKeys;
          });
          setInputValue('');
        } else {
          setInputValue(value);
        }
        onChange?.();
      } else {
        setInputValue(value);
      }
    }
  );

  const onRemove = useEvent<NonNullable<TagGroupProps['onRemove']>>(
    (removedKeys) => {
      setSelectedKeys((keys) => {
        const selectedKeys = new Set(keys.values());
        for (const key of removedKeys) {
          selectedKeys.delete(String(key));
        }
        // focus input when all items are removed
        if (selectedKeys.size == 0) {
          focusInput?.();
        }
        return selectedKeys;
      });
      onChange?.();
    }
  );

  const onReset = useEvent(() => {
    setSelectedKeys(new Set());
    setInputValue('');
  });

  return {
    onRemove,
    onSelectionChange,
    onInputChange,
    selectedItems,
    items: filteredItems,
    hiddenInputValues,
    inputValue,
    onReset
  };
}

export function useRemoteList({
  load,
  defaultItems,
  defaultSelectedKey,
  onChange,
  debounce,
  allowsCustomValue
}: {
  load: Loader;
  defaultItems?: Item[];
  defaultSelectedKey?: Key | null;
  onChange?: (item: Item | null) => void;
  debounce?: number;
  allowsCustomValue?: boolean;
}) {
  const [defaultSelectedItem, setSelectedItem] = useState<Item | null>(() => {
    if (defaultItems) {
      return (
        defaultItems.find((item) => item.value == defaultSelectedKey) ?? null
      );
    }
    return null;
  });
  const [inputValue, setInputValue] = useState(
    defaultSelectedItem?.label ?? ''
  );
  const selectedItem = useMemo<Item | null>(() => {
    if (defaultSelectedItem) {
      return defaultSelectedItem;
    }
    if (allowsCustomValue && inputValue != '') {
      return { label: inputValue, value: inputValue };
    }
    return null;
  }, [defaultSelectedItem, inputValue, allowsCustomValue]);
  const list = useAsyncList<Item>({ getKey, load });
  const setFilterText = useEvent((filterText: string) => {
    list.setFilterText(filterText);
  });
  const debouncedSetFilterText = useDebounceCallback(
    setFilterText,
    debounce ?? 300
  );

  const onSelectionChange = useEvent<
    NonNullable<ComboBoxProps['onSelectionChange']>
  >((key) => {
    const item =
      typeof key != 'string'
        ? null
        : selectedItem?.value == key
          ? selectedItem
          : (items.find((item) => item.value == key) ?? null);
    setSelectedItem(item);
    if (item) {
      setInputValue(item.label);
    } else if (!allowsCustomValue) {
      setInputValue('');
    }
    onChange?.(item);
  });

  const onInputChange = useEvent<NonNullable<ComboBoxProps['onInputChange']>>(
    (value) => {
      debouncedSetFilterText(value);
      setInputValue(value);
      if (value == '') {
        onSelectionChange(null);
      } else if (allowsCustomValue && selectedItem?.label != value) {
        onChange?.(selectedItem);
      }
    }
  );

  const onReset = useEvent(() => {
    setSelectedItem(null);
    setInputValue('');
  });

  // add to items list current selected item if it's not in the list
  const items =
    selectedItem && !list.getItem(selectedItem.value)
      ? [selectedItem, ...list.items]
      : list.items;

  return {
    selectedItem,
    selectedKey: selectedItem?.value ?? null,
    onSelectionChange,
    inputValue,
    onInputChange,
    items,
    onReset
  };
}

function getKey(item: Item) {
  return item.value;
}

const AnnuaireEducationPayload = s.type({
  records: s.array(
    s.type({
      fields: s.type({
        identifiant_de_l_etablissement: s.string(),
        nom_etablissement: s.string(),
        nom_commune: s.string()
      })
    })
  )
});

const Coerce = {
  Default: s.array(Item),
  AnnuaireEducation: s.coerce(
    s.array(Item),
    AnnuaireEducationPayload,
    ({ records }) =>
      records.map((record) => ({
        label: `${record.fields.nom_etablissement}, ${record.fields.nom_commune} (${record.fields.identifiant_de_l_etablissement})`,
        value: record.fields.identifiant_de_l_etablissement,
        data: record
      }))
  )
};

export const createLoader: (
  source: string,
  options?: {
    minimumInputLength?: number;
    limit?: number;
    param?: string;
    coerce?: keyof typeof Coerce;
  }
) => Loader =
  (source, options) =>
  async ({ signal, filterText }) => {
    const url = new URL(source, location.href);
    const minimumInputLength = options?.minimumInputLength ?? 2;
    const param = options?.param ?? 'q';
    const limit = options?.limit ?? 10;

    if (!filterText || filterText.length < minimumInputLength) {
      return { items: [] };
    }
    url.searchParams.set(param, filterText);
    try {
      const response = await fetch(url.toString(), {
        headers: { accept: 'application/json' },
        signal
      });
      if (response.ok) {
        const json = await response.json();
        const struct = Coerce[options?.coerce ?? 'Default'];
        const [err, items] = s.validate(json, struct, { coerce: true });
        if (!err) {
          if (items.length > limit) {
            const filteredItems = matchSorter(items, filterText, {
              keys: ['label']
            });
            return { items: filteredItems.slice(0, limit) };
          }
          return { items };
        }
      }
      return { items: [] };
    } catch {
      return { items: [] };
    }
  };

export function useLabelledBy(id?: string, ariaLabelledby?: string) {
  return useMemo(
    () => (ariaLabelledby ? ariaLabelledby : findLabelledbyId(id)),
    [id, ariaLabelledby]
  );
}

function findLabelledbyId(id?: string) {
  if (!id) {
    return;
  }
  const label = document.querySelector(`[for="${id}"]`);
  if (!label?.id) {
    return;
  }
  return label.id;
}

export function useOnFormReset(onReset?: () => void) {
  const ref = useRef<HTMLInputElement>(null);
  const onResetListener = useEvent<EventListener>((event) => {
    if (event.target == ref.current?.form) {
      onReset?.();
    }
  });
  useEffect(() => {
    if (onReset) {
      addEventListener('reset', onResetListener);
      return () => {
        removeEventListener('reset', onResetListener);
      };
    }
  }, [onReset, onResetListener]);

  return ref;
}

function distinctBy<T>(array: T[], key: keyof T): T[] {
  const keys = array.map((item) => item[key]);
  return array.filter((item, index) => keys.indexOf(item[key]) == index);
}
