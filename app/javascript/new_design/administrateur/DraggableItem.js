import { getJSON, debounce } from '@utils';
import Uploader from '../../shared/activestorage/uploader';

export default {
  props: ['state', 'index', 'item'],
  computed: {
    isValid() {
      if (this.deleted) {
        return true;
      }
      if (this.libelle) {
        return !!this.libelle.trim();
      }
      return false;
    },
    itemClassName() {
      const classNames = [`draggable-item-${this.index}`];
      if (this.isHeaderSection) {
        classNames.push('type-header-section');
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
    isRepetition() {
      return this.typeChamp === 'repetition';
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
    },
    payload() {
      const payload = {
        libelle: this.libelle,
        type_champ: this.typeChamp,
        mandatory: this.mandatory,
        description: this.description,
        drop_down_list_value: this.dropDownListValue,
        order_place: this.index
      };
      if (this.pieceJustificativeTemplate) {
        payload.piece_justificative_template = this.pieceJustificativeTemplate;
      }
      if (this.state.parentId) {
        payload.parent_id = this.state.parentId;
      }
      if (!this.id && this.state.isAnnotation) {
        payload.private = true;
      }
      Object.assign(payload, this.options);
      return payload;
    },
    saveUrl() {
      if (this.id) {
        return `${this.state.saveUrl}/${this.id}`;
      }
      return this.state.saveUrl;
    },
    savePayload() {
      if (this.deleted) {
        return {};
      }
      return { type_de_champ: this.payload };
    },
    saveMethod() {
      if (this.deleted) {
        return 'delete';
      } else if (this.id) {
        return 'patch';
      }
      return 'post';
    },
    typesDeChamp() {
      return this.item.types_de_champ;
    },
    typesDeChampOptions() {
      return this.state.typesDeChampOptions.filter(
        ([, typeChamp]) => !EXCLUDE_FROM_REPETITION.includes(typeChamp)
      );
    },
    stateForRepetition() {
      return Object.assign({}, this.state, {
        typesDeChamp: this.typesDeChamp,
        typesDeChampOptions: this.typesDeChampOptions,
        prefix: `${this.state.prefix}[${this.attribute}][${this.index}]`,
        parentId: this.id
      });
    }
  },
  data() {
    return {
      id: this.item.id,
      typeChamp: this.item.type_champ,
      libelle: this.item.libelle,
      mandatory: this.item.mandatory,
      description: this.item.description,
      pieceJustificativeTemplate: null,
      pieceJustificativeTemplateUrl: this.item.piece_justificative_template_url,
      pieceJustificativeTemplateFilename: this.item
        .piece_justificative_template_filename,
      dropDownListValue: this.item.drop_down_list_value,
      deleted: false,
      isSaving: false,
      isUploading: false,
      hasChanges: false
    };
  },
  watch: {
    index() {
      this.update();
    }
  },
  created() {
    this.debouncedSave = debounce(() => this.save(), 500);
    this.debouncedUpload = debounce(evt => this.upload(evt), 500);
  },
  methods: {
    removeChamp() {
      if (this.id) {
        this.deleted = true;
        this.debouncedSave();
      } else {
        const index = this.state.typesDeChamp.indexOf(this.item);
        this.state.typesDeChamp.splice(index, 1);
      }
    },
    nameFor(name) {
      return `${this.state.prefix}[${this.attribute}][${this.index}][${name}]`;
    },
    elementIdFor(name) {
      const prefix = this.state.prefix.replace(/\[/g, '_').replace(/\]/g, '');
      return `${prefix}_${this.attribute}_${this.index}_${name}`;
    },
    addChamp() {
      this.typesDeChamp.push({
        type_champ: 'text',
        types_de_champ: []
      });
    },
    update() {
      this.hasChanges = true;
      if (this.isValid) {
        if (this.state.inFlight === 0) {
          this.state.flash.clear();
        }
        this.debouncedSave();
      }
    },
    upload(evt) {
      if (this.isUploading) {
        this.debouncedUpload();
      } else {
        const input = evt.target;
        const file = input.files[0];
        if (file) {
          this.isUploading = true;
          const controller = new Uploader(
            input,
            file,
            this.state.directUploadUrl
          );
          controller.start().then(signed_id => {
            this.pieceJustificativeTemplate = signed_id;
            this.isUploading = false;
            this.debouncedSave();
          });
        }
        input.value = null;
      }
    },
    save() {
      if (this.isSaving) {
        this.debouncedSave();
      } else {
        this.isSaving = true;
        this.state.inFlight++;
        getJSON(this.saveUrl, this.savePayload, this.saveMethod)
          .then(data => {
            this.onSuccess(data);
          })
          .catch(xhr => {
            this.onError(xhr);
          });
      }
    },
    onSuccess(data) {
      if (data && data.type_de_champ) {
        this.id = data.type_de_champ.id;
        this.pieceJustificativeTemplateUrl =
          data.type_de_champ.piece_justificative_template_url;
        this.pieceJustificativeTemplateFilename =
          data.type_de_champ.piece_justificative_template_filename;
        this.pieceJustificativeTemplate = null;
      }
      this.state.inFlight--;
      this.isSaving = false;
      this.hasChanges = false;

      if (this.state.inFlight === 0) {
        this.state.flash.success();
      }
    },
    onError(xhr) {
      this.isSaving = false;
      this.state.inFlight--;
      try {
        const {
          errors: [message]
        } = JSON.parse(xhr.responseText);
        this.state.flash.error(message);
      } catch (e) {
        this.state.flash.error(xhr.responseText);
      }
    }
  }
};

const EXCLUDE_FROM_REPETITION = [
  'carte',
  'dossier_link',
  'repetition',
  'siret'
];

function castBoolean(value) {
  return value && value != 0;
}
