export default {
  props: ['state', 'update', 'index', 'item', 'prefix'],
  computed: {
    isDirty() {
      return (
        this.state.version &&
        this.state.unsavedInvalidItems.size > 0 &&
        this.state.unsavedItems.has(this.itemId)
      );
    },
    isInvalid() {
      if (this.deleted) {
        return false;
      }
      if (this.libelle) {
        return !this.libelle.trim();
      }
      return true;
    },
    itemId() {
      return this.item.id || this.clientId;
    },
    changeLog() {
      return [this.itemId, !this.isInvalid];
    },
    itemClassName() {
      const classNames = [`draggable-item-${this.index}`];
      if (this.isHeaderSection) {
        classNames.push('type-header-section');
      }
      if (this.isDirty) {
        if (this.isInvalid) {
          classNames.push('invalid');
        } else {
          classNames.push('dirty');
        }
      }
      return classNames.join(' ');
    },
    isDropDown() {
      return [
        'drop_down_list',
        'multiple_drop_down_list',
        'linked_drop_down_list'
      ].includes(this.typeChamp);
    },
    isFile() {
      return this.typeChamp === 'piece_justificative';
    },
    isCarte() {
      return this.typeChamp === 'carte';
    },
    isExplication() {
      return this.typeChamp === 'explication';
    },
    isHeaderSection() {
      return this.typeChamp === 'header_section';
    },
    options() {
      const options = this.item.options || {};
      for (let key of Object.keys(options)) {
        options[key] = castBoolean(options[key]);
      }
      return options;
    },
    attribute() {
      if (this.state.isAnnotation) {
        return 'types_de_champ_private_attributes';
      } else {
        return 'types_de_champ_attributes';
      }
    }
  },
  data() {
    return {
      typeChamp: this.item.type_champ,
      libelle: this.item.libelle,
      mandatory: this.item.mandatory,
      description: this.item.description,
      dropDownList: this.item.drop_down_list && this.item.drop_down_list.value,
      deleted: false,
      clientId: `id-${clientIds++}`
    };
  },
  created() {
    for (let path of PATHS_TO_WATCH) {
      this.$watch(path, () => this.update(this.changeLog));
    }
  },
  mounted() {
    if (this.isInvalid) {
      this.update(this.changeLog, false);
    }
  },
  methods: {
    removeChamp(item) {
      if (item.id) {
        this.deleted = true;
      } else {
        const index = this.state.typesDeChamp.indexOf(item);
        this.state.typesDeChamp.splice(index, 1);
        this.update([this.itemId, true]);
      }
    },
    nameFor(name) {
      return `${this.prefix}[${this.attribute}][${this.index}][${name}]`;
    },
    elementIdFor(name) {
      return `${this.prefix}_${this.attribute}_${this.index}_${name}`;
    }
  }
};

const PATHS_TO_WATCH = [
  'typeChamp',
  'libelle',
  'mandatory',
  'description',
  'dropDownList',
  'options.quartiers_prioritaires',
  'options.cadastres',
  'options.parcelles_agricoles',
  'index',
  'deleted'
];

function castBoolean(value) {
  return value && value != 0;
}

let clientIds = 0;
