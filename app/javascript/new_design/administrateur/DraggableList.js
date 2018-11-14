export default {
  props: ['state', 'version', 'update', 'updateAll'],
  methods: {
    addChamp() {
      this.state.typesDeChamp.push({
        type_champ: 'text',
        drop_down_list: {},
        options: {}
      });
    }
  }
};
