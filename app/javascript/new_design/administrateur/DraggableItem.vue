<template>
  <div class="deleted" v-if="deleted">
    <input type="hidden" :name="nameFor('id')" :value="id">
    <input type="hidden" :name="nameFor('_destroy')" value="true">
  </div>

  <div class="draggable-item flex column justify-start" v-else :class="itemClassName">
    <div class="flex justify-start section head" :class="{ hr: !isHeaderSection }">
      <div class="handle">
        <img :src="state.dragIconUrl" alt="">
      </div>
      <div class="cell">
        <select
          :id="elementIdFor('type_champ')"
          :name="nameFor('type_champ')"
          v-model="typeChamp"
          @change="update"
          class="small-margin small inline">
            <option v-for="option in state.typesDeChampOptions" :key="option[1]" :value="option[1]">
              {{ option[0] }}
            </option>
        </select>
      </div>
      <div class="flex justify-start delete">
        <button class="button danger" @click.prevent="removeChamp">
          Supprimer
        </button>
      </div>
    </div>
    <div class="flex justify-start section" :class="{ hr: isDropDown || isFile || isCarte }">
      <div class="flex column justify-start shift-left">
        <div class="cell libelle">
          <label :for="elementIdFor('libelle')">
            Libellé
          </label>
          <input
            type="text"
            :id="elementIdFor('libelle')"
            :name="nameFor('libelle')"
            v-model="libelle"
            @change="update"
            class="small-margin small"
            :class="{ error: hasChanges && !isValid }">
        </div>

        <div class="cell" v-show="!isHeaderSection && !isExplication && !state.isAnnotation">
          <label :for="elementIdFor('mandatory')">
            Obligatoire
          </label>
          <input :name="nameFor('mandatory')" type="hidden" value="0">
          <input
            type="checkbox"
            :id="elementIdFor('mandatory')"
            :name="nameFor('mandatory')"
            v-model="mandatory"
            @change="update"
            class="small-margin small"
            value="1">
        </div>
      </div>
      <div class="flex justify-start">
        <div class="cell" v-show="!isHeaderSection">
          <label :for="elementIdFor('description')">
            Description
          </label>
          <textarea
            :id="elementIdFor('description')"
            :name="nameFor('description')"
            v-model="description"
            @change="update"
            rows=3
            cols=40
            class="small-margin small">
          </textarea>
        </div>
      </div>
    </div>
    <div class="flex justify-start section shift-left" v-show="!isHeaderSection">
      <div class="cell" v-show="isDropDown">
        <label :for="elementIdFor('drop_down_list')">
          Liste déroulante
        </label>
        <textarea
          :id="elementIdFor('drop_down_list')"
          :name="nameFor('drop_down_list_attributes[value]')"
          v-model="dropDownListValue"
          @change="update"
          rows=3
          cols=40
          placeholder="Ecrire une valeur par ligne et --valeur-- pour un séparateur."
          class="small-margin small">
        </textarea>
      </div>
      <div class="cell" v-show="isFile">
        <label :for="elementIdFor('piece_justificative_template')">
          Modèle
        </label>
        <template v-if="pieceJustificativeTemplateUrl">
          <a :href="pieceJustificativeTemplateUrl" rel="noopener" target="_blank">
            {{pieceJustificativeTemplateFilename}}
          </a>
          <br> Modifier :
        </template>
        <input
          type="file"
          :id="elementIdFor('piece_justificative_template')"
          :name="nameFor('piece_justificative_template')"
          @change="upload"
          class="small-margin small">
      </div>
      <div class="cell" v-show="isCarte">
        <label>
          Utilisation de la cartographie
        </label>
        <div class="carte-options">
          <label :for="elementIdFor('quartiers_prioritaires')">
            <input :name="nameFor('quartiers_prioritaires')" type="hidden" value="0">
            <input
              type="checkbox"
              :id="elementIdFor('quartiers_prioritaires')"
              :name="nameFor('quartiers_prioritaires')"
              v-model="options.quartiers_prioritaires"
              @change="update"
              class="small-margin small"
              value="1">
            Quartiers prioritaires
          </label>
          <label :for="elementIdFor('cadastres')">
            <input :name="nameFor('cadastres')" type="hidden" value="0">
            <input
              type="checkbox"
              :id="elementIdFor('cadastres')"
              :name="nameFor('cadastres')"
              v-model="options.cadastres"
              @change="update"
              class="small-margin small"
              value="1">
            Cadastres
          </label>
          <label :for="elementIdFor('parcelles_agricoles')">
            <input :name="nameFor('parcelles_agricoles')" type="hidden" value="0">
            <input
              type="checkbox"
              :id="elementIdFor('parcelles_agricoles')"
              :name="nameFor('parcelles_agricoles')"
              v-model="options.parcelles_agricoles"
              @change="update"
              class="small-margin small"
              value="1">
            Parcelles Agricoles
          </label>
        </div>
      </div>
      <div class="flex-grow cell" v-show="isRepetition">
        <Draggable :list="typesDeChamp" :options="{handle:'.handle'}">
          <DraggableItem
            v-for="(item, index) in typesDeChamp"
            :state="stateForRepetition"
            :index="index"
            :item="item"
            :key="item.id" />
        </Draggable>

        <button class="button" @click.prevent="addChamp">
          <template v-if="state.isAnnotation">
            Ajouter une annotation
          </template>
          <template v-else>
            Ajouter un champ
          </template>
        </button>
      </div>
    </div>
    <div class="meta">
      <input type="hidden" :name="nameFor('order_place')" :value="index">
      <input type="hidden" :name="nameFor('id')" :value="id">
    </div>
  </div>
</template>

<script src="./DraggableItem.js"></script>
