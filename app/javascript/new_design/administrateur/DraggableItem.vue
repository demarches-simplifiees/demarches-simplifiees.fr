<template>
  <div class="deleted" v-if="deleted">
    <input type="hidden" :name="nameFor('id')" :value="item.id">
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
          @change="updateOnChange()"
          class="small-margin small inline">
            <option v-for="option in state.typesDeChampOptions" :key="option[1]" :value="option[1]">
              {{ option[0] }}
            </option>
        </select>
      </div>
      <div class="flex justify-start delete">
        <div v-if="isDirty" class="error-message">
          <span v-if="isInvalid" class="content">
            Le libellé doit être rempli.
          </span>
          <span v-else class="content">
            <template v-if="state.isAnnotation">
              Modifications non sauvegardées. Le libellé doit être rempli sur tous les annotations.
            </template>
            <template v-else>
              Modifications non sauvegardées. Le libellé doit être rempli sur tous les champs.
            </template>
          </span>
        </div>

        <button class="button danger" @click.prevent="removeChamp(item)">
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
            @change="updateOnChange()"
            class="small-margin small"
            :class="{ error: isDirty && isInvalid }">
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
            @change="updateOnChange()"
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
            @change="updateOnChange()"
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
          v-model="dropDownList"
          @change="updateOnChange()"
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
        <template v-if="item.piece_justificative_template_url">
          <a :href="item.piece_justificative_template_url" target="_blank">
            {{item.piece_justificative_template_filename}}
          </a>
          <br> Modifier :
        </template>
        <input
          type="file"
          :id="elementIdFor('piece_justificative_template')"
          :name="nameFor('piece_justificative_template')"
          :data-direct-upload-url="state.directUploadsUrl"
          @change="updateOnChange()"
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
              @change="updateOnChange()"
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
              @change="updateOnChange()"
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
              @change="updateOnChange()"
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
            :update="update"
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
      <input type="hidden" :name="nameFor('id')" :value="item.id">
    </div>
  </div>
</template>

<script src="./DraggableItem.js"></script>
