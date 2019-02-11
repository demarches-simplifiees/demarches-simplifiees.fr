<template>
  <div class="champs-editor">
    <div v-if="state.typesDeChamp.length > 3" class="header">
      <button class="button" @click.prevent="addChamp">
        <template v-if="state.isAnnotation">
          Ajouter une annotation
        </template>
        <template v-else>
          Ajouter un champ
        </template>
      </button>

      <button class="button primary" @click.prevent="save">Enregistrer</button>
    </div>

    <Draggable :list="state.typesDeChamp" :options="{handle:'.handle'}">
      <DraggableItem
        v-for="(item, index) in state.typesDeChamp"
        :state="state"
        :index="index"
        :item="item"
        :key="item.id" />
    </Draggable>

    <div class="footer">
      <button class="button" @click.prevent="addChamp">
        <template v-if="state.isAnnotation">
          Ajouter une annotation
        </template>
        <template v-else>
          Ajouter un champ
        </template>
      </button>

      <button class="button primary" @click.prevent="save">Enregistrer</button>
    </div>
  </div>
</template>

<script src="./DraggableList.js"></script>
