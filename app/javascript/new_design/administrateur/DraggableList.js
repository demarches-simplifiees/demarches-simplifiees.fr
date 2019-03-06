export default {
  props: ['state', 'version'],
  methods: {
    addChamp() {
      this.state.typesDeChamp.push({
        type_champ: 'text',
        types_de_champ: []
      });
    },
    save() {
      this.state.flash.success();
    }
  }
};
