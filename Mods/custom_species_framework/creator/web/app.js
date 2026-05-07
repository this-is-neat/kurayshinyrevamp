const BLANK_IMAGE = "data:image/gif;base64,R0lGODlhAQABAAAAACwAAAAAAQABAAA=";
const EMPTY_ARRAY = Object.freeze([]);

const state = {
  catalog: null,
  species: [],
  fusionBuilder: {
    headId: "",
    bodyId: "",
    preview: null,
    loading: false,
    error: ""
  },
  creatorStarterSet: null,
  deliveryQueue: null,
  importer: null,
  importerLoading: false,
  selectedId: null,
  dexSelectedId: null,
  dexCompareIds: { left: null, right: null },
  dexCatalogScope: "species",
  mode: "pokedex",
  creatorTab: "overview",
  dexTab: "overview",
  integrationTab: "export",
  importerDraft: {
    manifestText: "",
    config: null
  },
  lastSuggestedInternalId: "",
  pendingAssets: {
    front_data_url: null,
    back_data_url: null,
    icon_data_url: null
  },
  preview: {
    face: "front",
    shiny: false
  },
  history: [],
  future: [],
  historyTimer: null,
  autosaveTimer: null,
  dexRenderTimer: null,
  suspendHistory: false,
  assetNonce: Date.now(),
  assetDataCache: new Map(),
  pendingAssetData: new Map(),
  pendingCatalogDetails: new Map(),
  catalogDetailErrors: new Map(),
  syntheticDexEntries: new Map(),
  visualVariantCache: new Map(),
  pendingVisualVariantRequests: new Map(),
  fusionSliceCache: new Map(),
  pendingFusionSliceRequests: new Map(),
  lastExport: null,
  autosaveKey: "csf-studio-autosave-v3",
  dexCache: {
    catalogSpeciesSource: null,
    creatorSpeciesSource: null,
    mergedEntries: EMPTY_ARRAY,
    fusionEntriesSource: null,
    fusionEntriesSignature: "",
    fusionEntries: EMPTY_ARRAY,
    filteredSource: null,
    filteredQuery: "",
    filteredEntries: EMPTY_ARRAY
  }
};

const fallbackEnums = {
  types: [
    "NORMAL", "FIRE", "WATER", "GRASS", "ELECTRIC", "ICE", "FIGHTING", "POISON", "GROUND",
    "FLYING", "PSYCHIC", "BUG", "ROCK", "GHOST", "DRAGON", "DARK", "STEEL", "FAIRY"
  ].map((id) => ({ id, name: titleizeToken(id) })),
  growth_rates: ["Medium", "Fast", "Slow", "Parabolic", "Erratic", "Fluctuating"].map((id) => ({ id, name: titleizeToken(id) })),
  gender_ratios: [
    "AlwaysMale", "AlwaysFemale", "Genderless", "FemaleOneEighth",
    "Female25Percent", "Female50Percent", "Female75Percent", "FemaleSevenEighths"
  ].map((id) => ({ id, name: titleizeToken(id) })),
  egg_groups: [
    "Undiscovered", "Monster", "Water1", "Bug", "Flying", "Field", "Fairy",
    "Grass", "Humanlike", "Water3", "Mineral", "Amorphous", "Water2", "Ditto", "Dragon"
  ].map((id) => ({ id, name: titleizeToken(id) })),
  body_colors: ["Red", "Blue", "Yellow", "Green", "Black", "Brown", "Purple", "Gray", "White", "Pink"].map((id) => ({ id, name: titleizeToken(id) })),
  body_shapes: [
    "Head", "Serpentine", "Finned", "HeadArms", "HeadBase", "BipedalTail", "HeadLegs",
    "Quadruped", "Winged", "Multiped", "MultiBody", "Bipedal", "MultiWinged", "Insectoid"
  ].map((id) => ({ id, name: titleizeToken(id) })),
  habitats: ["None", "Grassland", "Forest", "WatersEdge", "Sea", "Cave", "Mountain", "RoughTerrain", "Urban", "Rare"].map((id) => ({ id, name: titleizeToken(id) })),
  evolution_methods: [
    { id: "Level", parameter_kind: "Integer" },
    { id: "LevelMale", parameter_kind: "Integer" },
    { id: "LevelFemale", parameter_kind: "Integer" },
    { id: "LevelDay", parameter_kind: "Integer" },
    { id: "LevelNight", parameter_kind: "Integer" },
    { id: "Happiness", parameter_kind: null },
    { id: "HappinessDay", parameter_kind: null },
    { id: "HappinessNight", parameter_kind: null },
    { id: "HappinessMove", parameter_kind: "Move" },
    { id: "HappinessMoveType", parameter_kind: "Type" },
    { id: "HasMove", parameter_kind: "Move" },
    { id: "HasMoveType", parameter_kind: "Type" },
    { id: "HasInParty", parameter_kind: "Species" },
    { id: "Location", parameter_kind: "Integer" },
    { id: "Region", parameter_kind: "Integer" },
    { id: "Item", parameter_kind: "Item" },
    { id: "Trade", parameter_kind: null },
    { id: "TradeItem", parameter_kind: "Item" },
    { id: "TradeSpecies", parameter_kind: "Species" }
  ].map((entry) => ({ ...entry, name: titleizeToken(entry.id) }))
};

const TYPE_COLORS = {
  NORMAL: "#919aa2",
  FIRE: "#ef7f4e",
  WATER: "#5a9be8",
  GRASS: "#5eaf53",
  ELECTRIC: "#f3c441",
  ICE: "#79d4d4",
  FIGHTING: "#cf6f47",
  POISON: "#a66ac8",
  GROUND: "#c7a15e",
  FLYING: "#83a9ff",
  PSYCHIC: "#ef6b9a",
  BUG: "#97b73a",
  ROCK: "#b39b5d",
  GHOST: "#7466c1",
  DRAGON: "#6074e7",
  DARK: "#5c596a",
  STEEL: "#6da0b0",
  FAIRY: "#ec8fd3"
};

const TYPE_EFFECTIVENESS = {
  NORMAL: { strong: [], weak: ["ROCK", "STEEL"], immune: ["GHOST"] },
  FIRE: { strong: ["GRASS", "ICE", "BUG", "STEEL"], weak: ["FIRE", "WATER", "ROCK", "DRAGON"], immune: [] },
  WATER: { strong: ["FIRE", "GROUND", "ROCK"], weak: ["WATER", "GRASS", "DRAGON"], immune: [] },
  GRASS: { strong: ["WATER", "GROUND", "ROCK"], weak: ["FIRE", "GRASS", "POISON", "FLYING", "BUG", "DRAGON", "STEEL"], immune: [] },
  ELECTRIC: { strong: ["WATER", "FLYING"], weak: ["ELECTRIC", "GRASS", "DRAGON"], immune: ["GROUND"] },
  ICE: { strong: ["GRASS", "GROUND", "FLYING", "DRAGON"], weak: ["FIRE", "WATER", "ICE", "STEEL"], immune: [] },
  FIGHTING: { strong: ["NORMAL", "ICE", "ROCK", "DARK", "STEEL"], weak: ["POISON", "FLYING", "PSYCHIC", "BUG", "FAIRY"], immune: ["GHOST"] },
  POISON: { strong: ["GRASS", "FAIRY"], weak: ["POISON", "GROUND", "ROCK", "GHOST"], immune: ["STEEL"] },
  GROUND: { strong: ["FIRE", "ELECTRIC", "POISON", "ROCK", "STEEL"], weak: ["GRASS", "BUG"], immune: ["FLYING"] },
  FLYING: { strong: ["GRASS", "FIGHTING", "BUG"], weak: ["ELECTRIC", "ROCK", "STEEL"], immune: [] },
  PSYCHIC: { strong: ["FIGHTING", "POISON"], weak: ["PSYCHIC", "STEEL"], immune: ["DARK"] },
  BUG: { strong: ["GRASS", "PSYCHIC", "DARK"], weak: ["FIRE", "FIGHTING", "POISON", "FLYING", "GHOST", "STEEL", "FAIRY"], immune: [] },
  ROCK: { strong: ["FIRE", "ICE", "FLYING", "BUG"], weak: ["FIGHTING", "GROUND", "STEEL"], immune: [] },
  GHOST: { strong: ["PSYCHIC", "GHOST"], weak: ["DARK"], immune: ["NORMAL"] },
  DRAGON: { strong: ["DRAGON"], weak: ["STEEL"], immune: ["FAIRY"] },
  DARK: { strong: ["PSYCHIC", "GHOST"], weak: ["FIGHTING", "DARK", "FAIRY"], immune: [] },
  STEEL: { strong: ["ICE", "ROCK", "FAIRY"], weak: ["FIRE", "WATER", "ELECTRIC", "STEEL"], immune: [] },
  FAIRY: { strong: ["FIGHTING", "DRAGON", "DARK"], weak: ["FIRE", "POISON", "STEEL"], immune: [] }
};

const CREATOR_TEMPLATES = {
  starter_grass: {
    name: "",
    category: "Sprout Cub",
    type1: "GRASS",
    starter_eligible: true,
    fusion_rule: "blocked",
    growth_rate: "Parabolic",
    egg_groups: ["Field", "Grass"],
    abilities: ["OVERGROW"],
    hidden_abilities: ["CHLOROPHYLL"],
    base_stats: { HP: 52, ATTACK: 52, DEFENSE: 50, SPECIAL_ATTACK: 60, SPECIAL_DEFENSE: 58, SPEED: 48 },
    moves: [{ level: 1, move: "TACKLE" }, { level: 5, move: "ABSORB" }],
    pokedex_entry: "A calm young starter that stores fresh energy in the leaves growing along its back."
  },
  starter_fire: {
    name: "",
    category: "Ember Cub",
    type1: "FIRE",
    starter_eligible: true,
    fusion_rule: "blocked",
    growth_rate: "Parabolic",
    egg_groups: ["Field"],
    abilities: ["BLAZE"],
    hidden_abilities: ["FLASHFIRE"],
    base_stats: { HP: 48, ATTACK: 56, DEFENSE: 44, SPECIAL_ATTACK: 62, SPECIAL_DEFENSE: 50, SPEED: 58 },
    moves: [{ level: 1, move: "SCRATCH" }, { level: 5, move: "EMBER" }],
    pokedex_entry: "Its mane flickers brighter whenever it senses a worthy challenge nearby."
  },
  starter_water: {
    name: "",
    category: "Current Pup",
    type1: "WATER",
    starter_eligible: true,
    fusion_rule: "blocked",
    growth_rate: "Parabolic",
    egg_groups: ["Water1", "Field"],
    abilities: ["TORRENT"],
    hidden_abilities: ["WATERVEIL"],
    base_stats: { HP: 54, ATTACK: 50, DEFENSE: 56, SPECIAL_ATTACK: 58, SPECIAL_DEFENSE: 60, SPEED: 42 },
    moves: [{ level: 1, move: "TACKLE" }, { level: 5, move: "WATERGUN" }],
    pokedex_entry: "It gathers dew in the crest on its head and uses it to keep calm under pressure."
  },
  early_bug: {
    category: "Threadling",
    type1: "BUG",
    type2: "NORMAL",
    abilities: ["SHEDSKIN"],
    hidden_abilities: ["RUNAWAY"],
    egg_groups: ["Bug"],
    base_stats: { HP: 40, ATTACK: 35, DEFENSE: 42, SPECIAL_ATTACK: 30, SPECIAL_DEFENSE: 32, SPEED: 55 },
    moves: [{ level: 1, move: "TACKLE" }, { level: 7, move: "BUGBITE" }],
    pokedex_entry: "A skittish route bug that spins silk around tree roots and old signposts."
  },
  regional_bird: {
    category: "Sky Finch",
    type1: "NORMAL",
    type2: "FLYING",
    abilities: ["KEENEYE"],
    hidden_abilities: ["BIGPECKS"],
    egg_groups: ["Flying"],
    base_stats: { HP: 48, ATTACK: 54, DEFENSE: 42, SPECIAL_ATTACK: 34, SPECIAL_DEFENSE: 36, SPEED: 60 },
    moves: [{ level: 1, move: "PECK" }, { level: 5, move: "GROWL" }],
    pokedex_entry: "It rides thermal currents for hours at a time and only lands to gather shining twigs."
  },
  pseudo_legendary: {
    category: "Mythic Whelp",
    type1: "DRAGON",
    abilities: ["INNERFOCUS"],
    hidden_abilities: ["MULTISCALE"],
    egg_groups: ["Dragon"],
    base_stats: { HP: 50, ATTACK: 70, DEFENSE: 55, SPECIAL_ATTACK: 55, SPECIAL_DEFENSE: 55, SPEED: 45 },
    moves: [{ level: 1, move: "TWISTER" }, { level: 8, move: "BITE" }],
    pokedex_entry: "It slumbers in old mountain shrines and awakens only when the wind shifts suddenly."
  },
  fossil: {
    category: "Relic Shell",
    type1: "ROCK",
    type2: "WATER",
    abilities: ["SWIFTSWIM"],
    hidden_abilities: ["BATTLEARMOR"],
    egg_groups: ["Water1", "Water3"],
    base_stats: { HP: 44, ATTACK: 58, DEFENSE: 68, SPECIAL_ATTACK: 44, SPECIAL_DEFENSE: 52, SPEED: 34 },
    moves: [{ level: 1, move: "TACKLE" }, { level: 6, move: "WITHDRAW" }],
    pokedex_entry: "Its shell bears marks from an age when the sea reached much farther inland."
  },
  baby: {
    category: "Tiny Friend",
    type1: "NORMAL",
    abilities: ["CUTECHARM"],
    hidden_abilities: ["FRIENDGUARD"],
    egg_groups: ["Undiscovered"],
    base_stats: { HP: 38, ATTACK: 24, DEFENSE: 28, SPECIAL_ATTACK: 30, SPECIAL_DEFENSE: 38, SPEED: 36 },
    moves: [{ level: 1, move: "CHARM" }, { level: 1, move: "POUND" }],
    pokedex_entry: "It follows the sound of familiar footsteps and hides behind scarves when startled."
  },
  single_rare: {
    category: "Mirage Beast",
    type1: "PSYCHIC",
    type2: "FAIRY",
    abilities: ["SYNCHRONIZE"],
    hidden_abilities: ["MAGICBOUNCE"],
    egg_groups: ["Field", "Fairy"],
    base_stats: { HP: 78, ATTACK: 62, DEFENSE: 74, SPECIAL_ATTACK: 96, SPECIAL_DEFENSE: 86, SPEED: 94 },
    moves: [{ level: 1, move: "CONFUSION" }, { level: 10, move: "FAIRYWIND" }],
    pokedex_entry: "Few trainers can tell whether they saw it at all until they find glittering footprints later."
  }
};

function bootCreatorStudio() {
  try {
    bindEvents();
    refreshApp().catch(handleStartupFailure);
  } catch (error) {
    handleStartupFailure(error);
  }
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", bootCreatorStudio, { once: true });
} else {
  bootCreatorStudio();
}

function bindEvents() {
  document.getElementById("newSpeciesBtn").addEventListener("click", () => newSpeciesDraft());
  document.getElementById("saveSpeciesBtn").addEventListener("click", saveSpecies);
  document.getElementById("undoBtn").addEventListener("click", undoDraft);
  document.getElementById("redoBtn").addEventListener("click", redoDraft);
  document.getElementById("duplicateSpeciesBtn").addEventListener("click", duplicateSpecies);
  document.getElementById("deleteSpeciesBtn").addEventListener("click", deleteSpecies);
  document.getElementById("publishHomePcBtn").addEventListener("click", publishSpeciesToHomePc);
  document.getElementById("wizardNextStepBtn").addEventListener("click", openNextWizardStep);
  document.getElementById("wizardPublishShortcutBtn").addEventListener("click", () => {
    setMode("creator");
    setCreatorTab("publish");
    renderWizardProgress();
  });
  document.getElementById("createVariantFromDexBtn").addEventListener("click", cloneSelectedDexSpecies);
  document.getElementById("setFusionHeadBtn").addEventListener("click", () => assignSelectedDexSpeciesToFusionSlot("head"));
  document.getElementById("setFusionBodyBtn").addEventListener("click", () => assignSelectedDexSpeciesToFusionSlot("body"));
  document.getElementById("swapFusionPartsBtn").addEventListener("click", swapDexFusionBuilder);
  document.getElementById("clearFusionBuilderBtn").addEventListener("click", clearDexFusionBuilder);
  document.getElementById("createFusionVariantBtn").addEventListener("click", cloneFusionBuilderSpecies);
  document.getElementById("cloneToCreatorBtn").addEventListener("click", cloneSelectedDexSpeciesAsFakemon);
  document.getElementById("setCompareLeftBtn").addEventListener("click", () => setCompareSlot("left"));
  document.getElementById("setCompareRightBtn").addEventListener("click", () => setCompareSlot("right"));
  document.getElementById("clearCompareBtn").addEventListener("click", clearComparison);
  document.getElementById("clearDexFiltersBtn").addEventListener("click", clearDexFilters);
  document.getElementById("refreshDraftVariantChoicesBtn").addEventListener("click", () => {
    renderDraftVisualVariantPanel({ refresh: true });
  });
  document.getElementById("saveStarterBtn").addEventListener("click", saveStarterTrio);
  document.getElementById("refreshDeliveryQueueBtn").addEventListener("click", () => refreshDeliveryQueueState());
  document.getElementById("exportSpeciesBtn").addEventListener("click", exportSpeciesPack);
  document.getElementById("loadImportExampleBtn").addEventListener("click", loadImportExampleManifest);
  document.getElementById("saveImportWorkspaceBtn").addEventListener("click", saveImporterWorkspace);
  document.getElementById("runImportDryRunBtn").addEventListener("click", runImporterDryRun);
  document.getElementById("applyImportBundleBtn").addEventListener("click", applyImporterBundle);
  document.getElementById("addMoveBtn").addEventListener("click", () => addLevelMoveRow());
  document.getElementById("addTmMoveBtn").addEventListener("click", () => addSimpleMoveRow("tmMovesList"));
  document.getElementById("addTutorMoveBtn").addEventListener("click", () => addSimpleMoveRow("tutorMovesList"));
  document.getElementById("addEggMoveBtn").addEventListener("click", () => addSimpleMoveRow("eggMovesList"));
  document.getElementById("addEvolutionBtn").addEventListener("click", () => addEvolutionRow());

  document.querySelectorAll(".nav-button").forEach((button) => {
    button.addEventListener("click", () => setMode(button.dataset.mode));
  });
  document.querySelectorAll("[data-creator-tab]").forEach((button) => {
    if (button.classList.contains("tab-button")) {
      button.addEventListener("click", () => setCreatorTab(button.dataset.creatorTab));
    }
  });
  document.querySelectorAll("[data-dex-tab]").forEach((button) => {
    if (button.classList.contains("tab-button")) {
      button.addEventListener("click", () => setDexTab(button.dataset.dexTab));
    }
  });
  document.querySelectorAll("[data-integration-tab]").forEach((button) => {
    if (button.classList.contains("tab-button")) {
      button.addEventListener("click", () => setIntegrationTab(button.dataset.integrationTab));
    }
  });
  document.querySelectorAll("[data-preview-face]").forEach((button) => {
    button.addEventListener("click", () => setPreviewFace(button.dataset.previewFace));
  });
  document.getElementById("previewShinyBtn").addEventListener("click", togglePreviewShiny);
  document.querySelectorAll(".template-card").forEach((button) => {
    button.addEventListener("click", () => applyTemplate(button.dataset.template));
  });

  ["frontAsset", "backAsset", "iconAsset"].forEach((inputId) => {
    document.getElementById(inputId).addEventListener("change", handleAssetSelection);
  });
  document.getElementById("draftVisualVariantGallery").addEventListener("click", handleDraftVariantGalleryClick);

  ["movesList", "tmMovesList", "tutorMovesList", "eggMovesList", "evolutionsList"].forEach((listId) => {
    document.getElementById(listId).addEventListener("click", (event) => {
      if (event.target.classList.contains("remove-row")) {
        event.target.closest(".repeater-row").remove();
        handleFormMutation();
      }
    });
  });

  ["starterSpecies1", "starterSpecies2", "starterSpecies3"].forEach((selectId) => {
    document.getElementById(selectId).addEventListener("change", refreshStarterCounterOptions);
  });

  [
    "deliveryLabel",
    "deliveryLevel",
    "deliveryQuantity",
    "deliveryNickname",
    "deliveryHeldItem",
    "deliveryMessage",
    "deliveryNotes",
    "deliveryShiny"
  ].forEach((elementId) => {
    const element = document.getElementById(elementId);
    if (!element) {
      return;
    }
    element.addEventListener("input", handleFormMutation);
    element.addEventListener("change", handleFormMutation);
  });

  document.getElementById("importManifestEditor").addEventListener("input", (event) => {
    state.importerDraft.manifestText = event.target.value;
  });
  [
    ["importStrictPermission", "strict_permission_mode"],
    ["importAllowPartial", "allow_partial_entries"],
    ["importRequireBack", "require_backsprite"],
    ["importRequireIcon", "require_icon"],
    ["importOverwriteExisting", "overwrite_existing_species"]
  ].forEach(([elementId, configKey]) => {
    document.getElementById(elementId).addEventListener("change", (event) => {
      const config = ensureImporterDraftConfig();
      config[configKey] = Boolean(event.target.checked);
    });
  });

  ["dexSearch", "dexAbilityFilter"].forEach((id) => {
    document.getElementById(id).addEventListener("input", scheduleDexSpeciesListRender);
  });
  document.getElementById("dexCatalogScope").addEventListener("change", (event) => {
    setDexCatalogScope(event.target.value);
  });
  ["dexTypeFilter", "dexKindFilter", "dexSort"].forEach((id) => {
    document.getElementById(id).addEventListener("change", scheduleDexSpeciesListRender);
  });
  ["dexFusionHead", "dexFusionBody"].forEach((id) => {
    const element = document.getElementById(id);
    if (!element) {
      return;
    }
    element.addEventListener("input", handleDexFusionBuilderInput);
    element.addEventListener("change", handleDexFusionBuilderInput);
  });

  document.getElementById("kind").addEventListener("change", () => {
    updateKindUi();
    handleFormMutation();
  });
  const variantSourceMode = document.getElementById("variantSourceMode");
  if (variantSourceMode) {
    variantSourceMode.addEventListener("change", () => {
      updateKindUi();
      handleFormMutation();
    });
  }
  ["variantFusionHead", "variantFusionBody"].forEach((id) => {
    const element = document.getElementById(id);
    if (!element) {
      return;
    }
    element.addEventListener("input", () => {
      syncRegionalFusionFields();
      handleFormMutation();
    });
    element.addEventListener("change", () => {
      syncRegionalFusionFields();
      handleFormMutation();
    });
  });
  document.getElementById("name").addEventListener("input", () => {
    maybeSuggestInternalId();
    handleFormMutation();
  });
  document.getElementById("internalId").addEventListener("blur", () => {
    normalizeInternalIdField();
    handleFormMutation();
  });
  document.querySelectorAll(".stat-input").forEach((input) => {
    input.addEventListener("input", updateBst);
  });

  const speciesForm = document.getElementById("speciesForm");
  speciesForm.addEventListener("input", (event) => {
    if (["frontAsset", "backAsset", "iconAsset"].includes(event.target.id)) {
      return;
    }
    handleFormMutation();
  });
  speciesForm.addEventListener("change", (event) => {
    if (["frontAsset", "backAsset", "iconAsset"].includes(event.target.id)) {
      return;
    }
    handleFormMutation();
  });

  document.addEventListener("keydown", (event) => {
    const ctrlOrMeta = event.ctrlKey || event.metaKey;
    if (!ctrlOrMeta) {
      return;
    }
    const key = event.key.toLowerCase();
    if (key === "z" && !event.shiftKey) {
      event.preventDefault();
      undoDraft();
    } else if ((key === "z" && event.shiftKey) || key === "y") {
      event.preventDefault();
      redoDraft();
    }
  });
}

async function refreshApp() {
  const stateResult = await fetchJson("/api/state", { timeoutMs: 10000 });
  state.catalog = null;
  state.catalogInfo = stateResult.data?.catalog || null;
  state.species = stateResult.data?.species || [];
  state.creatorStarterSet = stateResult.data?.creator_starter_set || null;
  state.deliveryQueue = stateResult.data?.delivery_queue || null;
  state.lastExport = null;

  updateCatalogStatus({
    loading: Boolean(state.catalogInfo?.available),
    data: state.catalogInfo || {}
  });
  populateCatalogDrivenControls();

  if (state.catalogInfo?.available) {
    const summaryResult = await fetchCatalogPayload().catch((error) => ({
      ok: false,
      data: { error: error.message }
    }));
    if (summaryResult?.ok) {
      state.catalog = summaryResult.data;
    } else {
      state.catalog = null;
      state.catalogInfo = {
        ...(state.catalogInfo || {}),
        error: summaryResult?.data?.error || "The local catalog summary could not be loaded."
      };
    }
  }

  updateCatalogStatus({
    ok: Boolean(state.catalog?.species?.length),
    data: state.catalogInfo || state.catalog || {}
  });
  populateCatalogDrivenControls();

  const mergedSpecies = mergedDexEntries();
  if (!state.dexSelectedId && mergedSpecies.length > 0) {
    state.dexSelectedId = mergedSpecies[0].id;
  }

  const restored = restoreAutosaveIfAvailable();
  if (!restored) {
    if (state.selectedId) {
      const selected = state.species.find((entry) => entry.id === state.selectedId);
      if (selected) {
        loadSpeciesIntoForm(selected);
      } else if (state.species.length > 0) {
        loadSpeciesIntoForm(state.species[0]);
      } else {
        newSpeciesDraft();
      }
    } else if (state.species.length > 0) {
      loadSpeciesIntoForm(state.species[0]);
    } else {
      newSpeciesDraft();
    }
  }

  renderStarterEditor();
  renderDexSpeciesList();
  refreshWorkspace();
}

function handleStartupFailure(error) {
  const message = error?.message || "The creator couldn't reach the local creator server.";
  const pill = document.getElementById("catalogStatus");
  if (pill) {
    pill.textContent = "Catalog Error";
    pill.className = "status-pill";
  }
  showMessage(`${message} Restart the creator server to retry the local catalog scan.`, "error");
  if (!state.draft) {
    newSpeciesDraft();
  }
}

async function loadCatalogInBackground() {
  const entry = selectedDexEntry();
  if (entry?.id) {
    await ensureDexSpeciesDetail(entry.id, { silent: true });
  }
  return {
    ok: Boolean(state.catalog?.species?.length),
    data: state.catalog || state.catalogInfo || {}
  };
}

async function fetchJson(url, options = {}) {
  const controller = new AbortController();
  const timeoutMs = Number(options.timeoutMs || 0);
  let timeoutHandle = null;
  if (timeoutMs > 0) {
    timeoutHandle = window.setTimeout(() => controller.abort(), timeoutMs);
  }
  try {
    const response = await fetch(url, {
      ...(options.fetchOptions || {}),
      signal: controller.signal
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok && !options.allowError) {
      throw new Error(data.error || `Request failed: ${response.status}`);
    }
    return {
      ok: response.ok,
      status: response.status,
      data
    };
  } catch (error) {
    if (error?.name === "AbortError") {
      throw new Error(options.timeoutMessage || "The creator server took too long to respond.");
    }
    throw error;
  } finally {
    if (timeoutHandle) {
      window.clearTimeout(timeoutHandle);
    }
  }
}

async function fetchCatalogPayload() {
  const controller = new AbortController();
  const timeoutHandle = window.setTimeout(() => controller.abort(), 20000);
  try {
    const response = await fetch("/api/catalog-summary", { cache: "no-store", signal: controller.signal });
    const raw = await response.text();
    let data = {};
    try {
      data = JSON.parse(raw);
    } catch (error) {
      throw new Error("The creator catalog response could not be parsed.");
    }

    const normalized = normalizeCatalogPayload(data);
    return {
      ok: response.ok && Array.isArray(normalized?.species) && normalized.species.length > 0,
      status: response.status,
      data: normalized || {}
    };
  } catch (error) {
    if (error?.name === "AbortError") {
      throw new Error("The creator catalog summary took too long to load.");
    }
    throw error;
  } finally {
    window.clearTimeout(timeoutHandle);
  }
}

function normalizeCatalogPayload(data) {
  if (!data || typeof data !== "object") {
    return null;
  }
  const species = Array.isArray(data.species)
    ? data.species
    : (data.species && typeof data.species === "object" ? Object.values(data.species) : []);
  return {
    ...data,
    species
  };
}

function updateCatalogStatus(result) {
  const pill = document.getElementById("catalogStatus");
  if (result.loading) {
    const loadingText = result.data?.generated_at ? `Loading Catalog - ${result.data.generated_at}` : "Loading Game Catalog";
    pill.textContent = loadingText;
    pill.className = "status-pill";
    showMessage("Loading the installed game's Pokédex catalog in the background.", "info");
    return;
  }
  if (result.ok) {
    const generatedAt = result.data.generated_at ? `Catalog Ready · ${result.data.generated_at}` : "Catalog Ready";
    pill.textContent = generatedAt;
    pill.className = "status-pill";
    showMessage("The studio is reading the installed game's current species, move, ability, and item data.", "success");
    return;
  }
  pill.textContent = "Catalog Missing";
  pill.className = "status-pill";
  showMessage(result.data.error || "The creator couldn't load its local Pokédex catalog views.", "error");
}

function showMessage(message, type = "info") {
  const banner = document.getElementById("messageBanner");
  if (!message) {
    banner.className = "message-banner hidden";
    banner.textContent = "";
    return;
  }
  banner.textContent = message;
  banner.className = `message-banner ${type}`;
}

function catalogEntries(key) {
  if (state.catalog && Array.isArray(state.catalog[key]) && state.catalog[key].length > 0) {
    return state.catalog[key];
  }
  return fallbackEnums[key] || [];
}

function populateCatalogDrivenControls() {
  populateSelect(document.getElementById("type1"), catalogEntries("types"), { allowBlank: false });
  populateSelect(document.getElementById("type2"), catalogEntries("types"), { allowBlank: true, blankLabel: "None" });
  populateSelect(document.getElementById("growthRate"), catalogEntries("growth_rates"), { allowBlank: false });
  populateSelect(document.getElementById("genderRatio"), catalogEntries("gender_ratios"), { allowBlank: false });
  populateSelect(document.getElementById("eggGroup1"), catalogEntries("egg_groups"), { allowBlank: false });
  populateSelect(document.getElementById("eggGroup2"), catalogEntries("egg_groups"), { allowBlank: true, blankLabel: "None" });
  populateSelect(document.getElementById("color"), catalogEntries("body_colors"), { allowBlank: false });
  populateSelect(document.getElementById("shape"), catalogEntries("body_shapes"), { allowBlank: false });
  populateSelect(document.getElementById("habitat"), catalogEntries("habitats"), { allowBlank: false });
  populateSelect(document.getElementById("dexTypeFilter"), catalogEntries("types"), { allowBlank: true, blankLabel: "All Types" });

  populateDatalist("move-options", catalogEntries("moves"), (entry) => `${entry.id} · ${entry.name}`);
  populateDatalist("ability-options", catalogEntries("abilities"), (entry) => `${entry.id} · ${entry.name}`);
  populateDatalist("species-options", allSpeciesOptions(), (entry) => `${entry.id} · ${entry.name}`);
  populateDatalist("type-options", catalogEntries("types"), (entry) => `${entry.id} · ${entry.name}`);
  populateDatalist("item-options", catalogEntries("items"), (entry) => `${entry.id} · ${entry.name}`);
}

function populateSelect(select, entries, config = {}) {
  const currentValue = select.value;
  select.innerHTML = "";
  if (config.allowBlank) {
    const option = document.createElement("option");
    option.value = "";
    option.textContent = config.blankLabel || "None";
    select.appendChild(option);
  }
  entries.forEach((entry) => {
    const option = document.createElement("option");
    option.value = entry.id;
    option.textContent = entry.name || entry.id;
    select.appendChild(option);
  });
  if (currentValue && [...select.options].some((option) => option.value === currentValue)) {
    select.value = currentValue;
  }
}

function populateDatalist(id, entries, labelBuilder) {
  const datalist = document.getElementById(id);
  datalist.innerHTML = "";
  entries.forEach((entry) => {
    const option = document.createElement("option");
    option.value = entry.id;
    option.label = labelBuilder(entry);
    datalist.appendChild(option);
  });
}

function mergedDexEntries() {
  const catalogSpeciesSource = state.catalog?.species || EMPTY_ARRAY;
  const creatorSpeciesSource = state.species || EMPTY_ARRAY;
  if (
    state.dexCache.catalogSpeciesSource === catalogSpeciesSource &&
    state.dexCache.creatorSpeciesSource === creatorSpeciesSource &&
    state.dexCache.mergedEntries !== EMPTY_ARRAY
  ) {
    return state.dexCache.mergedEntries;
  }

  const merged = new Map();
  catalogSpeciesSource.map(normalizeCatalogSpeciesEntry).forEach((entry) => merged.set(entry.id, entry));
  creatorSpeciesSource.map(normalizeCreatorSpeciesEntry).forEach((entry) => merged.set(entry.id, entry));

  state.dexCache.catalogSpeciesSource = catalogSpeciesSource;
  state.dexCache.creatorSpeciesSource = creatorSpeciesSource;
  state.dexCache.mergedEntries = [...merged.values()];
  state.dexCache.filteredSource = null;
  state.dexCache.filteredQuery = "";
  state.dexCache.filteredEntries = EMPTY_ARRAY;
  return state.dexCache.mergedEntries;
}

function allSpeciesOptions() {
  return mergedDexEntries()
    .map((entry) => ({ id: entry.id, name: entry.name || entry.id, id_number: entry.id_number || 0 }))
    .sort((a, b) => a.name.localeCompare(b.name));
}

function normalizeCatalogSpeciesEntry(entry) {
  const frontVisual = resolveStudioAssetUrl(entry.visuals?.front);
  const backVisual = resolveStudioAssetUrl(entry.visuals?.back || entry.visuals?.front);
  const iconVisual = resolveStudioAssetUrl(entry.visuals?.icon || entry.visuals?.front);
  const shinyFrontVisual = resolveStudioAssetUrl(entry.visuals?.shiny_front);
  const shinyBackVisual = resolveStudioAssetUrl(entry.visuals?.shiny_back);
  const overworldVisual = resolveStudioAssetUrl(entry.visuals?.overworld);
  const fusionSource = normalizeFusionSourceValue(entry.fusion_source || entry.base_species);
  return {
    id: entry.id,
    name: entry.name || entry.id,
    species: entry.species || entry.id,
    id_number: Number(entry.id_number || 0),
    category: entry.category || "Unknown Species",
    pokedex_entry: entry.pokedex_entry || "",
    design_notes: entry.design_notes || "",
    template_source_label: entry.template_source_label || "",
    types: uniqueTypes(entry.types || []),
    base_stats: normalizeStats(entry.base_stats),
    bst: Number(entry.bst || calculateBst(entry.base_stats)),
    base_exp: Number(entry.base_exp || 0),
    growth_rate: normalizeNamedEntry(entry.growth_rate),
    gender_ratio: normalizeNamedEntry(entry.gender_ratio),
    catch_rate: Number(entry.catch_rate || 0),
    happiness: Number(entry.happiness || 0),
    abilities: normalizeNamedList(entry.abilities),
    hidden_abilities: normalizeNamedList(entry.hidden_abilities),
    moves: normalizeMoveList(entry.moves),
    tutor_moves: normalizeMoveList(entry.tutor_moves),
    egg_moves: normalizeMoveList(entry.egg_moves),
    tm_moves: normalizeMoveList(entry.tm_moves),
    egg_groups: normalizeNamedList(entry.egg_groups),
    hatch_steps: Number(entry.hatch_steps || 0),
    evolutions: normalizeEvolutionList(entry.evolutions),
    previous_species: normalizeSpeciesReference(entry.previous_species),
    family_species: normalizeSpeciesReferenceList(entry.family_species),
    height: Number(entry.height || 0),
    weight: Number(entry.weight || 0),
    color: normalizeNamedEntry(entry.color),
    shape: normalizeNamedEntry(entry.shape),
    habitat: normalizeNamedEntry(entry.habitat),
    generation: Number(entry.generation || 0),
    kind: entry.kind || "base_game",
    source: entry.source || "base_game",
    detail_level: entry.detail_level || "full",
    fusion_rule: entry.fusion_rule || "standard",
    fusion_compatible: Boolean(entry.fusion_compatible),
    starter_eligible: Boolean(entry.starter_eligible),
    encounter_eligible: Boolean(entry.encounter_eligible),
    trainer_eligible: Boolean(entry.trainer_eligible),
    regional_variant: Boolean(entry.regional_variant),
    variant_scope: entry.variant_scope || (entry.kind === "regional_variant" ? "single_species" : ""),
    variant_family: entry.variant_family || "",
    base_species: normalizeSpeciesReference(entry.base_species),
    fallback_species: normalizeSpeciesReference(entry.fallback_species),
    fusion_source: fusionSource,
    visuals: normalizeVisuals({
      front: frontVisual,
      back: backVisual,
      icon: iconVisual,
      shiny_front: shinyFrontVisual,
      shiny_back: shinyBackVisual,
      overworld: overworldVisual,
      shiny_strategy: entry.visuals?.shiny_strategy || "hue_shift"
    }),
    world_data: normalizeWorldData(entry.world_data),
    fusion_meta: normalizeFusionMeta(entry.fusion_meta, entry.fusion_rule),
    export_meta: normalizeExportMeta(entry.export_meta)
  };
}

function normalizeCreatorSpeciesEntry(entry) {
  const runtimeBase = Number(state.catalog?.framework?.standard_species_min || 0);
  const slot = Number(entry.slot || 0);
  const idNumber = runtimeBase > 0 && slot > 0 ? runtimeBase + slot - 1 : Number(entry.id_number || 0);
  const fusionRule = entry.fusion_rule || "blocked";
  const frontVisual = modAssetUrl(entry.assets?.front);
  const backVisual = entry.assets?.back ? modAssetUrl(entry.assets.back) : frontVisual;
  const iconVisual = entry.assets?.icon ? modAssetUrl(entry.assets.icon) : frontVisual;
  const fusionSource = normalizeFusionSourceValue(entry.fusion_source || entry.base_species);
  return {
    id: entry.id,
    name: entry.name || entry.id,
    species: entry.id,
    id_number: idNumber,
    category: entry.category || "Custom Species",
    pokedex_entry: entry.pokedex_entry || "",
    design_notes: entry.design_notes || "",
    template_source_label: entry.template_source_label || "",
    types: uniqueTypes([entry.type1, entry.type2]),
    base_stats: normalizeStats(entry.base_stats),
    bst: calculateBst(entry.base_stats),
    base_exp: Number(entry.base_exp || 0),
    growth_rate: namedCatalogEntry("growth_rates", entry.growth_rate),
    gender_ratio: namedCatalogEntry("gender_ratios", entry.gender_ratio),
    catch_rate: Number(entry.catch_rate || 0),
    happiness: Number(entry.happiness || 0),
    abilities: normalizeNamedList((entry.abilities || []).map((id) => namedCatalogEntry("abilities", id))),
    hidden_abilities: normalizeNamedList((entry.hidden_abilities || []).map((id) => namedCatalogEntry("abilities", id))),
    moves: normalizeMoveList((entry.moves || []).map((move) => ({ level: move.level, ...moveCatalogEntry(move.move) }))),
    tutor_moves: normalizeMoveList((entry.tutor_moves || []).map((id) => moveCatalogEntry(id))),
    egg_moves: normalizeMoveList((entry.egg_moves || []).map((id) => moveCatalogEntry(id))),
    tm_moves: normalizeMoveList((entry.tm_moves || []).map((id) => moveCatalogEntry(id))),
    egg_groups: normalizeNamedList((entry.egg_groups || []).map((id) => namedCatalogEntry("egg_groups", id))),
    hatch_steps: Number(entry.hatch_steps || 0),
    evolutions: normalizeEvolutionList((entry.evolutions || []).map((evo) => ({
      species: speciesReference(evo.species),
      method: evolutionMethodEntry(evo.method),
      parameter: evolutionParameterDisplay(evo.parameter, evo.method)
    }))),
    previous_species: entry.base_species && entry.kind === "regional_variant" ? speciesReference(entry.base_species) : null,
    family_species: buildCreatorFamily(entry),
    height: Number(entry.height || 0),
    weight: Number(entry.weight || 0),
    color: namedCatalogEntry("body_colors", entry.color),
    shape: namedCatalogEntry("body_shapes", entry.shape),
    habitat: namedCatalogEntry("habitats", entry.habitat),
    generation: Number(entry.generation || 0),
    kind: entry.kind || "fakemon",
    source: "creator_saved",
    fusion_rule: fusionRule,
    fusion_compatible: fusionRule === "standard",
    starter_eligible: Boolean(entry.starter_eligible),
    encounter_eligible: Boolean(entry.encounter_eligible),
    trainer_eligible: Boolean(entry.trainer_eligible),
    regional_variant: entry.kind === "regional_variant",
    variant_scope: entry.variant_scope || (entry.kind === "regional_variant" ? "single_species" : ""),
    variant_family: entry.variant_family || "",
    base_species: speciesReference(entry.base_species),
    fallback_species: speciesReference(entry.fallback_species),
    fusion_source: fusionSource,
    visuals: {
      front: frontVisual,
      back: backVisual,
      icon: iconVisual,
      shiny_strategy: "hue_shift"
    },
    world_data: normalizeWorldData(entry.world_data || {
      encounter_rarity: entry.encounter_rarity,
      encounter_zones: entry.encounter_zones,
      trainer_roles: entry.trainer_roles,
      trainer_notes: entry.trainer_notes,
      encounter_level_min: entry.encounter_level_min,
      encounter_level_max: entry.encounter_level_max
    }),
    fusion_meta: normalizeFusionMeta(entry.fusion_meta || {
      rule: fusionRule,
      head_offset_x: entry.head_offset_x,
      head_offset_y: entry.head_offset_y,
      body_offset_x: entry.body_offset_x,
      body_offset_y: entry.body_offset_y,
      naming_notes: entry.fusion_naming_notes,
      sprite_hints: entry.fusion_sprite_hints
    }, fusionRule),
    export_meta: normalizeExportMeta(entry.export_meta || {
      framework_managed: true,
      slot,
      json_filename: `${String(entry.id || "species").toLowerCase()}.json`,
      recommended_internal_id: entry.id,
      author: entry.export_author,
      version: entry.export_version,
      pack_name: entry.export_pack_name,
      tags: entry.export_tags
    })
  };
}

function refreshWorkspace() {
  renderModeUi();
  updateKindUi();
  updateBst();
  updateSummaryBadges();
  renderCreatorSpeciesList();
  renderDexSpeciesList();
  renderPokedexPanels();
  renderDraftVisualVariantPanel();
  renderStarterEditor();
  renderImporterEditor();
  renderImporterResults();
  renderIntegrationSummary();
  renderHomePcDeliveryPanel();
  renderWizardProgress();
  renderInsights();
  renderValidationPanels();
  renderExportManifest();
  renderLivePreview();
  updateUndoRedoButtons();
}

function renderModeUi() {
  document.querySelectorAll(".nav-button").forEach((button) => {
    button.classList.toggle("active", button.dataset.mode === state.mode);
  });
  setValue("dexCatalogScope", state.dexCatalogScope);
  const dexKindFilter = document.getElementById("dexKindFilter");
  if (dexKindFilter) {
    dexKindFilter.disabled = state.dexCatalogScope === "fusion";
  }
  document.querySelectorAll(".sidebar-pane").forEach((pane) => {
    pane.classList.toggle("hidden", pane.dataset.mode !== state.mode);
  });
  document.querySelectorAll(".view-section").forEach((section) => {
    const matches = section.dataset.mode === state.mode;
    section.classList.toggle("hidden", !matches);
    section.classList.toggle("active", matches);
  });
  setCreatorTab(state.creatorTab);
  setDexTab(state.dexTab);
  setIntegrationTab(state.integrationTab);
}

function setMode(mode) {
  state.mode = mode;
  renderModeUi();
  renderLivePreview();
  if (mode === "integration") {
    refreshDeliveryQueueState({ silent: true }).catch(() => {});
    if (["importer", "review"].includes(state.integrationTab)) {
      refreshImporterState({ silent: true }).catch(() => {});
    }
  }
}

function setDexCatalogScope(scope) {
  const normalizedScope = scope === "fusion" ? "fusion" : "species";
  const previousEntry = selectedDexEntry();
  state.dexCatalogScope = normalizedScope;
  setValue("dexCatalogScope", normalizedScope);
  state.dexCache.filteredQuery = "";
  state.dexCache.fusionEntriesSignature = "";

  if (normalizedScope === "fusion") {
    seedFusionCatalogFromEntry(previousEntry);
    ensureFusionSliceAvailable({ silent: true }).catch(() => {});
  } else if (previousEntry && isFusionSymbol(previousEntry.id)) {
    const fallbackEntry = previousEntry.fusion_source?.head || previousEntry.fusion_source?.body || speciesReference(state.fusionBuilder.headId) || speciesReference(state.fusionBuilder.bodyId);
    state.dexSelectedId = fallbackEntry?.id || state.dexSelectedId;
  }

  renderDexSpeciesList();
  renderPokedexPanels();
  renderLivePreview();
}

function setCreatorTab(tab) {
  state.creatorTab = tab;
  document.querySelectorAll("[data-creator-tab].tab-button").forEach((button) => {
    button.classList.toggle("active", button.dataset.creatorTab === tab);
  });
  document.querySelectorAll(".editor-panel[data-creator-tab]").forEach((panel) => {
    panel.classList.toggle("hidden", panel.dataset.creatorTab !== tab);
    panel.classList.toggle("active", panel.dataset.creatorTab === tab);
  });
  if (tab === "publish") {
    refreshDeliveryQueueState({ silent: true }).catch(() => {});
  }
}

function setDexTab(tab) {
  state.dexTab = tab;
  document.querySelectorAll("[data-dex-tab].tab-button").forEach((button) => {
    button.classList.toggle("active", button.dataset.dexTab === tab);
  });
  document.querySelectorAll(".editor-panel[data-dex-tab]").forEach((panel) => {
    panel.classList.toggle("hidden", panel.dataset.dexTab !== tab);
    panel.classList.toggle("active", panel.dataset.dexTab === tab);
  });
  if (state.mode === "pokedex") {
    queueDexSpeciesDetail(selectedDexEntry(), { silent: true });
    renderPokedexPanels();
  }
}

function setIntegrationTab(tab) {
  state.integrationTab = tab;
  document.querySelectorAll("[data-integration-tab].tab-button").forEach((button) => {
    button.classList.toggle("active", button.dataset.integrationTab === tab);
  });
  document.querySelectorAll(".editor-panel[data-integration-tab]").forEach((panel) => {
    panel.classList.toggle("hidden", panel.dataset.integrationTab !== tab);
    panel.classList.toggle("active", panel.dataset.integrationTab === tab);
  });
  if (state.mode === "integration" && ["importer", "review"].includes(tab)) {
    refreshImporterState({ silent: true }).catch(() => {});
  }
}

function creatorWizardSteps() {
  const draft = currentDraftPayload();
  const entry = currentDraftViewerEntry();
  const validation = computeValidation(draft);
  const delivery = gatherDeliveryPayload();
  const isRegionalVariant = draft.kind === "regional_variant";
  const regionalSource = fusionSourceStateFromPayload(draft);
  const isFusionRegionalVariant = Boolean(isRegionalVariant && regionalSource.mode === "fusion");
  const hasBaseSpecies = Boolean(isRegionalVariant && regionalSource.ready);
  const bst = calculateBst({
    HP: Number(draft.hp || 0),
    ATTACK: Number(draft.attack || 0),
    DEFENSE: Number(draft.defense || 0),
    SPECIAL_ATTACK: Number(draft.special_attack || 0),
    SPECIAL_DEFENSE: Number(draft.special_defense || 0),
    SPEED: Number(draft.speed || 0)
  });
  const hasFrontArt = Boolean(state.pendingAssets.front_data_url || (entry.visuals?.front && entry.visuals.front !== BLANK_IMAGE));
  const canReuseBaseArt = isRegionalVariant && regionalSource.canReuseBaseArt;
  const hasDexCopy = Boolean((draft.pokedex_entry || "").trim());
  const deliveryReady = Number(delivery.level || 0) >= 1 && Number(delivery.level || 0) <= 100 && Number(delivery.quantity || 0) >= 1 && Number(delivery.quantity || 0) <= 6;
  const savedId = document.getElementById("existingId").value || "";
  const queuedForPc = Boolean(savedId && (state.deliveryQueue?.pending || []).some((queued) => queued?.species_id === savedId));
  const moveReady = Array.isArray(draft.moves) && draft.moves.some((move) => (move.move || "").trim());
  const basicsReady = Boolean((draft.name || "").trim() && (draft.internal_id || "").trim() && (draft.category || "").trim() && (!isRegionalVariant || hasBaseSpecies));
  const traitsReady = Boolean((draft.type1 || "").trim() && (draft.primary_ability || "").trim());
  const battleReady = bst >= 180 && moveReady;
  const presentationReady = (hasFrontArt || canReuseBaseArt) && hasDexCopy;
  const publishReady = !validation.errors.length && deliveryReady && queuedForPc;
  return [
    {
      key: "overview",
      label: isFusionRegionalVariant ? "Pick the fusion source" : (isRegionalVariant ? "Pick the base species" : "Set species basics"),
      summary: isRegionalVariant
        ? "Choose the original Pokémon this variant should coexist with, then name the new version."
        : "Name it, give it an internal ID, and define its role at a glance.",
      tab: "overview",
      complete: basicsReady
    },
    {
      key: "identity",
      label: isRegionalVariant ? "Edit the variant traits" : "Choose typing and abilities",
      summary: isRegionalVariant
        ? "Change typing, abilities, breeding data, and flavor so it feels like a real alternate form."
        : "Make sure the species has battle identity and legal ability data.",
      tab: "identity",
      complete: traitsReady
    },
    {
      key: "battle",
      label: "Make it battle-ready",
      summary: "Balance its stats and add at least one real level-up move.",
      tab: moveReady ? "stats" : "moves",
      complete: battleReady
    },
    {
      key: "presentation",
      label: isRegionalVariant ? "Reuse or replace the art" : "Add art and Dex copy",
      summary: isRegionalVariant
        ? (hasFrontArt ? "Custom art is attached. You can still leave the original species visuals as the fallback in-game." : "Regional variants can reuse the base species art until you decide to upload new visuals.")
        : "Give it front art and the Pokédex text that will sell it in-game.",
      tab: hasDexCopy ? (hasFrontArt ? "lore" : (isRegionalVariant ? (hasBaseSpecies ? "visuals" : "overview") : "visuals")) : "lore",
      complete: presentationReady
    },
    {
      key: "publish",
      label: queuedForPc ? "Queued for bedroom PC pickup" : "Queue the bedroom PC delivery",
      summary: queuedForPc
        ? "This species is already on the bedroom PC delivery list."
        : "Publish the saved species and create one delivery ticket the player can claim in-game.",
      tab: "publish",
      complete: publishReady,
      pending: !queuedForPc && !validation.errors.length && deliveryReady
    }
  ];
}

function nextWizardStep() {
  return creatorWizardSteps().find((step) => !step.complete) || creatorWizardSteps().slice(-1)[0] || null;
}

function openNextWizardStep() {
  const step = nextWizardStep();
  if (!step) {
    return;
  }
  setMode("creator");
  setCreatorTab(step.tab);
  renderWizardProgress();
}

function renderWizardProgress() {
  const summary = document.getElementById("wizardProgressSummary");
  const list = document.getElementById("wizardStepList");
  const hint = document.getElementById("wizardQuestHint");
  const progressBadge = document.getElementById("wizardProgressBadge");
  const currentBadge = document.getElementById("wizardCurrentBadge");
  const bannerTitle = document.getElementById("wizardBannerTitle");
  const bannerText = document.getElementById("wizardBannerText");
  if (!summary || !list || !hint || !progressBadge || !currentBadge || !bannerTitle || !bannerText) {
    return;
  }

  const steps = creatorWizardSteps();
  const completedCount = steps.filter((step) => step.complete).length;
  const nextStep = steps.find((step) => !step.complete) || steps[steps.length - 1] || null;
  const draft = currentDraftPayload();
  const validation = computeValidation(draft);
  const isRegionalVariant = draft.kind === "regional_variant";
  const regionalSource = fusionSourceStateFromPayload(draft);
  const isFusionRegionalVariant = Boolean(isRegionalVariant && regionalSource.mode === "fusion");
  const hasBaseSpecies = Boolean(isRegionalVariant && regionalSource.ready);
  const queued = Boolean(document.getElementById("existingId").value && (state.deliveryQueue?.pending || []).some((entry) => entry?.species_id === document.getElementById("existingId").value));

  summary.innerHTML = `
    <div class="severity-pill ${validation.errors.length ? "error" : "success"}">${validation.errors.length ? "Blocked" : "Ready"} <strong>${validation.errors.length ? validation.errors.length : completedCount}</strong></div>
    <div class="severity-pill warning">Warnings <strong>${validation.warnings.length}</strong></div>
    <div class="severity-pill suggestion">Quest <strong>${completedCount}/${steps.length}</strong></div>
  `;

  list.innerHTML = steps.map((step) => {
    const isCurrent = state.creatorTab === step.tab;
    const statusLabel = step.complete ? "Ready" : (step.pending ? "Next" : "Pending");
    return `
      <button class="wizard-step ${step.complete ? "is-complete" : ""} ${isCurrent ? "is-current" : ""}" data-wizard-tab="${escapeAttribute(step.tab)}" type="button">
        <div class="wizard-step-topline">
          <strong>${escapeHtml(step.label)}</strong>
          <span class="status-chip ${step.complete ? "ready" : (step.pending ? "review" : "neutral")}">${escapeHtml(statusLabel)}</span>
        </div>
        <span>${escapeHtml(step.summary)}</span>
      </button>
    `;
  }).join("");

  list.querySelectorAll("[data-wizard-tab]").forEach((button) => {
    button.addEventListener("click", () => {
      setMode("creator");
      setCreatorTab(button.dataset.wizardTab);
      renderWizardProgress();
    });
  });

  hint.textContent = queued
    ? "The species is queued. Restart the game if needed, then claim it from the bedroom PC."
    : (nextStep ? `Next up: ${nextStep.label}. ${nextStep.summary}` : "The guided quest is ready.");
  progressBadge.textContent = `${completedCount} / ${steps.length} Ready`;
  currentBadge.textContent = queued
    ? "Bedroom PC Ready"
    : (nextStep ? `Next: ${nextStep.label}` : "Quest Complete");
  bannerTitle.textContent = queued
    ? "This species is on the bedroom PC delivery list."
    : (isRegionalVariant
        ? (hasBaseSpecies ? "Turn one existing Pokémon into a new regional variant." : "Start by picking a base Pokémon from the Pokédex.")
        : "Build one complete species, then queue it for the bedroom PC.");
  bannerText.textContent = queued
    ? "Launch the game, open the bedroom PC, and claim the queued delivery to test the full pipeline in-engine."
    : (isRegionalVariant
        ? (nextStep
            ? `This path keeps the original species untouched. ${nextStep.summary}`
            : "Finish the guided steps to save a coexistence-safe variant and queue it for the bedroom PC.")
        : (nextStep ? `Stay on the wizard path: ${nextStep.summary}` : "Finish the guided steps to get a clean, playable species into the game."));

  const nextButton = document.getElementById("wizardNextStepBtn");
  if (nextButton) {
    nextButton.textContent = nextStep ? `Open ${nextStep.label}` : "Open Next Step";
  }
}

function renderCreatorSpeciesList() {
  const list = document.getElementById("creatorSpeciesList");
  list.textContent = "";
  if (state.species.length === 0) {
    list.innerHTML = `<p class="muted-copy">No saved creator species yet. Use a template or clone a Pokédex entry to begin.</p>`;
    return;
  }

  state.species
    .map(normalizeCreatorSpeciesEntry)
    .sort((a, b) => (a.export_meta.slot || 0) - (b.export_meta.slot || 0))
    .forEach((entry) => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = `species-item ${state.selectedId === entry.id ? "active" : ""}`;
      button.innerHTML = `
        <img alt="${escapeAttribute(entry.name)}" loading="lazy" decoding="async">
        <div>
          <strong>${escapeHtml(entry.name)}</strong>
          <small>${escapeHtml(entry.id)} · Slot ${escapeHtml(String(entry.export_meta.slot || "?"))}</small>
          <div class="species-item-meta">
            ${entry.types.map((type) => `<span class="compare-chip">${escapeHtml(titleizeToken(type))}</span>`).join("")}
          </div>
        </div>
      `;
      setImageSourceWithFallback(button.querySelector("img"), previewIconCandidates(entry));
      button.addEventListener("click", () => {
        loadSpeciesIntoForm(state.species.find((species) => species.id === entry.id));
        setMode("creator");
      });
      list.appendChild(button);
    });
}

function renderDexSpeciesList() {
  const list = document.getElementById("dexSpeciesList");
  if (!list) {
    return;
  }
  const speciesEntries = filteredDexEntries();
  const fusionRequest = state.dexCatalogScope === "fusion" ? currentFusionSliceRequest() : null;
  const fusionSlicePending = fusionRequest?.cacheKey ? state.pendingFusionSliceRequests.has(fusionRequest.cacheKey) : false;
  if (speciesEntries.length > 0 && !speciesEntries.some((entry) => entry.id === state.dexSelectedId)) {
    state.dexSelectedId = speciesEntries[0].id;
  }
  const fragment = document.createDocumentFragment();
  list.textContent = "";
  if (speciesEntries.length === 0 && state.dexCatalogScope === "fusion") {
    if (!fusionRequest?.headEntry) {
      list.textContent = "Choose a fusion head to open that Pokémon's installed fusion slice.";
      return;
    } else if (fusionSlicePending) {
      list.innerHTML = `<p class="muted-copy">Scanning installed fusion sprites for ${escapeHtml(fusionRequest.headEntry.name)}.</p>`;
    } else if (fusionRequest?.bodyEntry) {
      list.innerHTML = `<p class="muted-copy">No installed sprites were found for the ${escapeHtml(fusionRequest.headEntry.name)} + ${escapeHtml(fusionRequest.bodyEntry.name)} fusion.</p>`;
    } else {
      list.innerHTML = `<p class="muted-copy">No installed fusion sprites were found for the ${escapeHtml(fusionRequest.headEntry.name)} slice.</p>`;
    }
    return;
  }
  if (speciesEntries.length === 0) {
    list.innerHTML = `<p class="muted-copy">No species match the current Pokédex filters.</p>`;
    return;
  }
  speciesEntries.forEach((entry) => {
    const compareLabels = [];
    if (state.dexCompareIds.left === entry.id) compareLabels.push("A");
    if (state.dexCompareIds.right === entry.id) compareLabels.push("B");
    const button = document.createElement("button");
    button.type = "button";
    button.dataset.speciesId = entry.id;
    button.className = `species-item ${state.dexSelectedId === entry.id ? "active" : ""}`;
    const secondaryLine = state.dexCatalogScope === "fusion"
      ? `${entry.fusion_source?.head?.name || "Unknown"} head · ${entry.fusion_source?.body?.name || "Unknown"} body`
      : `No. ${formatDexNumber(entry.id_number)} · ${titleizeToken(entry.kind)}`;
    const fusionVariantChip = state.dexCatalogScope === "fusion" && Number(entry.installed_variant_count || 0) > 0
      ? `<span class="compare-chip">${escapeHtml(String(entry.installed_variant_count))} art option${Number(entry.installed_variant_count || 0) === 1 ? "" : "s"}</span>`
      : "";
    button.innerHTML = `
      <img alt="${escapeAttribute(entry.name)}" loading="lazy" decoding="async">
      <div>
        <strong>${escapeHtml(entry.name)}</strong>
        <small>No. ${escapeHtml(formatDexNumber(entry.id_number))} · ${escapeHtml(titleizeToken(entry.kind))}</small>
        <div class="species-item-meta">
          ${entry.types.map((type) => `<span class="compare-chip">${escapeHtml(titleizeToken(type))}</span>`).join("")}
          ${compareLabels.map((label) => `<span class="compare-chip">Compare ${escapeHtml(label)}</span>`).join("")}
        </div>
      </div>
    `;
    const secondaryLineNode = button.querySelector("small");
    if (secondaryLineNode) {
      secondaryLineNode.textContent = secondaryLine;
    }
    if (fusionVariantChip) {
      button.querySelector(".species-item-meta")?.insertAdjacentHTML("afterbegin", fusionVariantChip);
    }
    const thumbnailCandidates = state.dexCatalogScope === "fusion" || isFusionSymbol(entry.id)
      ? previewImageCandidates(entry)
      : previewIconCandidates(entry);
    setImageSourceWithFallback(button.querySelector("img"), thumbnailCandidates);
    button.addEventListener("click", () => {
      state.dexSelectedId = entry.id;
      list.querySelectorAll(".species-item.active").forEach((item) => item.classList.remove("active"));
      button.classList.add("active");
      queueDexSpeciesDetail(entry, { silent: true });
      renderPokedexPanels();
      renderLivePreview();
    });
    fragment.appendChild(button);
  });
  list.replaceChildren(fragment);
}

function scheduleDexSpeciesListRender() {
  window.clearTimeout(state.dexRenderTimer);
  state.dexRenderTimer = window.setTimeout(() => renderDexSpeciesList(), 90);
}

function currentDexSourceEntries() {
  return state.dexCatalogScope === "fusion" ? fusionCatalogEntries() : mergedDexEntries();
}

function filteredDexEntries() {
  const search = normalizeLookupValue(document.getElementById("dexSearch").value).toLowerCase();
  const typeFilter = document.getElementById("dexTypeFilter").value;
  const kindFilter = document.getElementById("dexKindFilter").value;
  const abilityFilter = normalizeLookupValue(document.getElementById("dexAbilityFilter").value).toUpperCase();
  const sort = document.getElementById("dexSort").value;
  const sourceEntries = currentDexSourceEntries();
  const filterQuery = [state.dexCatalogScope, search, typeFilter, kindFilter, abilityFilter, sort, state.fusionBuilder.headId, state.fusionBuilder.bodyId, state.dexSelectedId].join("\u0001");

  if (
    state.dexCache.filteredSource === sourceEntries &&
    state.dexCache.filteredQuery === filterQuery &&
    state.dexCache.filteredEntries !== EMPTY_ARRAY
  ) {
    return state.dexCache.filteredEntries;
  }

  const entries = sourceEntries.filter((entry) => {
    if (search) {
      const haystack = [entry.name, entry.id, String(entry.id_number)].join(" ").toLowerCase();
      if (!haystack.includes(search)) {
        return false;
      }
    }
    if (typeFilter && !entry.types.includes(typeFilter)) {
      return false;
    }
    if (state.dexCatalogScope !== "fusion" && kindFilter && kindFilter !== "all") {
      if (kindFilter === "base_game" && entry.source !== "base_game") {
        return false;
      }
      if (kindFilter !== "base_game" && entry.kind !== kindFilter) {
        return false;
      }
    }
    if (abilityFilter) {
      const abilityIds = [...entry.abilities, ...entry.hidden_abilities].map((ability) => ability.id.toUpperCase());
      if (!abilityIds.includes(abilityFilter)) {
        return false;
      }
    }
    return true;
  });

  entries.sort((a, b) => {
    if (sort === "name") {
      return a.name.localeCompare(b.name);
    }
    if (sort === "bst") {
      return b.bst - a.bst || a.name.localeCompare(b.name);
    }
    if (state.dexCatalogScope === "fusion") {
      const aSort = Number(a.fusion_source?.body?.id_number || a.fusion_source?.head?.id_number || a.id_number || 999999);
      const bSort = Number(b.fusion_source?.body?.id_number || b.fusion_source?.head?.id_number || b.id_number || 999999);
      return aSort - bSort || a.name.localeCompare(b.name);
    }
    return (a.id_number || 999999) - (b.id_number || 999999) || a.name.localeCompare(b.name);
  });
  state.dexCache.filteredSource = sourceEntries;
  state.dexCache.filteredQuery = filterQuery;
  state.dexCache.filteredEntries = entries;
  return entries;
}

function selectedDexEntry() {
  const entries = filteredDexEntries();
  const direct = speciesEntryById(state.dexSelectedId);
  if (entries.length === 0) {
    return direct;
  }
  const inList = entries.find((entry) => entry.id === state.dexSelectedId) || null;
  if (inList) {
    return speciesEntryById(inList.id) || inList;
  }
  if (direct) {
    return direct;
  }
  const fallback = entries[0] || null;
  return fallback ? (speciesEntryById(fallback.id) || fallback) : null;
}

function queueDexSpeciesDetail(entry, options = {}) {
  if (!entry || entry.detail_level === "full") {
    return null;
  }
  const normalizedId = normalizeLookupValue(entry.id);
  if (!options.force && state.catalogDetailErrors.has(normalizedId)) {
    return null;
  }
  return ensureDexSpeciesDetail(entry.id, { silent: options.silent !== false }).catch(() => null);
}

function fusionBrowsePoolEntries() {
  const baseCount = fusionBaseSpeciesMax();
  return mergedDexEntries()
    .filter((entry) => {
      if (!entry || isFusionSymbol(entry.id)) {
        return false;
      }
      const dexNumber = Number(entry.id_number || 0);
      if (dexNumber <= 0) {
        return false;
      }
      return baseCount > 0 ? dexNumber <= baseCount : true;
    })
    .sort((a, b) => (a.id_number || 999999) - (b.id_number || 999999) || a.name.localeCompare(b.name));
}

function selectedFusionSeedEntry(pool = fusionBrowsePoolEntries()) {
  const selectedEntry = fusionComponentEntryById(state.dexSelectedId);
  if (selectedEntry) {
    return selectedEntry;
  }
  const currentHead = fusionComponentEntryById(state.fusionBuilder.headId);
  if (currentHead) {
    return currentHead;
  }
  return pool[0] || null;
}

function seedFusionCatalogFromEntry(entry) {
  const seedEntry = fusionComponentEntryById(entry?.id) || selectedFusionSeedEntry();
  if (!seedEntry) {
    return;
  }
  if (!fusionComponentEntryById(state.fusionBuilder.headId)) {
    state.fusionBuilder.headId = seedEntry.id;
    setValue("dexFusionHead", seedEntry.id);
  }
  refreshDexFusionPreview({ ensureDetail: false, silent: true }).catch(() => {});
}

function fusionSliceCacheKey(headDex, bodyDex = 0) {
  const normalizedHeadDex = Number(headDex || 0);
  const normalizedBodyDex = Number(bodyDex || 0);
  if (normalizedHeadDex <= 0) {
    return "";
  }
  return `${normalizedHeadDex}::${normalizedBodyDex}`;
}

function currentFusionSliceRequest() {
  const selectedFusion = parseFusionSymbol(state.dexSelectedId);
  let headEntry = fusionComponentEntryById(state.fusionBuilder.headId);
  let bodyEntry = fusionComponentEntryById(state.fusionBuilder.bodyId);

  if (!headEntry && selectedFusion) {
    headEntry = standardFusionComponentEntryByDexNumber(selectedFusion.headDex);
  }
  if (!bodyEntry && selectedFusion) {
    bodyEntry = standardFusionComponentEntryByDexNumber(selectedFusion.bodyDex);
  }
  if (!headEntry) {
    headEntry = fusionComponentEntryById(state.dexSelectedId);
  }

  const headDex = Number(headEntry?.id_number || 0);
  const bodyDex = Number(bodyEntry?.id_number || 0);
  return {
    headEntry,
    bodyEntry,
    headDex,
    bodyDex,
    cacheKey: fusionSliceCacheKey(headDex, bodyDex)
  };
}

function getCachedFusionSlice(request = currentFusionSliceRequest()) {
  if (!request?.cacheKey) {
    return null;
  }
  return state.fusionSliceCache.get(request.cacheKey) || null;
}

function normalizeFusionSlicePayload(data) {
  if (!data || typeof data !== "object") {
    return null;
  }
  const entries = Array.isArray(data.entries) ? data.entries : [];
  return {
    ok: Boolean(data.ok),
    head_dex: Number(data.head_dex || 0),
    body_dex: Number(data.body_dex || 0),
    total_entries: Number(data.total_entries || entries.length || 0),
    entries: entries
      .map((entry) => ({
        head_dex: Number(entry.head_dex || 0),
        body_dex: Number(entry.body_dex || 0),
        fusion_id: normalizeLookupValue(entry.fusion_id).toUpperCase(),
        preview_path: entry.preview_path || "",
        variant_count: Number(entry.variant_count || 0),
        sources: Array.isArray(entry.sources) ? entry.sources : []
      }))
      .filter((entry) => entry.head_dex > 0 && entry.body_dex > 0)
      .sort((left, right) => left.body_dex - right.body_dex)
  };
}

async function ensureFusionSliceAvailable(options = {}) {
  const request = options.request || currentFusionSliceRequest();
  if (!request?.headDex) {
    return null;
  }
  if (options.refresh) {
    state.dexCache.fusionEntriesSignature = "";
    state.dexCache.fusionEntries = EMPTY_ARRAY;
  }
  if (!options.refresh && state.fusionSliceCache.has(request.cacheKey)) {
    return state.fusionSliceCache.get(request.cacheKey);
  }
  if (state.pendingFusionSliceRequests.has(request.cacheKey)) {
    return state.pendingFusionSliceRequests.get(request.cacheKey);
  }

  const query = new URLSearchParams();
  query.set("head_dex", String(request.headDex));
  if (request.bodyDex > 0) {
    query.set("body_dex", String(request.bodyDex));
  }

  const pending = fetchJson(`/api/fusion-slice?${query.toString()}`, { allowError: true, timeoutMs: 15000 })
    .then((result) => {
      if (!result.ok || !result.data?.ok) {
        throw new Error(result.data?.error || "The installed fusion slice could not be scanned.");
      }
      const payload = normalizeFusionSlicePayload(result.data);
      state.fusionSliceCache.set(request.cacheKey, payload);
      state.dexCache.fusionEntriesSignature = "";
      state.dexCache.fusionEntries = EMPTY_ARRAY;
      return payload;
    })
    .then((payload) => {
      const currentRequest = currentFusionSliceRequest();
      if (currentRequest.cacheKey === request.cacheKey && state.dexCatalogScope === "fusion") {
        renderDexSpeciesList();
        renderPokedexPanels();
        renderLivePreview();
      }
      return payload;
    })
    .catch((error) => {
      if (!options.silent) {
        showMessage(error?.message || "The installed fusion slice could not be scanned.", "error");
      }
      return null;
    })
    .finally(() => {
      state.pendingFusionSliceRequests.delete(request.cacheKey);
    });

  state.pendingFusionSliceRequests.set(request.cacheKey, pending);
  return pending;
}

function buildFusionSliceEntry(headEntry, sliceEntry) {
  const bodyEntry = standardFusionComponentEntryByDexNumber(sliceEntry?.body_dex);
  if (!headEntry || !bodyEntry) {
    return null;
  }
  const fusionEntry = buildFusionSpeciesEntry(headEntry, bodyEntry);
  if (!fusionEntry) {
    return null;
  }
  const visuals = {
    ...(fusionEntry.visuals || {})
  };
  if (sliceEntry.preview_path) {
    visuals.front = sliceEntry.preview_path;
    visuals.back ||= sliceEntry.preview_path;
  }
  return {
    ...fusionEntry,
    visuals,
    installed_variant_count: Number(sliceEntry.variant_count || 0),
    installed_variant_sources: Array.isArray(sliceEntry.sources) ? sliceEntry.sources : []
  };
}

function fusionCatalogEntries() {
  const request = currentFusionSliceRequest();
  const signature = [request.cacheKey, state.dexSelectedId].join("\u0001");

  if (
    state.dexCache.fusionEntriesSignature === signature &&
    state.dexCache.fusionEntries !== EMPTY_ARRAY
  ) {
    return state.dexCache.fusionEntries;
  }

  if (!request.headEntry) {
    state.dexCache.fusionEntriesSignature = signature;
    state.dexCache.fusionEntries = EMPTY_ARRAY;
    return [];
  }

  const payload = getCachedFusionSlice(request);
  if (!payload) {
    ensureFusionSliceAvailable({ request, silent: true }).catch(() => {});
    state.dexCache.fusionEntriesSignature = signature;
    state.dexCache.fusionEntries = EMPTY_ARRAY;
    return [];
  }

  const entries = payload.entries
    .map((sliceEntry) => buildFusionSliceEntry(request.headEntry, sliceEntry))
    .filter(Boolean);
  entries.forEach((entry) => {
    state.syntheticDexEntries.set(entry.id, entry);
  });

  state.dexCache.fusionEntriesSignature = signature;
  state.dexCache.fusionEntries = entries;
  return entries;
}

function fusionBaseSpeciesMax() {
  const standardSpeciesMin = Number(state.catalog?.framework?.standard_species_min || 0);
  if (standardSpeciesMin > 1) {
    return standardSpeciesMin - 1;
  }
  return 0;
}

function isFusionSymbol(value) {
  return /^B\d+H\d+$/i.test(normalizeLookupValue(value));
}

function parseFusionSymbol(value) {
  const match = normalizeLookupValue(value).toUpperCase().match(/^B(\d+)H(\d+)$/);
  if (!match) {
    return null;
  }
  return {
    id: `B${Number(match[1])}H${Number(match[2])}`,
    bodyDex: Number(match[1]),
    headDex: Number(match[2])
  };
}

function buildFusionSymbol(bodyDex, headDex) {
  const normalizedBody = Number(bodyDex || 0);
  const normalizedHead = Number(headDex || 0);
  if (!normalizedBody || !normalizedHead) {
    return "";
  }
  return `B${normalizedBody}H${normalizedHead}`;
}

function fusionDexNumber(bodyDex, headDex) {
  const baseCount = fusionBaseSpeciesMax();
  if (baseCount <= 0) {
    return 0;
  }
  return (Number(bodyDex || 0) * baseCount) + Number(headDex || 0);
}

function standardFusionComponentEntryByDexNumber(idNumber) {
  const numericId = Number(idNumber || 0);
  const baseCount = fusionBaseSpeciesMax();
  if (numericId <= 0 || baseCount <= 0 || numericId > baseCount) {
    return null;
  }
  return mergedDexEntries().find((entry) => {
    if (!entry || isFusionSymbol(entry.id)) {
      return false;
    }
    return Number(entry.id_number || 0) === numericId;
  }) || null;
}

function fusionComponentEntryById(speciesId) {
  const normalizedId = normalizeLookupValue(speciesId);
  if (!normalizedId || isFusionSymbol(normalizedId)) {
    return null;
  }
  const entry = mergedDexEntries().find((candidate) => candidate?.id === normalizedId) || null;
  if (!entry) {
    return null;
  }
  const baseCount = fusionBaseSpeciesMax();
  const dexNumber = Number(entry.id_number || 0);
  if (baseCount > 0 && (dexNumber <= 0 || dexNumber > baseCount)) {
    return null;
  }
  return entry;
}

function uniqueFusionNamedEntries(entries) {
  const seen = new Set();
  return (entries || []).filter((entry) => {
    if (!entry?.id || seen.has(entry.id)) {
      return false;
    }
    seen.add(entry.id);
    return true;
  });
}

function combineFusionMoveRows(entries) {
  return normalizeMoveList(entries || []);
}

function fusionStatBlend(dominant, other) {
  return Math.floor((2 * Number(dominant || 0)) / 3) + Math.floor(Number(other || 0) / 3);
}

function fusionGrowthRate(headEntry, bodyEntry) {
  const priority = ["Fast", "Medium", "Parabolic", "Fluctuating", "Erratic", "Slow"];
  const available = new Set([
    headEntry?.growth_rate?.id,
    bodyEntry?.growth_rate?.id
  ].filter(Boolean));
  return namedCatalogEntry("growth_rates", priority.find((id) => available.has(id)) || headEntry?.growth_rate?.id || bodyEntry?.growth_rate?.id || "Medium");
}

function combineFusionDexEntry(bodyEntry, headEntry) {
  const bodyText = normalizeLookupValue(bodyEntry?.pokedex_entry);
  const headText = normalizeLookupValue(headEntry?.pokedex_entry);
  if (!bodyText && !headText) {
    return "";
  }
  if (!bodyText) {
    return headText;
  }
  if (!headText) {
    return bodyText;
  }
  const bodyParts = bodyText.split(".", 2);
  const headParts = headText.split(".", 2);
  const bodyLead = bodyParts[0]?.trim() || bodyText;
  const headTail = (headParts[1] || headParts[0] || headText).trim();
  return `${bodyLead}. ${headTail}`.replace(/\s+/g, " ").trim();
}

function buildFusionReference(headEntry, bodyEntry) {
  if (!headEntry || !bodyEntry) {
    return null;
  }
  return {
    id: buildFusionSymbol(bodyEntry.id_number, headEntry.id_number),
    name: `${headEntry.name} + ${bodyEntry.name}`,
    id_number: fusionDexNumber(bodyEntry.id_number, headEntry.id_number)
  };
}

function buildFusionEvolutionList(headEntry, bodyEntry) {
  const evolutions = [];
  (bodyEntry?.evolutions || []).forEach((evolution) => {
    const evolvedBody = standardFusionComponentEntryByDexNumber(evolution?.species?.id_number);
    if (!evolvedBody) {
      return;
    }
    const fusionSpecies = buildFusionReference(headEntry, evolvedBody);
    if (!fusionSpecies) {
      return;
    }
    evolutions.push({
      species: fusionSpecies,
      method: evolution.method,
      parameter: evolution.parameter
    });
  });
  (headEntry?.evolutions || []).forEach((evolution) => {
    const evolvedHead = standardFusionComponentEntryByDexNumber(evolution?.species?.id_number);
    if (!evolvedHead) {
      return;
    }
    const fusionSpecies = buildFusionReference(evolvedHead, bodyEntry);
    if (!fusionSpecies) {
      return;
    }
    evolutions.push({
      species: fusionSpecies,
      method: evolution.method,
      parameter: evolution.parameter
    });
  });
  return evolutions;
}

function buildFusionSpeciesEntry(headEntry, bodyEntry) {
  if (!headEntry || !bodyEntry) {
    return null;
  }
  const fusionId = buildFusionSymbol(bodyEntry.id_number, headEntry.id_number);
  const dexNumber = fusionDexNumber(bodyEntry.id_number, headEntry.id_number);
  const headType1 = headEntry.types?.[0] || "NORMAL";
  const headType2 = headEntry.types?.[1] || "";
  const primaryType = headType1 === "NORMAL" && headType2 === "FLYING" ? headType2 : headType1;
  const bodyType1 = bodyEntry.types?.[0] || headType1 || "NORMAL";
  const bodyType2 = bodyEntry.types?.[1] || "";
  const secondaryType = (bodyType2 && bodyType2 !== primaryType) ? bodyType2 : (bodyType1 || primaryType);
  const ability1 = bodyEntry.abilities?.[0] || null;
  const ability2 = headEntry.abilities?.[0] || null;
  const hiddenAbility1 = bodyEntry.abilities?.[1] || ability1 || bodyEntry.hidden_abilities?.[0] || null;
  const hiddenAbility2 = headEntry.abilities?.[1] || ability2 || headEntry.hidden_abilities?.[0] || null;
  const fusionReference = buildFusionReference(headEntry, bodyEntry);
  return normalizeCatalogSpeciesEntry({
    id: fusionId,
    species: fusionId,
    name: fusionReference?.name || `${headEntry.name} + ${bodyEntry.name}`,
    id_number: dexNumber,
    category: `${headEntry.category || "Fusion"} / ${bodyEntry.category || "Fusion"}`,
    pokedex_entry: combineFusionDexEntry(bodyEntry, headEntry),
    template_source_label: `Fusion base · ${headEntry.name} head + ${bodyEntry.name} body`,
    types: uniqueTypes([primaryType, secondaryType]),
    base_stats: {
      HP: fusionStatBlend(headEntry.base_stats?.HP, bodyEntry.base_stats?.HP),
      ATTACK: fusionStatBlend(bodyEntry.base_stats?.ATTACK, headEntry.base_stats?.ATTACK),
      DEFENSE: fusionStatBlend(bodyEntry.base_stats?.DEFENSE, headEntry.base_stats?.DEFENSE),
      SPECIAL_ATTACK: fusionStatBlend(headEntry.base_stats?.SPECIAL_ATTACK, bodyEntry.base_stats?.SPECIAL_ATTACK),
      SPECIAL_DEFENSE: fusionStatBlend(headEntry.base_stats?.SPECIAL_DEFENSE, bodyEntry.base_stats?.SPECIAL_DEFENSE),
      SPEED: fusionStatBlend(bodyEntry.base_stats?.SPEED, headEntry.base_stats?.SPEED)
    },
    bst: 0,
    base_exp: Math.floor((Number(headEntry.base_exp || 0) + Number(bodyEntry.base_exp || 0)) / 2),
    growth_rate: fusionGrowthRate(headEntry, bodyEntry),
    gender_ratio: bodyEntry.gender_ratio,
    catch_rate: Math.min(Number(headEntry.catch_rate || 255), Number(bodyEntry.catch_rate || 255)),
    happiness: Number(headEntry.happiness || bodyEntry.happiness || 70),
    abilities: uniqueFusionNamedEntries([ability1, ability2]),
    hidden_abilities: uniqueFusionNamedEntries([
      bodyEntry.abilities?.[1] || ability1,
      headEntry.abilities?.[1] || ability2,
      bodyEntry.hidden_abilities?.[0] || hiddenAbility1,
      headEntry.hidden_abilities?.[0] || hiddenAbility2
    ]),
    moves: combineFusionMoveRows([...(bodyEntry.moves || []), ...(headEntry.moves || [])]),
    tutor_moves: combineFusionMoveRows([...(bodyEntry.tutor_moves || []), ...(headEntry.tutor_moves || [])]),
    egg_moves: combineFusionMoveRows([...(bodyEntry.egg_moves || []), ...(headEntry.egg_moves || [])]),
    tm_moves: combineFusionMoveRows([...(bodyEntry.tm_moves || []), ...(headEntry.tm_moves || [])]),
    egg_groups: uniqueFusionNamedEntries([...(bodyEntry.egg_groups || []), ...(headEntry.egg_groups || [])]),
    hatch_steps: Math.floor((Number(headEntry.hatch_steps || 0) + Number(bodyEntry.hatch_steps || 0)) / 2),
    evolutions: buildFusionEvolutionList(headEntry, bodyEntry),
    previous_species: null,
    family_species: [speciesReference(headEntry.id), speciesReference(bodyEntry.id)].filter(Boolean),
    height: Math.floor((Number(headEntry.height || 0) + Number(bodyEntry.height || 0)) / 2),
    weight: Math.floor((Number(headEntry.weight || 0) + Number(bodyEntry.weight || 0)) / 2),
    color: headEntry.color,
    shape: bodyEntry.shape,
    habitat: bodyEntry.habitat || headEntry.habitat,
    generation: Math.max(Number(headEntry.generation || 0), Number(bodyEntry.generation || 0), 1),
    kind: "fusion_source",
    source: "fusion_source",
    detail_level: headEntry.detail_level === "full" && bodyEntry.detail_level === "full" ? "full" : "summary",
    fusion_rule: "blocked",
    fusion_compatible: false,
    starter_eligible: false,
    encounter_eligible: false,
    trainer_eligible: false,
    regional_variant: false,
    variant_family: "",
    base_species: null,
    fallback_species: null,
    visuals: {
      front: `/game/Graphics/Battlers/${headEntry.id_number}/${headEntry.id_number}.${bodyEntry.id_number}.png`,
      back: `/game/Graphics/Battlers/${headEntry.id_number}/${headEntry.id_number}.${bodyEntry.id_number}.png`,
      icon: `/game/Graphics/Pokemon/FusionIcons/icon${dexNumber}.png`,
      shiny_strategy: "hue_shift"
    },
    world_data: normalizeWorldData({}),
    fusion_meta: normalizeFusionMeta({
      rule: "blocked",
      naming_notes: `Fusion source built from ${headEntry.name} (head) and ${bodyEntry.name} (body).`
    }, "blocked"),
    export_meta: normalizeExportMeta({
      tags: ["fusion_source"]
    }),
    fusion_source: {
      head: speciesReference(headEntry.id),
      body: speciesReference(bodyEntry.id)
    }
  });
}

function buildFusionSpeciesEntryFromSymbol(fusionId) {
  const parsed = parseFusionSymbol(fusionId);
  if (!parsed) {
    return null;
  }
  const headEntry = standardFusionComponentEntryByDexNumber(parsed.headDex);
  const bodyEntry = standardFusionComponentEntryByDexNumber(parsed.bodyDex);
  return buildFusionSpeciesEntry(headEntry, bodyEntry);
}

function fusionSourceStateFromPayload(payload) {
  const kind = normalizeLookupValue(payload?.kind);
  if (kind !== "regional_variant") {
    return {
      ready: false,
      mode: "species",
      canReuseBaseArt: false,
      label: "",
      headEntry: null,
      bodyEntry: null,
      baseSpeciesId: normalizeLookupValue(payload?.base_species),
      fusionSymbol: ""
    };
  }

  const requestedMode = normalizeLookupValue(payload?.variant_source_mode).toLowerCase();
  const payloadBaseSpecies = normalizeLookupValue(payload?.base_species);
  const parsedBaseFusion = parseFusionSymbol(payloadBaseSpecies);
  const fusionMode = requestedMode === "fusion" || Boolean(parsedBaseFusion);
  if (!fusionMode) {
    const baseEntry = speciesEntryById(payloadBaseSpecies);
    return {
      ready: Boolean(baseEntry),
      mode: "species",
      canReuseBaseArt: Boolean(baseEntry),
      label: baseEntry ? baseEntry.name : "",
      headEntry: null,
      bodyEntry: null,
      baseSpeciesId: payloadBaseSpecies,
      fusionSymbol: ""
    };
  }

  let headEntry = fusionComponentEntryById(payload?.fusion_source_head);
  let bodyEntry = fusionComponentEntryById(payload?.fusion_source_body);
  if ((!headEntry || !bodyEntry) && parsedBaseFusion) {
    headEntry ||= standardFusionComponentEntryByDexNumber(parsedBaseFusion.headDex);
    bodyEntry ||= standardFusionComponentEntryByDexNumber(parsedBaseFusion.bodyDex);
  }
  const fusionEntry = buildFusionSpeciesEntry(headEntry, bodyEntry);
  return {
    ready: Boolean(fusionEntry),
    mode: "fusion",
    canReuseBaseArt: Boolean(fusionEntry),
    label: fusionEntry?.name || "",
    headEntry,
    bodyEntry,
    baseSpeciesId: fusionEntry?.id || payloadBaseSpecies,
    fusionSymbol: fusionEntry?.id || payloadBaseSpecies
  };
}

function invalidateDexCaches() {
  state.dexCache.catalogSpeciesSource = null;
  state.dexCache.creatorSpeciesSource = null;
  state.dexCache.mergedEntries = EMPTY_ARRAY;
  state.dexCache.fusionEntriesSource = null;
  state.dexCache.fusionEntriesSignature = "";
  state.dexCache.fusionEntries = EMPTY_ARRAY;
  state.dexCache.filteredSource = null;
  state.dexCache.filteredQuery = "";
  state.dexCache.filteredEntries = EMPTY_ARRAY;
  state.syntheticDexEntries.clear();
  state.visualVariantCache.clear();
  state.pendingVisualVariantRequests.clear();
  state.fusionSliceCache.clear();
  state.pendingFusionSliceRequests.clear();
  state.catalogDetailErrors.clear();
}

function mergeCatalogSpeciesDetail(rawEntry) {
  if (!rawEntry) {
    return null;
  }
  const normalized = normalizeCatalogSpeciesEntry(rawEntry);
  state.catalogDetailErrors.delete(normalized.id);
  const existingCatalog = state.catalog && typeof state.catalog === "object" ? state.catalog : {};
  const existingSpecies = Array.isArray(existingCatalog.species) ? [...existingCatalog.species] : [];
  const index = existingSpecies.findIndex((entry) => entry.id === normalized.id);
  if (index >= 0) {
    existingSpecies[index] = normalized;
  } else {
    existingSpecies.push(normalized);
  }
  state.catalog = {
    ...existingCatalog,
    species: existingSpecies
  };
  invalidateDexCaches();
  return normalized;
}

async function ensureDexSpeciesDetail(speciesId, options = {}) {
  const normalizedId = normalizeLookupValue(speciesId).toUpperCase();
  if (!normalizedId) {
    return null;
  }

  const current = speciesEntryById(normalizedId);
  if (!current || current.detail_level === "full") {
    state.catalogDetailErrors.delete(normalizedId);
    return current;
  }

  if (isFusionSymbol(normalizedId)) {
    const parsed = parseFusionSymbol(normalizedId);
    if (!parsed) {
      return current;
    }
    const headEntry = standardFusionComponentEntryByDexNumber(parsed.headDex);
    const bodyEntry = standardFusionComponentEntryByDexNumber(parsed.bodyDex);
    if (!headEntry || !bodyEntry) {
      return current;
    }
    let resolvedHead = headEntry;
    let resolvedBody = bodyEntry;
    try {
      resolvedHead = await ensureDexSpeciesDetail(headEntry.id, { silent: true }) || headEntry;
      resolvedBody = await ensureDexSpeciesDetail(bodyEntry.id, { silent: true }) || bodyEntry;
    } catch (error) {
      if (!options.silent) {
        showMessage(error?.message || `Couldn't load full data for ${normalizedId}.`, "error");
      }
    }
    const cachedFusionEntry = state.syntheticDexEntries.get(normalizedId) || current;
    const builtFusionEntry = buildFusionSpeciesEntry(resolvedHead, resolvedBody);
    const fusionEntry = builtFusionEntry
      ? {
          ...builtFusionEntry,
          installed_variant_count: Number(cachedFusionEntry?.installed_variant_count || 0),
          installed_variant_sources: cachedFusionEntry?.installed_variant_sources || [],
          visuals: {
            ...(builtFusionEntry.visuals || {}),
            ...(cachedFusionEntry?.visuals?.front ? { front: cachedFusionEntry.visuals.front } : {}),
            ...(cachedFusionEntry?.visuals?.back ? { back: cachedFusionEntry.visuals.back } : {}),
            ...(cachedFusionEntry?.visuals?.icon ? { icon: cachedFusionEntry.visuals.icon } : {})
          }
        }
      : cachedFusionEntry;
    if (fusionEntry) {
      state.catalogDetailErrors.delete(normalizedId);
      state.syntheticDexEntries.set(normalizedId, fusionEntry);
      renderDexSpeciesList();
      renderPokedexPanels();
      renderLivePreview();
    }
    return fusionEntry;
  }

  if (state.pendingCatalogDetails.has(normalizedId)) {
    return state.pendingCatalogDetails.get(normalizedId);
  }

  state.catalogDetailErrors.delete(normalizedId);
  const pending = fetchJson(`/api/catalog-species?id=${encodeURIComponent(normalizedId)}`, { allowError: true })
    .then((result) => {
      if (!result.ok || !result.data?.species) {
        throw new Error(result.data?.error || `Couldn't load full data for ${normalizedId}.`);
      }
      return mergeCatalogSpeciesDetail(result.data.species);
    })
    .then((entry) => {
      if (entry) {
        renderDexSpeciesList();
        renderPokedexPanels();
        renderLivePreview();
      }
      return entry;
    })
    .catch((error) => {
      const message = error?.message || `Couldn't load full data for ${normalizedId}.`;
      state.catalogDetailErrors.set(normalizedId, message);
      if (!options.silent) {
        showMessage(message, "error");
      }
      if (normalizeLookupValue(selectedDexEntry()?.id) === normalizedId) {
        renderPokedexPanels();
        renderLivePreview();
      }
      return current;
    })
    .finally(() => {
      state.pendingCatalogDetails.delete(normalizedId);
    });

  state.pendingCatalogDetails.set(normalizedId, pending);
  return pending;
}

async function refreshDexFusionPreview(options = {}) {
  const normalizedHeadId = normalizeLookupValue(state.fusionBuilder.headId);
  const normalizedBodyId = normalizeLookupValue(state.fusionBuilder.bodyId);
  const headEntry = fusionComponentEntryById(normalizedHeadId);
  const bodyEntry = fusionComponentEntryById(normalizedBodyId);
  if (!headEntry || !bodyEntry) {
    state.fusionBuilder.preview = null;
    state.fusionBuilder.error = (normalizedHeadId || normalizedBodyId) ? "Choose both a fusion head and a fusion body from the installed species list." : "";
    state.fusionBuilder.loading = false;
    renderDexFusionBuilder();
    return null;
  }

  state.fusionBuilder.loading = true;
  renderDexFusionBuilder();
  let resolvedHead = headEntry;
  let resolvedBody = bodyEntry;
  if (options.ensureDetail) {
    resolvedHead = await ensureDexSpeciesDetail(headEntry.id, { silent: options.silent !== false }) || headEntry;
    resolvedBody = await ensureDexSpeciesDetail(bodyEntry.id, { silent: options.silent !== false }) || bodyEntry;
  }

  const basePreview = buildFusionSpeciesEntry(resolvedHead, resolvedBody);
  const slicePayload = getCachedFusionSlice(currentFusionSliceRequest());
  const sliceEntry = slicePayload?.entries?.find((entry) => Number(entry.body_dex || 0) === Number(resolvedBody.id_number || 0)) || null;
  state.fusionBuilder.preview = basePreview
    ? {
        ...basePreview,
        installed_variant_count: Number(sliceEntry?.variant_count || 0),
        visuals: {
          ...(basePreview.visuals || {}),
          ...(sliceEntry?.preview_path ? { front: sliceEntry.preview_path } : {}),
          ...(sliceEntry?.preview_path && !basePreview.visuals?.back ? { back: sliceEntry.preview_path } : {})
        }
      }
    : null;
  state.fusionBuilder.error = state.fusionBuilder.preview ? "" : "The selected fusion source couldn't be built from the current catalog data.";
  state.fusionBuilder.loading = false;
  renderDexFusionBuilder();
  return state.fusionBuilder.preview;
}

function handleDexFusionBuilderInput() {
  state.fusionBuilder.headId = normalizeLookupValue(document.getElementById("dexFusionHead").value);
  state.fusionBuilder.bodyId = normalizeLookupValue(document.getElementById("dexFusionBody").value);
  state.dexCache.fusionEntriesSignature = "";
  refreshDexFusionPreview({ ensureDetail: false, silent: true }).catch(() => {});
  ensureFusionSliceAvailable({ silent: true, refresh: true }).catch(() => {});
  if (state.dexCatalogScope === "fusion") {
    renderDexSpeciesList();
    renderPokedexPanels();
    renderLivePreview();
  }
}

function assignSelectedDexSpeciesToFusionSlot(slot) {
  const entry = selectedDexEntry();
  if (!entry) {
    showMessage("Select a Pokédex species first.", "error");
    return;
  }
  if (!fusionComponentEntryById(entry.id)) {
    showMessage("That entry can't be used as a fusion component in this builder.", "error");
    return;
  }
  if (slot === "head") {
    state.fusionBuilder.headId = entry.id;
    document.getElementById("dexFusionHead").value = entry.id;
  } else {
    state.fusionBuilder.bodyId = entry.id;
    document.getElementById("dexFusionBody").value = entry.id;
  }
  state.dexCache.fusionEntriesSignature = "";
  refreshDexFusionPreview({ ensureDetail: false, silent: true }).catch(() => {});
  if (state.dexCatalogScope !== "fusion") {
    setDexCatalogScope("fusion");
  } else {
    ensureFusionSliceAvailable({ silent: true, refresh: true }).catch(() => {});
    renderDexSpeciesList();
    renderPokedexPanels();
    renderLivePreview();
  }
}

function swapDexFusionBuilder() {
  const currentHead = normalizeLookupValue(document.getElementById("dexFusionHead").value);
  const currentBody = normalizeLookupValue(document.getElementById("dexFusionBody").value);
  document.getElementById("dexFusionHead").value = currentBody;
  document.getElementById("dexFusionBody").value = currentHead;
  handleDexFusionBuilderInput();
}

function clearDexFusionBuilder() {
  state.fusionBuilder = {
    headId: "",
    bodyId: "",
    preview: null,
    loading: false,
    error: ""
  };
  document.getElementById("dexFusionHead").value = "";
  document.getElementById("dexFusionBody").value = "";
  state.dexCache.fusionEntriesSignature = "";
  renderDexFusionBuilder();
  if (state.dexCatalogScope === "fusion") {
    renderDexSpeciesList();
    renderPokedexPanels();
    renderLivePreview();
  }
}

async function cloneFusionBuilderSpecies() {
  const preview = await refreshDexFusionPreview({ ensureDetail: true, silent: false });
  if (!preview) {
    showMessage(state.fusionBuilder.error || "Choose a valid fusion head and body first.", "error");
    return;
  }
  newSpeciesDraft(preview, {
    kind: "regional_variant",
    nameSuffix: " Variant",
    templateLabel: `Regional variant of ${preview.name}`,
    variantScope: "single_species",
    variantFamily: ""
  });
  showMessage(`Started a regional variant draft from the ${preview.name} fusion. It begins as a single-species variant, so the source fusion and its parent line stay untouched unless you expand it.`, "success");
}

function comparedDexEntries() {
  return {
    left: speciesEntryById(state.dexCompareIds.left) || null,
    right: speciesEntryById(state.dexCompareIds.right) || null
  };
}

function renderPokedexPanels() {
  const entry = selectedDexEntry();
  queueDexSpeciesDetail(entry, { silent: true });
  renderDexOverviewPanel(entry);
  renderDexStatsPanel(entry);
  renderDexMovesPanel(entry);
  renderDexEvolutionPanel(entry);
  renderDexComparePanel();
  renderDexFusionBuilder();
}

function renderDexOverviewPanel(entry) {
  const panel = document.getElementById("dexOverviewPanel");
  if (!entry) {
    panel.innerHTML = `<p class="muted-copy">No Pokédex data is available yet.</p>`;
    return;
  }
  const variantLibrary = renderVisualVariantLibraryHtml(entry, { context: "dex" });
  panel.innerHTML = `
    <div class="panel-heading">
      <h3>${escapeHtml(entry.name)}</h3>
      <p>${escapeHtml(entry.category)} · ${escapeHtml(isFusionSymbol(entry.id) ? "Fusion Slice" : (entry.source === "base_game" ? "Base Game" : titleizeToken(entry.kind)))}</p>
    </div>
    <div class="overview-grid">
      <article class="info-card">
        <h4>Identity</h4>
        <div class="type-chip-row">${renderTypeChips(entry.types)}</div>
        <div class="key-value-list">
          ${renderKeyValueRow("Dex Number", formatDexNumber(entry.id_number))}
          ${renderKeyValueRow("Generation", entry.generation || "Unknown")}
          ${renderKeyValueRow("Growth Rate", entry.growth_rate?.name || "Unknown")}
          ${renderKeyValueRow("Gender Ratio", entry.gender_ratio?.name || "Unknown")}
          ${renderKeyValueRow("Egg Groups", entry.egg_groups.map((group) => group.name).join(", ") || "None")}
        </div>
      </article>
      <article class="info-card">
        <h4>Traits</h4>
        <div class="key-value-list">
          ${renderKeyValueRow("Abilities", entry.abilities.map((ability) => ability.name).join(", ") || "None")}
          ${renderKeyValueRow("Hidden Ability", entry.hidden_abilities.map((ability) => ability.name).join(", ") || "None")}
          ${renderKeyValueRow("Height", entry.height || "Unknown")}
          ${renderKeyValueRow("Weight", entry.weight || "Unknown")}
          ${renderKeyValueRow("Fusion Rule", titleizeToken(entry.fusion_rule))}
        </div>
      </article>
    </div>
    <article class="info-card">
      <h4>Pokédex Entry</h4>
      <p>${escapeHtml(entry.pokedex_entry || "No Pokédex entry is available.")}</p>
    </article>
    <article class="info-card">
      ${variantLibrary}
    </article>
  `;
  ensureVisualVariantsAvailable(entry, { silent: true }).catch(() => {});
}

function visualVariantCacheKey(entry) {
  const entryId = normalizeLookupValue(entry?.id);
  const idNumber = Number(entry?.id_number || 0);
  if (!entryId && !idNumber) {
    return "";
  }
  return `${entryId}::${idNumber}`;
}

function normalizeVisualVariantPayload(data) {
  if (!data || typeof data !== "object") {
    return null;
  }
  return {
    ok: Boolean(data.ok),
    entry: data.entry || {},
    variants: {
      front: Array.isArray(data.variants?.front) ? data.variants.front : [],
      back: Array.isArray(data.variants?.back) ? data.variants.back : [],
      icon: Array.isArray(data.variants?.icon) ? data.variants.icon : []
    }
  };
}

function getCachedVisualVariants(entry) {
  const cacheKey = visualVariantCacheKey(entry);
  if (!cacheKey) {
    return null;
  }
  return state.visualVariantCache.get(cacheKey) || null;
}

async function ensureVisualVariantsAvailable(entry, options = {}) {
  const cacheKey = visualVariantCacheKey(entry);
  if (!cacheKey) {
    return null;
  }
  if (!options.refresh && state.visualVariantCache.has(cacheKey)) {
    return state.visualVariantCache.get(cacheKey);
  }
  if (state.pendingVisualVariantRequests.has(cacheKey)) {
    return state.pendingVisualVariantRequests.get(cacheKey);
  }

  const query = new URLSearchParams();
  query.set("id", normalizeLookupValue(entry.id));
  query.set("id_number", String(Number(entry.id_number || 0)));
  const pending = fetchJson(`/api/visual-variants?${query.toString()}`, { allowError: true, timeoutMs: 15000 })
    .then((result) => {
      if (!result.ok || !result.data?.ok) {
        throw new Error(result.data?.error || `Couldn't load installed sprite variants for ${entry.name || entry.id}.`);
      }
      const payload = normalizeVisualVariantPayload(result.data);
      state.visualVariantCache.set(cacheKey, payload);
      return payload;
    })
    .then((payload) => {
      if (normalizeLookupValue(selectedDexEntry()?.id) === normalizeLookupValue(entry.id)) {
        renderPokedexPanels();
      }
      const draftSource = currentDraftVisualSourceEntry();
      if (normalizeLookupValue(draftSource?.id) === normalizeLookupValue(entry.id)) {
        renderDraftVisualVariantPanel();
      }
      return payload;
    })
    .catch((error) => {
      if (!options.silent) {
        showMessage(error?.message || `Couldn't load installed sprite variants for ${entry.name || entry.id}.`, "error");
      }
      return null;
    })
    .finally(() => {
      state.pendingVisualVariantRequests.delete(cacheKey);
    });

  state.pendingVisualVariantRequests.set(cacheKey, pending);
  return pending;
}

function totalVisualVariantCount(payload) {
  return ["front", "back", "icon"].reduce((sum, kind) => sum + (payload?.variants?.[kind]?.length || 0), 0);
}

function renderVariantCardsHtml(kind, items, options = {}) {
  if (!items || items.length === 0) {
    return `
      <div class="variant-empty">
        <span>No ${escapeHtml(titleizeToken(kind))} variants found.</span>
      </div>
    `;
  }
  return items.map((item) => {
    const action = options.selectable
      ? `<button class="ghost-button small" type="button" data-variant-kind="${escapeAttribute(kind)}" data-variant-path="${escapeAttribute(item.path)}" data-variant-label="${escapeAttribute(item.label || item.file_name || titleizeToken(kind))}">Use for ${escapeHtml(titleizeToken(kind))}</button>`
      : `<span class="status-chip neutral">${escapeHtml(item.source || "Installed")}</span>`;
    return `
      <article class="variant-card">
        <img src="${escapeAttribute(normalizeAssetCandidate(item.path) || BLANK_IMAGE)}" alt="${escapeAttribute(item.label || item.file_name || titleizeToken(kind))}" loading="lazy" decoding="async">
        <div class="variant-card-copy">
          <strong>${escapeHtml(item.label || item.file_name || titleizeToken(kind))}</strong>
          <small>${escapeHtml(item.file_name || item.path || "")}</small>
        </div>
        <div class="variant-card-actions">
          ${action}
        </div>
      </article>
    `;
  }).join("");
}

function renderVariantLibrarySectionsHtml(payload, options = {}) {
  const labels = {
    front: "Front Sprites",
    back: "Back Sprites",
    icon: "Icons"
  };
  return ["front", "back", "icon"].map((kind) => `
    <section class="variant-library-group">
      <div class="section-heading compact">
        <div>
          <h4>${escapeHtml(labels[kind])}</h4>
          <p>${escapeHtml(String(payload?.variants?.[kind]?.length || 0))} installed option${(payload?.variants?.[kind]?.length || 0) === 1 ? "" : "s"} available.</p>
        </div>
      </div>
      <div class="variant-card-grid">
        ${renderVariantCardsHtml(kind, payload?.variants?.[kind] || [], options)}
      </div>
    </section>
  `).join("");
}

function renderVisualVariantLibraryHtml(entry, options = {}) {
  const payload = getCachedVisualVariants(entry);
  const selectionKind = isFusionSymbol(entry?.id) ? "Fusion Slice" : "Installed Species";
  if (!payload) {
    return `
      <div class="section-heading compact">
        <div>
          <h4>Installed Art Library</h4>
          <p>${escapeHtml(selectionKind)} art choices load on demand so the Pokédex stays fast.</p>
        </div>
      </div>
      <div class="empty-state">Scanning installed sprite options for ${escapeHtml(entry?.name || "this entry")}.</div>
    `;
  }
  return `
    <div class="section-heading compact">
      <div>
        <h4>Installed Art Library</h4>
        <p>${escapeHtml(selectionKind)} choices for ${escapeHtml(entry?.name || "this entry")}.</p>
      </div>
      <span class="status-chip neutral">${escapeHtml(String(totalVisualVariantCount(payload)))} assets</span>
    </div>
    ${renderVariantLibrarySectionsHtml(payload, { selectable: options.context === "draft" })}
  `;
}

function currentDraftVisualSourceEntry() {
  const payload = currentDraftPayload();
  const regionalSource = fusionSourceStateFromPayload(payload);
  if (payload.kind === "regional_variant" && regionalSource.ready) {
    return speciesEntryById(regionalSource.baseSpeciesId || regionalSource.fusionSymbol || payload.base_species);
  }
  if (document.getElementById("existingId").value) {
    const savedEntry = state.species.find((entry) => entry.id === document.getElementById("existingId").value);
    if (savedEntry) {
      return normalizeCreatorSpeciesEntry(savedEntry);
    }
  }
  return null;
}

function renderDraftVisualVariantPanel(options = {}) {
  const container = document.getElementById("draftVisualVariantGallery");
  if (!container) {
    return;
  }
  const sourceEntry = currentDraftVisualSourceEntry();
  if (!sourceEntry) {
    container.className = "variant-gallery-empty empty-state";
    container.innerHTML = "Choose a base Pokédex species or a fusion source to load installed art choices here.";
    return;
  }
  const payload = getCachedVisualVariants(sourceEntry);
  if (!payload) {
    container.className = "variant-gallery-loading empty-state";
    container.innerHTML = `Scanning installed art choices for ${escapeHtml(sourceEntry.name)}.`;
    ensureVisualVariantsAvailable(sourceEntry, { silent: true, refresh: options.refresh }).catch(() => {});
    return;
  }
  container.className = "variant-library";
  container.innerHTML = renderVariantLibrarySectionsHtml(payload, { selectable: true });
  if (options.refresh) {
    ensureVisualVariantsAvailable(sourceEntry, { silent: true, refresh: true }).catch(() => {});
  }
}

function renderDexStatsPanel(entry) {
  const panel = document.getElementById("dexStatsPanel");
  if (!entry) {
    panel.innerHTML = `<p class="muted-copy">No species selected.</p>`;
    return;
  }
  const role = computeRoleEstimate(entry.base_stats);
  const coverage = describeTypeCoverage(entry.types);
  panel.innerHTML = `
    <div class="panel-heading">
      <h3>Stat Profile</h3>
      <p>${escapeHtml(role.title)} · BST ${escapeHtml(String(entry.bst))}</p>
    </div>
    <div class="stats-compare-grid">
      <article class="info-card">
        <h4>Base Stats</h4>
        <div class="stat-bar-list">${renderStatsBars(entry.base_stats)}</div>
      </article>
      <article class="info-card">
        <h4>Battle Notes</h4>
        <div class="key-value-list">
          ${renderKeyValueRow("Role", role.title)}
          ${renderKeyValueRow("Summary", role.summary)}
          ${renderKeyValueRow("Offensive Coverage", coverage.offense)}
          ${renderKeyValueRow("Defensive Profile", coverage.defense)}
          ${renderKeyValueRow("Weaknesses", coverage.weaknesses.join(", ") || "None")}
          ${renderKeyValueRow("Resistances", coverage.resistances.join(", ") || "None")}
        </div>
      </article>
    </div>
  `;
}

function renderDexMovesPanel(entry) {
  const panel = document.getElementById("dexMovesPanel");
  if (!entry) {
    panel.innerHTML = `<p class="muted-copy">No species selected.</p>`;
    return;
  }
  const normalizedId = normalizeLookupValue(entry.id);
  const detailPending = state.pendingCatalogDetails.has(normalizedId);
  const detailError = state.catalogDetailErrors.get(normalizedId);
  if (entry.detail_level !== "full") {
    if (!detailPending && !detailError) {
      queueDexSpeciesDetail(entry, { silent: true });
    }
    if (detailError) {
      panel.innerHTML = `
        <div class="panel-heading">
          <h3>Learnsets</h3>
          <p>Detailed move data for ${escapeHtml(entry.name)} could not be loaded from the local catalog.</p>
        </div>
        <div class="guide-panel compact-state">
          <p class="muted-copy">${escapeHtml(detailError)}</p>
          <div class="inline-actions">
            <button id="retryDexMovesLoadBtn" class="ghost-button small" type="button">Retry Detail Load</button>
          </div>
        </div>
      `;
      document.getElementById("retryDexMovesLoadBtn")?.addEventListener("click", () => {
        state.catalogDetailErrors.delete(normalizedId);
        renderPokedexPanels();
        ensureDexSpeciesDetail(entry.id, { silent: false }).catch(() => {});
      });
      return;
    }
    panel.innerHTML = `
      <div class="panel-heading">
        <h3>Learnsets</h3>
        <p>Loading the full learnset and move compatibility for ${escapeHtml(entry.name)}.</p>
      </div>
      <div class="guide-panel compact-state">
        <p class="muted-copy">The Pokédex overview is ready. Level-up, TM, tutor, and egg move data are loading in the background.</p>
        <p class="muted-copy">You can keep browsing while the creator fills in the full species detail file.</p>
      </div>
    `;
    return;
  }
  panel.innerHTML = `
    <div class="panel-heading">
      <h3>Learnsets</h3>
      <p>Level-up moves, TM compatibility, tutoring, and egg inheritance.</p>
    </div>
    <div class="move-columns">
      ${renderMoveColumn("Level-Up", entry.moves, true)}
      ${renderMoveColumn("TM", entry.tm_moves)}
      ${renderMoveColumn("Tutor", entry.tutor_moves)}
    </div>
    <div class="move-columns">
      ${renderMoveColumn("Egg", entry.egg_moves)}
      <article class="info-card">
        <h4>Abilities</h4>
        <div class="move-list">
          ${(entry.abilities.length ? entry.abilities : [{ name: "No ability data." }]).map((ability) => `<div class="move-pill"><strong>${escapeHtml(ability.name)}</strong><span>${escapeHtml(ability.description || ability.id || "")}</span></div>`).join("")}
        </div>
      </article>
      <article class="info-card">
        <h4>Flavor Notes</h4>
        <p>${escapeHtml(entry.design_notes || entry.template_source_label || "No extra design notes were stored for this species.")}</p>
      </article>
    </div>
  `;
}

function renderDexEvolutionPanel(entry) {
  const panel = document.getElementById("dexEvolutionsPanel");
  if (!entry) {
    panel.innerHTML = `<p class="muted-copy">No species selected.</p>`;
    return;
  }
  panel.innerHTML = `
    <div class="panel-heading">
      <h3>Evolution Data</h3>
      <p>Family tree and direct evolution requirements.</p>
    </div>
    <div class="family-columns">
      <article class="info-card">
        <h4>Family Members</h4>
        <div class="family-list">
          ${familyNodes(entry).map((node) => `<div class="family-pill"><strong>${escapeHtml(node.name)}</strong><span>No. ${escapeHtml(formatDexNumber(node.id_number))}</span></div>`).join("")}
        </div>
      </article>
      <article class="info-card">
        <h4>Direct Evolutions</h4>
        <div class="family-list">
          ${entry.evolutions.length ? entry.evolutions.map((evo) => `<div class="family-pill"><strong>${escapeHtml(evo.species?.name || "Unknown")}</strong><span>${escapeHtml(evolutionRequirementText(evo))}</span></div>`).join("") : `<p class="muted-copy">No forward evolutions stored.</p>`}
        </div>
      </article>
    </div>
  `;
}

function renderDexComparePanel() {
  const panel = document.getElementById("dexComparePanel");
  const { left, right } = comparedDexEntries();
  if (!left || !right) {
    panel.innerHTML = `<p class="muted-copy">Choose Compare A and Compare B from the Pokédex view to render a side-by-side comparison.</p>`;
    return;
  }
  panel.innerHTML = `
    <div class="panel-heading">
      <h3>Compare Species</h3>
      <p>${escapeHtml(left.name)} vs ${escapeHtml(right.name)}</p>
    </div>
    <div class="compare-grid">
      ${renderCompareCard(left)}
      ${renderCompareCard(right)}
    </div>
  `;
}

function renderCompareCard(entry) {
  return `
    <article class="compare-card">
      <div class="battle-topline">
        <strong>${escapeHtml(entry.name)}</strong>
        <span>No. ${escapeHtml(formatDexNumber(entry.id_number))}</span>
      </div>
      <div class="type-chip-row">${renderTypeChips(entry.types)}</div>
      <div class="stat-bar-list">${renderStatsBars(entry.base_stats)}</div>
      <div class="key-value-list">
        ${renderKeyValueRow("BST", entry.bst)}
        ${renderKeyValueRow("Abilities", entry.abilities.map((ability) => ability.name).join(", ") || "None")}
        ${renderKeyValueRow("Fusion Rule", titleizeToken(entry.fusion_rule))}
      </div>
    </article>
  `;
}

function renderDexFusionBuilder() {
  const panel = document.getElementById("dexFusionBuilderPanel");
  if (!panel) {
    return;
  }
  const headEntry = fusionComponentEntryById(state.fusionBuilder.headId);
  const bodyEntry = fusionComponentEntryById(state.fusionBuilder.bodyId);
  const preview = state.fusionBuilder.preview;
  const ready = Boolean(preview);
  const sliceRequest = currentFusionSliceRequest();
  const slicePayload = getCachedFusionSlice(sliceRequest);
  const slicePending = sliceRequest?.cacheKey ? state.pendingFusionSliceRequests.has(sliceRequest.cacheKey) : false;
  if (sliceRequest?.headDex && !slicePayload && !slicePending) {
    ensureFusionSliceAvailable({ request: sliceRequest, silent: true }).catch(() => {});
  }
  const sliceCount = Number(slicePayload?.total_entries || 0);
  const sliceBadge = ready
    ? "Fusion Ready"
    : slicePending
      ? "Scanning Slice"
      : headEntry
        ? `${sliceCount} Installed`
        : "Pick A Head";
  panel.innerHTML = `
    <div class="panel-heading compact">
      <div>
        <h3>Fusion Variant Builder</h3>
        <p>Use the Pokédex list to pick a head and body, preview one installed fusion, then clone it into a regional-variant draft.</p>
      </div>
      <span class="summary-badge ${ready ? "soft" : "neutral"}">${escapeHtml(sliceBadge)}</span>
    </div>
    <div class="field-grid two-columns fusion-builder-fields">
      <label class="field">
        <span>Fusion Head</span>
        <input id="dexFusionHead" type="text" list="species-options" placeholder="PIKACHU" value="${escapeAttribute(state.fusionBuilder.headId)}">
      </label>
      <label class="field">
        <span>Fusion Body</span>
        <input id="dexFusionBody" type="text" list="species-options" placeholder="CHARMANDER" value="${escapeAttribute(state.fusionBuilder.bodyId)}">
      </label>
    </div>
    <div class="inline-actions fusion-builder-actions">
      <button id="swapFusionPartsBtn" class="ghost-button small" type="button">Swap</button>
      <button id="clearFusionBuilderBtn" class="ghost-button small" type="button">Clear</button>
      <button id="createFusionVariantBtn" class="primary-button small" type="button"${ready ? "" : " disabled"}>Create Fusion Regional Variant</button>
    </div>
    <div class="fusion-builder-preview ${ready ? "" : "is-empty"}">
      ${ready ? `
        <div class="fusion-builder-preview-topline">
          <strong>${escapeHtml(preview.name)}</strong>
          <span>No. ${escapeHtml(formatDexNumber(preview.id_number))}</span>
        </div>
        <div class="fusion-builder-preview-grid">
          <img id="dexFusionPreviewImage" class="fusion-builder-preview-image" alt="Fusion source preview">
          <div class="fusion-builder-preview-copy">
            <div class="type-chip-row">${renderTypeChips(preview.types)}</div>
            <p><strong>Head:</strong> ${escapeHtml(headEntry?.name || "Unknown")}</p>
            <p><strong>Body:</strong> ${escapeHtml(bodyEntry?.name || "Unknown")}</p>
            <p><strong>BST:</strong> ${escapeHtml(String(preview.bst || calculateBst(preview.base_stats)))}</p>
            <p><strong>Installed Slice:</strong> ${escapeHtml(slicePending ? "Scanning..." : String(sliceCount))} fusion option${sliceCount === 1 ? "" : "s"} currently on disk for this head.</p>
            <p>${escapeHtml(preview.template_source_label || "Fusion source preview ready.")}</p>
          </div>
        </div>
      ` : `
        <p class="muted-copy">${escapeHtml(
          state.fusionBuilder.loading
            ? "Building the fusion preview..."
            : (state.fusionBuilder.error
                || (!headEntry && !bodyEntry
                    ? "Pick a species on the left, then use “Use As Fusion Head” and “Use As Fusion Body” to stage the source."
                    : (!headEntry
                        ? "Choose the fusion head first."
                        : (!bodyEntry ? "Choose the fusion body next." : "The creator is waiting for the exact fusion preview."))))
        )}</p>
      `}
    </div>
  `;

  ["dexFusionHead", "dexFusionBody"].forEach((id) => {
    const element = document.getElementById(id);
    element.addEventListener("input", handleDexFusionBuilderInput);
    element.addEventListener("change", handleDexFusionBuilderInput);
  });
  document.getElementById("swapFusionPartsBtn").addEventListener("click", swapDexFusionBuilder);
  document.getElementById("clearFusionBuilderBtn").addEventListener("click", clearDexFusionBuilder);
  document.getElementById("createFusionVariantBtn").addEventListener("click", cloneFusionBuilderSpecies);

  if (ready) {
    setImageSourceWithFallback(document.getElementById("dexFusionPreviewImage"), previewImageCandidates(preview));
  }
}

function renderStarterEditor() {
  const options = allSpeciesOptions();
  ["starterSpecies1", "starterSpecies2", "starterSpecies3"].forEach((selectId) => {
    populateSelect(document.getElementById(selectId), options, { allowBlank: true, blankLabel: "Choose species" });
  });

  const starterSet = state.creatorStarterSet;
  setValue("starterLabel", starterSet?.label || "My Custom Fakemon Trio");
  setChecked("starterActivate", Boolean(starterSet?.intro_default));
  setValue("starterSpecies1", starterSet?.species?.[0] || "");
  setValue("starterSpecies2", starterSet?.species?.[1] || "");
  setValue("starterSpecies3", starterSet?.species?.[2] || "");
  refreshStarterCounterOptions();
}

function refreshStarterCounterOptions() {
  const chosenSpecies = [
    document.getElementById("starterSpecies1").value,
    document.getElementById("starterSpecies2").value,
    document.getElementById("starterSpecies3").value
  ].filter(Boolean);
  const currentMap = state.creatorStarterSet?.rival_counterpick || {};
  ["starterCounter1", "starterCounter2", "starterCounter3"].forEach((selectId, index) => {
    const select = document.getElementById(selectId);
    const sourceSpecies = document.getElementById(`starterSpecies${index + 1}`).value;
    const currentValue = currentMap[sourceSpecies] || select.value;
    const entries = chosenSpecies
      .filter((speciesId) => speciesId && speciesId !== sourceSpecies)
      .map((speciesId) => {
        const entry = mergedDexEntries().find((dexEntry) => dexEntry.id === speciesId);
        return entry ? { id: entry.id, name: entry.name } : { id: speciesId, name: speciesId };
      });
    populateSelect(select, entries, { allowBlank: true, blankLabel: "Auto" });
    if (currentValue && [...select.options].some((option) => option.value === currentValue)) {
      select.value = currentValue;
    }
  });
}

function defaultImporterConfig(source = {}) {
  const config = source && typeof source === "object" ? { ...source } : {};
  return {
    ...config,
    allow_partial_entries: Boolean(config.allow_partial_entries),
    require_backsprite: config.require_backsprite !== false,
    require_icon: config.require_icon !== false,
    overwrite_existing_species: Boolean(config.overwrite_existing_species),
    strict_permission_mode: config.strict_permission_mode !== false,
    dry_run_only: config.dry_run_only !== false,
    apply_bundle_to_framework: Boolean(config.apply_bundle_to_framework)
  };
}

function ensureImporterDraftConfig() {
  if (!state.importerDraft.config) {
    state.importerDraft.config = defaultImporterConfig(state.importer?.config || {});
  }
  return state.importerDraft.config;
}

function syncImporterDraftFromState() {
  const importer = state.importer || {};
  state.importerDraft = {
    manifestText: importer.manifest_text || "{\n  \"sources\": []\n}\n",
    config: defaultImporterConfig(importer.config || {})
  };
}

function collectImporterConfigDraft(mode = "save") {
  const config = { ...ensureImporterDraftConfig() };
  if (mode === "dry_run") {
    config.dry_run_only = true;
    config.apply_bundle_to_framework = false;
  } else if (mode === "apply") {
    config.dry_run_only = false;
    config.apply_bundle_to_framework = true;
  }
  return config;
}

async function refreshImporterState(options = {}) {
  if (state.importerLoading) {
    return;
  }
  state.importerLoading = true;
  try {
    const result = await fetchJson("/api/importer/state", { allowError: true });
    if (!result.ok) {
      if (!options.silent) {
        showMessage(result.data?.error || "The importer state could not be loaded.", "error");
      }
      return;
    }
    state.importer = result.data.importer || null;
    syncImporterDraftFromState();
    renderImporterEditor();
    renderImporterResults();
    renderIntegrationSummary();
  } catch (error) {
    if (!options.silent) {
      showMessage(error.message, "error");
    }
  } finally {
    state.importerLoading = false;
  }
}

function renderImporterEditor() {
  const manifestEditor = document.getElementById("importManifestEditor");
  if (!manifestEditor) {
    return;
  }

  const importer = state.importer || {};
  const config = ensureImporterDraftConfig();
  if (manifestEditor.value !== state.importerDraft.manifestText) {
    manifestEditor.value = state.importerDraft.manifestText || "{\n  \"sources\": []\n}\n";
  }

  setChecked("importStrictPermission", config.strict_permission_mode !== false);
  setChecked("importAllowPartial", Boolean(config.allow_partial_entries));
  setChecked("importRequireBack", config.require_backsprite !== false);
  setChecked("importRequireIcon", config.require_icon !== false);
  setChecked("importOverwriteExisting", Boolean(config.overwrite_existing_species));

  const paths = importer.paths || {};
  document.getElementById("importPathsPanel").innerHTML = `
    ${renderKeyValueRow("Manifest", paths.manifest || "Mods/custom_species_framework/importer/config/source_manifest.json")}
    ${renderKeyValueRow("Config", paths.config || "Mods/custom_species_framework/importer/config/importer_config.json")}
    ${renderKeyValueRow("Output Root", paths.output_root || "Mods/custom_species_framework/importer/import_output")}
    ${renderKeyValueRow("Bundle Root", paths.bundle_root || "Mods/custom_species_framework/importer/import_output/framework_bundle")}
  `;

  const summary = importer.summary || {};
  const report = importer.report || {};
  const applyResult = report.apply_result || {};
  const generatedAt = summary.generated_at || "No import run yet";
  const modeLabel = summary.apply_bundle ? "Applied To Framework" : (summary.dry_run_only === false ? "Bundle Prep" : "Dry Run Only");
  document.getElementById("importRunSummary").innerHTML = `
    ${renderKeyValueRow("Last Run", generatedAt)}
    ${renderKeyValueRow("Mode", modeLabel)}
    ${renderKeyValueRow("Discovered", String(summary.discovered || 0))}
    ${renderKeyValueRow("Ready", String(summary.ready || 0))}
    ${renderKeyValueRow("Review", String(summary.review || 0))}
    ${renderKeyValueRow("Rejected", String(summary.rejected || 0))}
    ${renderKeyValueRow("Applied Files", String((applyResult.applied_files || []).length))}
    ${renderKeyValueRow("Conflicts", String((applyResult.conflicts || []).length))}
  `;

  const logTail = Array.isArray(importer.log_tail) ? importer.log_tail : [];
  document.getElementById("importLogTail").textContent = logTail.length
    ? logTail.join("\n")
    : "Importer log output will appear here after the first dry run.";
}

function renderImporterResults() {
  const importer = state.importer || {};
  const summary = importer.summary || {};
  const speciesData = Array.isArray(importer.species_data) ? importer.species_data : [];
  const readyEntries = speciesData.filter((entry) => importerEntryStatus(entry) === "ready");
  const reviewEntries = speciesData.filter((entry) => {
    const status = importerEntryStatus(entry);
    return status !== "ready" && status !== "rejected";
  });
  const rejectedItems = Array.isArray(importer.rejected_items) ? importer.rejected_items : [];
  const creditsItems = Array.isArray(importer.credits_manifest) ? importer.credits_manifest : [];

  const reviewSummary = document.getElementById("importReviewSummary");
  if (reviewSummary) {
    reviewSummary.innerHTML = `
      <div class="status-chip ready">Ready <strong>${summary.ready || readyEntries.length}</strong></div>
      <div class="status-chip review">Review <strong>${summary.review || reviewEntries.length}</strong></div>
      <div class="status-chip rejected">Rejected <strong>${summary.rejected || rejectedItems.length}</strong></div>
      <div class="status-chip neutral">${escapeHtml(summary.apply_bundle ? "Last run applied files" : "Dry run staging only")}</div>
    `;
  }

  renderImportedSpeciesCards("importReadyList", readyEntries, {
    emptyText: "Run a dry import to stage approved Fakemon packs here."
  });
  renderImportedSpeciesCards("importReviewList", reviewEntries, {
    emptyText: "Questionable or incomplete packs will land here with validation details."
  });
  renderRejectedImportCards("importRejectedList", rejectedItems);
  renderCreditsManifestCards("importCreditsList", creditsItems);
}

function importerEntryStatus(entry) {
  return String(entry?.integration?.insert_status || entry?.insert_status || "pending").trim().toLowerCase();
}

function renderImportedSpeciesCards(containerId, entries, options = {}) {
  const container = document.getElementById(containerId);
  if (!container) {
    return;
  }
  if (!entries.length) {
    container.innerHTML = `<div class="empty-state">${escapeHtml(options.emptyText || "No importer entries are available yet.")}</div>`;
    return;
  }
  container.innerHTML = entries.map((entry) => renderImportedSpeciesCard(entry)).join("");
  container.querySelectorAll("[data-import-to-creator]").forEach((button) => {
    button.addEventListener("click", () => openImportedSpeciesInCreator(button.dataset.importToCreator));
  });
}

function renderImportedSpeciesCard(entry) {
  const gameData = entry.game_data || {};
  const status = importerEntryStatus(entry);
  const validation = entry.validation || {};
  const errors = Array.isArray(validation.errors) ? validation.errors : [];
  const warnings = Array.isArray(validation.warnings) ? validation.warnings : [];
  const suggestions = Array.isArray(validation.suggestions) ? validation.suggestions : [];
  const insertErrors = Array.isArray(entry.integration?.insert_errors) ? entry.integration.insert_errors : [];
  const issueText = [...insertErrors, ...errors, ...warnings, ...suggestions].filter(Boolean);
  const assetKinds = Object.keys(entry.staged_assets || entry.assets || {});
  const frameworkSlot = entry.integration?.framework_slot ? `Slot ${entry.integration.framework_slot}` : "Pending";
  const types = uniqueTypes(gameData.types || []);
  const visibleName = entry.display_name || entry.species_name || entry.id || "Imported Species";
  const creator = entry.creator || "Unknown creator";
  const sourcePack = entry.source_pack || "Unknown pack";
  const permission = entry.usage_permission || "Permission notes missing";
  return `
    <article class="import-entry-card">
      <div class="import-entry-head">
        <div>
          <strong>${escapeHtml(visibleName)}</strong>
          <small>${escapeHtml(sourcePack)} · ${escapeHtml(creator)}</small>
        </div>
        <span class="status-chip ${escapeAttribute(status === "skipped_duplicate" ? "review" : status)}">${escapeHtml(titleizeToken(status))}</span>
      </div>
      <div class="type-chip-row">${renderTypeChips(types)}</div>
      <div class="key-value-list">
        ${renderKeyValueRow("Species Key", entry.integration?.framework_species_key || entry.id || "Pending")}
        ${renderKeyValueRow("Framework Slot", frameworkSlot)}
        ${renderKeyValueRow("Assets", assetKinds.length ? assetKinds.map(titleizeToken).join(", ") : "No staged assets")}
        ${renderKeyValueRow("Permission", permission)}
      </div>
      <p class="meta-copy">${escapeHtml(issueText[0] || entry.notes || entry.credit_text || "No extra review notes were stored for this import.")}</p>
      <div class="import-entry-actions">
        <div class="import-entry-meta">
          <span class="status-chip ${errors.length ? "error" : "neutral"}">Errors ${errors.length}</span>
          <span class="status-chip ${warnings.length ? "warning" : "neutral"}">Warnings ${warnings.length}</span>
          <span class="status-chip ${suggestions.length ? "neutral" : "neutral"}">Suggestions ${suggestions.length}</span>
        </div>
        <button class="ghost-button small" type="button" data-import-to-creator="${escapeAttribute(entry.id || "")}">Open In Creator</button>
      </div>
    </article>
  `;
}

function renderRejectedImportCards(containerId, entries) {
  const container = document.getElementById(containerId);
  if (!container) {
    return;
  }
  if (!entries.length) {
    container.innerHTML = `<div class="empty-state">Rejected items will appear here only when the importer finds unsafe permissions or invalid source files.</div>`;
    return;
  }
  container.innerHTML = entries.map((entry) => `
    <article class="import-entry-card">
      <div class="import-entry-head">
        <div>
          <strong>${escapeHtml(entry.species_name || "Unknown species")}</strong>
          <small>${escapeHtml(entry.source_pack || "Unknown pack")}</small>
        </div>
        <span class="status-chip rejected">Rejected</span>
      </div>
      <p class="meta-copy">${escapeHtml((entry.reasons || []).join(" | ") || "No rejection reason was recorded.")}</p>
      <p class="meta-copy">${escapeHtml((entry.files || []).join(", ") || "No file references were captured.")}</p>
    </article>
  `).join("");
}

function renderCreditsManifestCards(containerId, entries) {
  const container = document.getElementById(containerId);
  if (!container) {
    return;
  }
  if (!entries.length) {
    container.innerHTML = `<div class="empty-state">Credits manifests will appear here after the first approved pack run.</div>`;
    return;
  }
  container.innerHTML = entries.map((entry) => `
    <article class="import-entry-card">
      <div class="import-entry-head">
        <div>
          <strong>${escapeHtml(entry.species_name || "Imported species")}</strong>
          <small>${escapeHtml(entry.source_pack || "Unknown pack")} · ${escapeHtml(entry.creator || "Unknown creator")}</small>
        </div>
        <span class="status-chip neutral">Credit Ready</span>
      </div>
      <div class="key-value-list">
        ${renderKeyValueRow("Permission", entry.usage_permission || "Unspecified")}
        ${renderKeyValueRow("Source URL", entry.source_url || "Not provided")}
      </div>
      <p class="meta-copy">${escapeHtml(entry.credit_text || "No credit text was stored.")}</p>
    </article>
  `).join("");
}

function findImportedSpeciesEntry(importId) {
  return (state.importer?.species_data || []).find((entry) => entry.id === importId) || null;
}

function openImportedSpeciesInCreator(importId) {
  const importedEntry = findImportedSpeciesEntry(importId);
  if (!importedEntry) {
    showMessage(`Could not find importer entry ${importId}.`, "error");
    return;
  }
  const normalized = normalizeImportedSpeciesEntry(importedEntry);
  newSpeciesDraft(normalized, {
    nameSuffix: "",
    templateLabel: `${importedEntry.source_pack || "Imported Pack"} Intake`
  });
  showMessage(`Loaded ${normalized.name} from the importer into the creator studio.`, "success");
}

async function saveImporterWorkspace() {
  try {
    const result = await fetchJson("/api/importer/save", {
      fetchOptions: {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          manifest_text: state.importerDraft.manifestText || "{\n  \"sources\": []\n}\n",
          config: collectImporterConfigDraft("save")
        })
      }
    });
    state.importer = result.data.importer || state.importer;
    syncImporterDraftFromState();
    renderImporterEditor();
    renderImporterResults();
    renderIntegrationSummary();
    showMessage("Saved the importer workspace settings and manifest.", "success");
  } catch (error) {
    showMessage(error.message, "error");
  }
}

function loadImportExampleManifest() {
  state.importerDraft.manifestText = state.importer?.example_manifest_text || "{\n  \"sources\": []\n}\n";
  renderImporterEditor();
  setMode("integration");
  setIntegrationTab("importer");
  showMessage("Loaded the example importer manifest into the studio editor.", "success");
}

async function runImporterDryRun() {
  try {
    const result = await fetchJson("/api/importer/run", {
      fetchOptions: {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          manifest_text: state.importerDraft.manifestText || "{\n  \"sources\": []\n}\n",
          config: collectImporterConfigDraft("dry_run"),
          apply_bundle: false
        })
      }
    });
    state.importer = result.data.importer || state.importer;
    syncImporterDraftFromState();
    refreshWorkspace();
    setMode("integration");
    setIntegrationTab("review");
    const summary = state.importer?.summary || {};
    showMessage(`Dry import finished: ${summary.ready || 0} ready, ${summary.review || 0} review, ${summary.rejected || 0} rejected.`, "success");
  } catch (error) {
    showMessage(error.message, "error");
  }
}

async function applyImporterBundle() {
  const proceed = window.confirm("Apply the current importer bundle into the live framework files now?");
  if (!proceed) {
    return;
  }
  try {
    const result = await fetchJson("/api/importer/run", {
      fetchOptions: {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          manifest_text: state.importerDraft.manifestText || "{\n  \"sources\": []\n}\n",
          config: collectImporterConfigDraft("apply"),
          apply_bundle: true
        })
      }
    });
    state.importer = result.data.importer || state.importer;
    syncImporterDraftFromState();
    refreshWorkspace();
    setMode("integration");
    setIntegrationTab("review");
    const applyResult = state.importer?.report?.apply_result || {};
    showMessage(`Importer bundle applied: ${(applyResult.applied_files || []).length} files copied, ${(applyResult.conflicts || []).length} conflicts logged.`, "success");
  } catch (error) {
    showMessage(error.message, "error");
  }
}

async function refreshDeliveryQueueState(options = {}) {
  try {
    const result = await fetchJson("/api/delivery/state", { allowError: true });
    if (!result.ok) {
      if (!options.silent) {
        showMessage(result.data?.error || "The delivery queue could not be loaded.", "error");
      }
      return;
    }
    state.deliveryQueue = result.data.delivery_queue || null;
    renderHomePcDeliveryPanel();
    renderIntegrationSummary();
    renderWizardProgress();
  } catch (error) {
    if (!options.silent) {
      showMessage(error.message, "error");
    }
  }
}

function renderHomePcDeliveryPanel() {
  const checklist = document.getElementById("homePcPublishChecklist");
  if (!checklist) {
    return;
  }
  const validation = computeValidation(currentDraftPayload());
  const draftEntry = currentDraftViewerEntry();
  const delivery = gatherDeliveryPayload();
  const queue = state.deliveryQueue || { summary: {}, pending: [], history: [] };

  checklist.innerHTML = renderValidationItems(buildPublishChecklistItems(validation, draftEntry, delivery));
  document.getElementById("deliveryQueueSummary").innerHTML = `
    ${renderKeyValueRow("Pending", String(queue.summary?.pending || queue.pending?.length || 0))}
    ${renderKeyValueRow("History", String(queue.summary?.history || queue.history?.length || 0))}
    ${renderKeyValueRow("Last Update", queue.summary?.updated_at || "No deliveries queued yet")}
    ${renderKeyValueRow("Draft Target", draftEntry.name || "Unsaved Draft")}
  `;

  renderDeliveryEntryCards("deliveryPendingList", queue.pending || [], {
    emptyText: "Publish a species to queue it for pickup at the bedroom PC.",
    pending: true
  });
  renderDeliveryEntryCards("deliveryHistoryList", queue.history || [], {
    emptyText: "Claimed and canceled deliveries will appear here after the first publish.",
    pending: false
  });
}

function buildPublishChecklistItems(validation, draftEntry, delivery) {
  const items = [];
  const hasSavedId = Boolean(document.getElementById("existingId").value);
  const hasFrontArt = Boolean(state.pendingAssets.front_data_url || (draftEntry.visuals?.front && draftEntry.visuals.front !== BLANK_IMAGE));
  const level = Number(delivery.level || 0);
  const quantity = Number(delivery.quantity || 0);

  if (validation.errors.length) {
    items.push({
      severity: "error",
      title: "Blocking validation issues",
      body: `Clear ${validation.errors.length} error(s) before publishing this species to the bedroom PC queue.`
    });
  } else {
    items.push({
      severity: "success",
      title: "Species data ready",
      body: "This draft has no blocking validation issues and can be written into the framework safely."
    });
  }

  items.push({
    severity: hasFrontArt ? "success" : "warning",
    title: hasFrontArt ? "Artwork ready" : "Artwork still needed",
      body: hasFrontArt
        ? "Front-facing art is available for the saved species and live preview."
        : "Queue publishing expects the species art to be present so the in-game bedroom PC delivery feels complete."
  });

  items.push({
    severity: hasSavedId ? "success" : "suggestion",
    title: hasSavedId ? "Framework entry will update" : "First publish will save the species",
    body: hasSavedId
      ? `${draftEntry.name || "This species"} already has a creator registry entry and will be updated in place.`
      : "Publishing will save the species JSON and art first, then create the bedroom PC delivery ticket."
  });

  const deliveryReady = level >= 1 && level <= 100 && quantity >= 1 && quantity <= 6;
  items.push({
    severity: deliveryReady ? "success" : "warning",
    title: deliveryReady ? "Delivery packet ready" : "Delivery settings need attention",
    body: deliveryReady
      ? `The queued specimen will be delivered at level ${level} in a batch of ${quantity}.`
      : "Choose a level from 1 to 100 and a quantity from 1 to 6 before publishing."
  });

  items.push({
    severity: "suggestion",
    title: "In-game step",
    body: "If this species is new or changed, restart the game before visiting the bedroom PC so the framework can register the updated data cleanly."
  });
  return items;
}

function renderDeliveryEntryCards(containerId, entries, options = {}) {
  const container = document.getElementById(containerId);
  if (!container) {
    return;
  }
  if (!entries.length) {
    container.innerHTML = `<div class="empty-state">${escapeHtml(options.emptyText || "No delivery entries available.")}</div>`;
    return;
  }
  container.innerHTML = entries.map((entry) => renderDeliveryEntryCard(entry, options)).join("");
  if (options.pending) {
    container.querySelectorAll("[data-cancel-delivery]").forEach((button) => {
      button.addEventListener("click", () => cancelQueuedDelivery(button.dataset.cancelDelivery));
    });
  }
}

function renderDeliveryEntryCard(entry, options = {}) {
  const pokemon = entry?.pokemon || {};
  const status = String(entry?.status || (options.pending ? "pending" : "claimed")).toLowerCase();
  const quantity = Number(entry?.quantity || 1);
  const processedExtra = entry?.processed_extra || {};
  const claimBoxes = Array.isArray(entry?.claim_boxes) ? entry.claim_boxes : (Array.isArray(processedExtra?.claim_boxes) ? processedExtra.claim_boxes : []);
  const whenLabel = options.pending ? (entry?.created_at || "Queued now") : (entry?.processed_at || entry?.updated_at || "No timestamp");
  const detailBits = [
    `Lv. ${String(pokemon.level || 1)}`,
    `x${String(quantity)}`
  ];
  if (pokemon.nickname) {
    detailBits.push(`Nickname ${pokemon.nickname}`);
  }
  if (pokemon.held_item) {
    detailBits.push(`Item ${pokemon.held_item}`);
  }
  if (pokemon.shiny) {
    detailBits.push("Shiny");
  }
  if (!options.pending && claimBoxes.length) {
    detailBits.push(`Boxes ${claimBoxes.join(", ")}`);
  }
  return `
    <article class="import-entry-card">
      <div class="import-entry-head">
        <div>
          <strong>${escapeHtml(entry?.delivery_label || entry?.species_name || "Queued Delivery")}</strong>
          <small>${escapeHtml(entry?.species_name || "Unknown species")} · ${escapeHtml(whenLabel)}</small>
        </div>
        <span class="status-chip ${escapeAttribute(status === "pending" ? "review" : (status === "claimed" ? "ready" : "neutral"))}">${escapeHtml(titleizeToken(status))}</span>
      </div>
      <div class="key-value-list">
        ${renderKeyValueRow("Species ID", entry?.species_id || "Unknown")}
        ${renderKeyValueRow("Delivery", detailBits.join(" · "))}
        ${renderKeyValueRow("Source", entry?.source || "creator_publish")}
      </div>
      <p class="meta-copy">${escapeHtml(entry?.message || entry?.notes || "No extra delivery note was stored.")}</p>
      ${options.pending ? `
        <div class="import-entry-actions">
          <div class="import-entry-meta">
            <span class="status-chip neutral">${escapeHtml(entry?.sender || "Pokédex Studio")}</span>
          </div>
          <button class="ghost-button small" type="button" data-cancel-delivery="${escapeAttribute(entry?.delivery_id || "")}">Cancel Delivery</button>
        </div>
      ` : `
        <div class="import-entry-actions">
          <div class="import-entry-meta">
            <span class="status-chip neutral">${escapeHtml(entry?.processed_context || "game_claim")}</span>
          </div>
        </div>
      `}
    </article>
  `;
}

async function cancelQueuedDelivery(deliveryId) {
  if (!deliveryId) {
    return;
  }
  const confirmed = window.confirm("Cancel this queued bedroom PC delivery?");
  if (!confirmed) {
    return;
  }
  try {
    const result = await fetchJson("/api/delivery/cancel", {
      fetchOptions: {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ delivery_id: deliveryId })
      }
    });
    state.deliveryQueue = result.data.delivery_queue || state.deliveryQueue;
    renderHomePcDeliveryPanel();
    renderIntegrationSummary();
    renderWizardProgress();
    showMessage("Canceled the queued bedroom PC delivery.", "success");
  } catch (error) {
    showMessage(error.message, "error");
  }
}

function renderIntegrationSummary() {
  const container = document.getElementById("integrationSummary");
  if (!container) {
    return;
  }
  const validation = computeValidation(currentDraftPayload());
  const current = currentDraftViewerEntry();
  const starterLabel = state.creatorStarterSet?.label || "No starter trio saved";
  const importerSummary = state.importer?.summary || null;
  const importerMode = importerSummary
    ? (importerSummary.apply_bundle ? "Applied" : (importerSummary.dry_run_only === false ? "Bundle Ready" : "Dry Run"))
    : "Load In Advanced";
  const deliverySummary = state.deliveryQueue?.summary || {};
  container.innerHTML = `
    <article class="info-card">
      <h4>Current Draft</h4>
        <div class="key-value-list">
        ${renderKeyValueRow("Species", current.name || "Unsaved Draft")}
        ${renderKeyValueRow("Internal ID", current.id || "Not set")}
        ${renderKeyValueRow("Mode", state.mode === "integration" ? "Advanced" : titleizeToken(state.mode))}
      </div>
    </article>
    <article class="info-card">
      <h4>Starter Trio</h4>
      <p>${escapeHtml(starterLabel)}</p>
      <small class="meta-copy">${escapeHtml((state.creatorStarterSet?.species || []).join(", ") || "Choose three species in the Advanced tab.")}</small>
    </article>
    <article class="info-card">
      <h4>Validation Snapshot</h4>
      <div class="validation-summary">
        <div class="severity-pill error">Errors <strong>${validation.errors.length}</strong></div>
        <div class="severity-pill warning">Warnings <strong>${validation.warnings.length}</strong></div>
        <div class="severity-pill suggestion">Suggestions <strong>${validation.suggestions.length}</strong></div>
      </div>
    </article>
    <article class="info-card">
      <h4>Pack Intake</h4>
      ${importerSummary ? `
        <div class="key-value-list">
          ${renderKeyValueRow("Mode", importerMode)}
          ${renderKeyValueRow("Ready", String(importerSummary.ready || 0))}
          ${renderKeyValueRow("Review", String(importerSummary.review || 0))}
          ${renderKeyValueRow("Rejected", String(importerSummary.rejected || 0))}
        </div>
      ` : `
        <p class="meta-copy">Community pack intake stays in Advanced and only loads when you open Import Packs or Review Queue.</p>
      `}
    </article>
    <article class="info-card">
      <h4>Bedroom PC Queue</h4>
      <div class="key-value-list">
        ${renderKeyValueRow("Pending", String(deliverySummary.pending || 0))}
        ${renderKeyValueRow("History", String(deliverySummary.history || 0))}
        ${renderKeyValueRow("Updated", deliverySummary.updated_at || "No delivery activity yet")}
      </div>
    </article>
  `;
}

function renderInsights() {
  const draftEntry = currentDraftViewerEntry();
  const role = computeRoleEstimate(draftEntry.base_stats);
  const coverage = describeTypeCoverage(draftEntry.types);
  const curve = describeEvolutionCurve(currentDraftViewerEntry());
  document.getElementById("roleEstimate").textContent = role.title;
  document.getElementById("roleInsight").textContent = role.summary;
  document.getElementById("typeCoverageInsight").textContent = `${coverage.offense}. ${coverage.defense}.`;
  document.getElementById("evolutionCurveInsight").textContent = curve;
  renderEvolutionTreeBuilder();
}

function renderEvolutionTreeBuilder() {
  const container = document.getElementById("evolutionTreeBuilder");
  const entry = currentDraftViewerEntry();
  const nodes = buildEvolutionTreeNodes(entry);
  if (!nodes.length) {
    container.className = "tree-preview empty";
    container.textContent = "Add evolutions or clone a species family to preview its tree here.";
    return;
  }
  container.className = "tree-preview";
  container.innerHTML = nodes.map((node) => {
    if (node.type === "arrow") {
      return `<span class="tree-arrow">${escapeHtml(node.label)}</span>`;
    }
    return `<span class="tree-node">${escapeHtml(node.label)}</span>`;
  }).join("");
}

function renderValidationPanels() {
  const validation = computeValidation(currentDraftPayload());
  document.getElementById("validationErrorsCount").textContent = String(validation.errors.length);
  document.getElementById("validationWarningsCount").textContent = String(validation.warnings.length);
  document.getElementById("validationSuggestionsCount").textContent = String(validation.suggestions.length);

  const combined = [
    ...validation.errors.map((item) => ({ ...item, severity: "error" })),
    ...validation.warnings.map((item) => ({ ...item, severity: "warning" })),
    ...validation.suggestions.map((item) => ({ ...item, severity: "suggestion" }))
  ];
  document.getElementById("validationList").innerHTML = renderValidationItems(combined);
  document.getElementById("integrationValidationSummary").innerHTML = `
    <div class="severity-pill error">Errors <strong>${validation.errors.length}</strong></div>
    <div class="severity-pill warning">Warnings <strong>${validation.warnings.length}</strong></div>
    <div class="severity-pill suggestion">Suggestions <strong>${validation.suggestions.length}</strong></div>
  `;
  document.getElementById("integrationValidationList").innerHTML = renderValidationItems(combined);
}

function renderValidationItems(items) {
  if (!items.length) {
    return `<div class="validation-item suggestion"><strong>Ready To Save</strong><span>No blocking issues are currently detected for this draft.</span></div>`;
  }
  return items.map((item) => `
    <div class="validation-item ${escapeAttribute(item.severity)}">
      <strong>${escapeHtml(item.title)}</strong>
      <span>${escapeHtml(item.body)}</span>
    </div>
  `).join("");
}

function renderExportManifest() {
  const payload = currentDraftPayload();
  const internalId = buildSuggestedInternalId(payload.internal_id || payload.name || "CUSTOMMON");
  const manifest = document.getElementById("exportManifest");
  const existingId = document.getElementById("existingId").value;
  const prospectiveId = existingId || internalId;
  manifest.innerHTML = `
    <h4>Install Paths</h4>
    <div class="key-value-list">
      ${renderKeyValueRow("Species Registry", "Mods/custom_species_framework/data/species/user_created_species.json")}
      ${renderKeyValueRow("Front Sprite", `Mods/custom_species_framework/Graphics/Pokemon/Front/${prospectiveId}.png`)}
      ${renderKeyValueRow("Back Sprite", `Mods/custom_species_framework/Graphics/Pokemon/Back/${prospectiveId}.png`)}
      ${renderKeyValueRow("Icon", `Mods/custom_species_framework/Graphics/Pokemon/Icons/${prospectiveId}.png`)}
      ${renderKeyValueRow("Export Bundle", `Mods/custom_species_framework/creator/data/exports/${String(prospectiveId).toLowerCase()}.zip`)}
    </div>
    <p class="meta-copy">${existingId ? "This species has already been saved into the framework registry." : "Save the species first to write it into the framework registry and unlock export packaging."}</p>
  `;

  const downloadPanel = document.getElementById("exportDownloadPanel");
  if (!state.lastExport) {
    downloadPanel.classList.add("hidden");
    downloadPanel.innerHTML = "";
    return;
  }
  downloadPanel.classList.remove("hidden");
  downloadPanel.innerHTML = `
    <h4>Latest Export</h4>
    <p>${escapeHtml(state.lastExport.species_name || state.lastExport.species_id)} was packaged successfully.</p>
    <div class="key-value-list">
      ${renderKeyValueRow("Files", String((state.lastExport.files || []).length))}
      ${renderKeyValueRow("Download", state.lastExport.download_path)}
    </div>
    <a class="download-link" href="${escapeAttribute(state.lastExport.download_path)}" download>Download Export Bundle</a>
  `;
}

function renderLivePreview() {
  const entry = currentPreviewEntry();
  if (!entry) {
    document.getElementById("previewDexNumber").textContent = "No. ---";
    document.getElementById("previewSourcePill").textContent = "Pokédex";
    document.getElementById("previewName").textContent = "Select A Species";
    document.getElementById("previewCategory").textContent = "Choose a Pokémon from the Pokédex to preview it here.";
    document.getElementById("previewTypeChips").innerHTML = "";
    document.getElementById("previewDexEntry").textContent = "Build or select a species to preview its Pokédex entry here.";
    document.getElementById("battlePreviewName").textContent = "Select A Species";
    document.getElementById("battlePreviewLevel").textContent = "Lv. --";
    document.getElementById("battlePreviewBst").textContent = "BST --";
    document.getElementById("battlePreviewAbility").textContent = "Ability: --";
    document.getElementById("previewPartyName").textContent = "Select A Species";
    document.getElementById("previewPartyRole").textContent = "Waiting";
    document.getElementById("previewEvolutionChain").innerHTML = `<p class="muted-copy">Pick a species to preview its evolution chain.</p>`;
    document.getElementById("battlePreviewBar").style.width = "16%";
    setImageSourceWithFallback(document.getElementById("previewHeroImage"), []);
    setImageSourceWithFallback(document.getElementById("previewPartyIcon"), []);
    document.querySelectorAll("[data-preview-face]").forEach((button) => {
      button.classList.toggle("active", button.dataset.previewFace === state.preview.face);
    });
    document.getElementById("previewShinyBtn").classList.toggle("active", state.preview.shiny);
    return;
  }
  const role = computeRoleEstimate(entry.base_stats);
  const dexNumber = entry.id_number ? `No. ${formatDexNumber(entry.id_number)}` : "No. ---";
  const sourceLabel = isFusionSymbol(entry.id)
    ? "Fusion Slice"
    : (entry.source === "base_game" ? "Base Game" : titleizeToken(entry.kind || "draft"));
  document.getElementById("previewDexNumber").textContent = dexNumber;
  document.getElementById("previewSourcePill").textContent = sourceLabel;
  document.getElementById("previewName").textContent = entry.name || "New Species";
  document.getElementById("previewCategory").textContent = entry.category || "Custom Species";
  document.getElementById("previewTypeChips").innerHTML = renderTypeChips(entry.types);
  document.getElementById("previewDexEntry").textContent = entry.pokedex_entry || "Build or select a species to preview its Pokédex entry here.";
  document.getElementById("battlePreviewName").textContent = entry.name || "New Species";
  document.getElementById("battlePreviewLevel").textContent = `Lv. ${entry.starter_eligible ? "5" : "50"}`;
  document.getElementById("battlePreviewBst").textContent = `BST ${entry.bst || calculateBst(entry.base_stats)}`;
  document.getElementById("battlePreviewAbility").textContent = `Ability: ${(entry.abilities[0]?.name || "None")}`;
  document.getElementById("previewPartyName").textContent = entry.name || "New Species";
  document.getElementById("previewPartyRole").textContent = role.title;
  document.getElementById("previewEvolutionChain").innerHTML = renderEvolutionChainHtml(entry);
  document.getElementById("battlePreviewBar").style.width = `${Math.max(16, Math.min(100, Math.round(((entry.bst || 300) / 720) * 100)))}%`;

  const heroImage = document.getElementById("previewHeroImage");
  setImageSourceWithFallback(heroImage, previewImageCandidates(entry));
  heroImage.classList.toggle("shiny-preview", state.preview.shiny);

  const partyIcon = document.getElementById("previewPartyIcon");
  setImageSourceWithFallback(partyIcon, previewIconCandidates(entry));
  partyIcon.classList.toggle("shiny-preview", state.preview.shiny);

  document.querySelectorAll("[data-preview-face]").forEach((button) => {
    button.classList.toggle("active", button.dataset.previewFace === state.preview.face);
  });
  document.getElementById("previewShinyBtn").classList.toggle("active", state.preview.shiny);
}

function currentPreviewEntry() {
  if (state.mode === "pokedex") {
    return selectedDexEntry();
  }
  return currentDraftViewerEntry();
}

function currentDraftViewerEntry() {
  return normalizeCreatorSpeciesEntry({
    id: document.getElementById("existingId").value || buildSuggestedInternalId(document.getElementById("internalId").value || document.getElementById("name").value || "CUSTOMMON"),
    ...currentDraftPayload(),
    assets: {
      front: state.pendingAssets.front_data_url ? null : state.species.find((entry) => entry.id === document.getElementById("existingId").value)?.assets?.front,
      back: state.pendingAssets.back_data_url ? null : state.species.find((entry) => entry.id === document.getElementById("existingId").value)?.assets?.back,
      icon: state.pendingAssets.icon_data_url ? null : state.species.find((entry) => entry.id === document.getElementById("existingId").value)?.assets?.icon
    }
  });
}

function currentDraftPayload() {
  return gatherSpeciesPayload();
}

function defaultDeliveryPayload(source = {}) {
  const speciesName = source.name || document.getElementById("name")?.value.trim() || "Custom Species";
  const starterEligible = Boolean(source.starter_eligible ?? document.getElementById("starterEligible")?.checked);
  return {
    label: speciesName ? `${speciesName} Delivery` : "Custom Species Delivery",
    level: starterEligible ? 5 : 10,
    quantity: 1,
    nickname: "",
    held_item: "",
    shiny: false,
    message: "Queued from the browser studio for pickup at the player's bedroom PC.",
    notes: ""
  };
}

function gatherDeliveryPayload() {
  const labelInput = document.getElementById("deliveryLabel");
  if (!labelInput) {
    return defaultDeliveryPayload();
  }
  return {
    label: labelInput.value.trim(),
    level: document.getElementById("deliveryLevel").value,
    quantity: document.getElementById("deliveryQuantity").value,
    nickname: document.getElementById("deliveryNickname").value.trim(),
    held_item: document.getElementById("deliveryHeldItem").value.trim(),
    shiny: document.getElementById("deliveryShiny").checked,
    message: document.getElementById("deliveryMessage").value.trim(),
    notes: document.getElementById("deliveryNotes").value.trim()
  };
}

function applyDeliveryPayloadToForm(payload, draft = {}) {
  const merged = {
    ...defaultDeliveryPayload(draft),
    ...(payload || {})
  };
  setValue("deliveryLabel", merged.label || "");
  setValue("deliveryLevel", merged.level || (draft.starter_eligible ? 5 : 10));
  setValue("deliveryQuantity", merged.quantity || 1);
  setValue("deliveryNickname", merged.nickname || "");
  setValue("deliveryHeldItem", merged.held_item || "");
  setChecked("deliveryShiny", Boolean(merged.shiny));
  setValue("deliveryMessage", merged.message || "");
  setValue("deliveryNotes", merged.notes || "");
}

function newSpeciesDraft(source = null, options = {}) {
  state.selectedId = null;
  state.pendingAssets = { front_data_url: null, back_data_url: null, icon_data_url: null };
  state.lastExport = null;
  state.suspendHistory = true;

  document.getElementById("speciesForm").reset();
  document.getElementById("existingId").value = "";
  document.getElementById("internalId").disabled = false;

  const draft = buildDraftFromSource(source, options);
  applyDraftToForm(draft, { existingId: "", lockInternalId: false, pendingAssets: state.pendingAssets });

  state.suspendHistory = false;
  captureHistorySnapshot(true);
  persistAutosave();
  setMode("creator");
  setCreatorTab("overview");
  refreshWorkspace();
}

function buildDraftFromSource(source = null, options = {}) {
  if (!source) {
    return defaultDraft();
  }
  const normalized = source.base_stats ? source : normalizeCatalogSpeciesEntry(source);
  const targetKind = options.kind || (normalized.kind === "regional_variant" ? "regional_variant" : "fakemon");
  const suffix = options.nameSuffix || (targetKind === "regional_variant" ? " Variant" : (source.id && source.source === "base_game" ? " Copy" : " Copy"));
  const regionalBaseId = normalized.base_species?.id || normalized.id || "";
  const regionalFallbackId = normalized.fallback_species?.id || normalized.base_species?.id || regionalBaseId;
  const fusionSource = normalized.fusion_source || normalizeFusionSourceValue(regionalBaseId);
  const variantSourceMode = targetKind === "regional_variant" && fusionSource ? "fusion" : "species";
  const variantScope = targetKind === "regional_variant" ? (options.variantScope || normalized.variant_scope || "single_species") : "";
  const variantFamily = targetKind === "regional_variant"
    ? (typeof options.variantFamily === "string"
        ? options.variantFamily
        : (variantScope === "lineage" ? (normalized.variant_family || `${normalized.name} Variant Line`) : (normalized.variant_family || "")))
    : "";
  return {
    kind: targetKind,
    name: normalized.name ? `${normalized.name}${suffix}` : "",
    category: normalized.category || "",
    template_source_label: options.templateLabel || normalized.template_source_label || (targetKind === "regional_variant" && normalized.name ? `Regional variant of ${normalized.name}` : (normalized.name || "")),
    generation: normalized.generation || 9,
    fusion_rule: normalized.fusion_rule || "blocked",
    base_species: targetKind === "regional_variant" ? regionalBaseId : "",
    fallback_species: targetKind === "regional_variant" ? regionalFallbackId : "",
    variant_source_mode: variantSourceMode,
    variant_scope: variantScope,
    fusion_source_head: targetKind === "regional_variant" ? (fusionSource?.head?.id || "") : "",
    fusion_source_body: targetKind === "regional_variant" ? (fusionSource?.body?.id || "") : "",
    variant_family: variantFamily,
    starter_eligible: Boolean(normalized.starter_eligible),
    encounter_eligible: Boolean(normalized.encounter_eligible),
    trainer_eligible: Boolean(normalized.trainer_eligible),
    type1: normalized.types[0] || "NORMAL",
    type2: normalized.types[1] || "",
    growth_rate: normalized.growth_rate?.id || "Medium",
    gender_ratio: normalized.gender_ratio?.id || "Female50Percent",
    primary_ability: normalized.abilities[0]?.id || "",
    secondary_ability: normalized.abilities[1]?.id || "",
    hidden_ability: normalized.hidden_abilities[0]?.id || "",
    egg_group_1: normalized.egg_groups[0]?.id || "Field",
    egg_group_2: normalized.egg_groups[1]?.id || "",
    base_exp: normalized.base_exp || 64,
    catch_rate: normalized.catch_rate || 45,
    happiness: normalized.happiness || 70,
    hatch_steps: normalized.hatch_steps || 5120,
    height: normalized.height || 6,
    weight: normalized.weight || 60,
    color: normalized.color?.id || "Red",
    shape: normalized.shape?.id || "Head",
    habitat: normalized.habitat?.id || "None",
    hp: normalized.base_stats.HP || 50,
    attack: normalized.base_stats.ATTACK || 50,
    defense: normalized.base_stats.DEFENSE || 50,
    special_attack: normalized.base_stats.SPECIAL_ATTACK || 50,
    special_defense: normalized.base_stats.SPECIAL_DEFENSE || 50,
    speed: normalized.base_stats.SPEED || 50,
    pokedex_entry: normalized.pokedex_entry || "",
    design_notes: normalized.design_notes || "",
    moves: normalized.moves.length ? normalized.moves.map((move) => ({ level: move.level || 1, move: move.id })) : [{ level: 1, move: "TACKLE" }],
    tm_moves: normalized.tm_moves.map((move) => move.id),
    tutor_moves: normalized.tutor_moves.map((move) => move.id),
    egg_moves: normalized.egg_moves.map((move) => move.id),
    evolutions: normalized.evolutions.map((evo) => ({
      species: evo.species?.id || "",
      method: evo.method?.id || "Level",
      parameter: parameterAsInput(evo.parameter)
    })),
    encounter_rarity: normalized.world_data.encounter_rarity || "",
    encounter_zones: (normalized.world_data.encounter_zones || []).join("\n"),
    trainer_roles: (normalized.world_data.trainer_roles || []).join("\n"),
    trainer_notes: normalized.world_data.trainer_notes || "",
    encounter_level_min: normalized.world_data.encounter_level_min || 0,
    encounter_level_max: normalized.world_data.encounter_level_max || 0,
    head_offset_x: normalized.fusion_meta.head_offset_x || 0,
    head_offset_y: normalized.fusion_meta.head_offset_y || 0,
    body_offset_x: normalized.fusion_meta.body_offset_x || 0,
    body_offset_y: normalized.fusion_meta.body_offset_y || 0,
    fusion_naming_notes: normalized.fusion_meta.naming_notes || "",
    fusion_sprite_hints: normalized.fusion_meta.sprite_hints || "",
    export_author: normalized.export_meta.author || "",
    export_version: normalized.export_meta.version || "",
    export_pack_name: normalized.export_meta.pack_name || "",
    export_tags: (normalized.export_meta.tags || []).join(", ")
  };
}

function defaultDraft() {
  return {
    kind: "fakemon",
    name: "",
    category: "",
    template_source_label: "",
    generation: 9,
    fusion_rule: "blocked",
    base_species: "",
    fallback_species: "",
    variant_source_mode: "species",
    variant_scope: "single_species",
    fusion_source_head: "",
    fusion_source_body: "",
    variant_family: "",
    starter_eligible: false,
    encounter_eligible: false,
    trainer_eligible: false,
    type1: "NORMAL",
    type2: "",
    growth_rate: "Medium",
    gender_ratio: "Female50Percent",
    primary_ability: "",
    secondary_ability: "",
    hidden_ability: "",
    egg_group_1: "Field",
    egg_group_2: "",
    base_exp: 64,
    catch_rate: 45,
    happiness: 70,
    hatch_steps: 5120,
    height: 6,
    weight: 60,
    color: "Red",
    shape: "Head",
    habitat: "None",
    hp: 50,
    attack: 50,
    defense: 50,
    special_attack: 50,
    special_defense: 50,
    speed: 50,
    pokedex_entry: "",
    design_notes: "",
    moves: [{ level: 1, move: "TACKLE" }],
    tm_moves: [],
    tutor_moves: [],
    egg_moves: [],
    evolutions: [],
    encounter_rarity: "",
    encounter_zones: "",
    trainer_roles: "",
    trainer_notes: "",
    encounter_level_min: 0,
    encounter_level_max: 0,
    head_offset_x: 0,
    head_offset_y: 0,
    body_offset_x: 0,
    body_offset_y: 0,
    fusion_naming_notes: "",
    fusion_sprite_hints: "",
    export_author: "",
    export_version: "",
    export_pack_name: "",
    export_tags: ""
  };
}

function normalizeImportedSpeciesEntry(entry) {
  const gameData = entry?.game_data || {};
  const stats = normalizeImportedStats(gameData.base_stats);
  const fusionRule = gameData.fusion_rule || (entry?.integration?.fusion_ready ? "standard" : "blocked");
  const sourcePack = entry?.source_pack || "Imported Pack";
  const creator = entry?.creator || "Unknown creator";
  const typeList = uniqueTypes(gameData.types || ["NORMAL"]);
  const evolutions = (gameData.evolutions || []).map((evo) => ({
    species: speciesReference(evo?.species || evo?.id || evo?.target_species || ""),
    method: evolutionMethodEntry(evo?.method || "Level"),
    parameter: evolutionParameterDisplay(evo?.parameter, evo?.method || "Level")
  }));
  return {
    id: entry?.id || buildSuggestedInternalId(entry?.display_name || entry?.species_name || "IMPORTEDMON"),
    name: entry?.display_name || entry?.species_name || entry?.id || "Imported Species",
    species: entry?.id || "",
    id_number: Number(entry?.integration?.framework_slot || 0),
    category: gameData.category || "Imported Species",
    pokedex_entry: gameData.pokedex_entry || "",
    design_notes: entry?.notes || "",
    template_source_label: `${sourcePack} · ${creator}`,
    types: typeList,
    base_stats: stats,
    bst: calculateBst(stats),
    base_exp: Number(gameData.base_exp || 64),
    growth_rate: namedCatalogEntry("growth_rates", gameData.growth_rate || "Medium"),
    gender_ratio: namedCatalogEntry("gender_ratios", gameData.gender_ratio || "Female50Percent"),
    catch_rate: Number(gameData.catch_rate || 45),
    happiness: Number(gameData.happiness || 70),
    abilities: normalizeNamedList((gameData.abilities || []).map((id) => namedCatalogEntry("abilities", id))),
    hidden_abilities: normalizeNamedList([gameData.hidden_ability].filter(Boolean).map((id) => namedCatalogEntry("abilities", id))),
    moves: normalizeMoveList(gameData.moves || []),
    tutor_moves: normalizeMoveList(gameData.tutor_moves || []),
    egg_moves: normalizeMoveList(gameData.egg_moves || []),
    tm_moves: normalizeMoveList(gameData.tm_moves || []),
    egg_groups: normalizeNamedList((gameData.egg_groups || ["Field"]).map((id) => namedCatalogEntry("egg_groups", id))),
    hatch_steps: Number(gameData.hatch_steps || 5120),
    evolutions: normalizeEvolutionList(evolutions),
    previous_species: normalizeSpeciesReference(gameData.previous_species || gameData.base_species || null),
    family_species: normalizeSpeciesReferenceList(gameData.family_species || []),
    height: Number(gameData.height || 10),
    weight: Number(gameData.weight || 100),
    color: namedCatalogEntry("body_colors", gameData.color || "Red"),
    shape: namedCatalogEntry("body_shapes", gameData.shape || "Head"),
    habitat: namedCatalogEntry("habitats", gameData.habitat || "None"),
    generation: Number(gameData.generation || 9),
    kind: gameData.kind || "fakemon",
    source: "importer",
    fusion_rule: fusionRule,
    fusion_compatible: Boolean(entry?.integration?.fusion_ready),
    starter_eligible: Boolean(gameData.starter_eligible),
    encounter_eligible: Boolean(gameData.encounter_eligible),
    trainer_eligible: Boolean(gameData.trainer_eligible),
    regional_variant: (gameData.kind || "") === "regional_variant",
    variant_scope: gameData.variant_scope || ((gameData.kind || "") === "regional_variant" ? "single_species" : ""),
    variant_family: gameData.variant_family || "",
    base_species: normalizeSpeciesReference(gameData.base_species || null),
    fallback_species: normalizeSpeciesReference(gameData.fallback_species || null),
    visuals: normalizeVisuals({
      front: resolveStudioAssetUrl(entry?.staged_assets?.front || entry?.assets?.front),
      back: resolveStudioAssetUrl(entry?.staged_assets?.back || entry?.assets?.back || entry?.staged_assets?.front || entry?.assets?.front),
      icon: resolveStudioAssetUrl(entry?.staged_assets?.icon || entry?.assets?.icon || entry?.staged_assets?.front || entry?.assets?.front),
      shiny_front: resolveStudioAssetUrl(entry?.staged_assets?.shiny_front || entry?.assets?.shiny_front),
      shiny_back: resolveStudioAssetUrl(entry?.staged_assets?.shiny_back || entry?.assets?.shiny_back),
      overworld: resolveStudioAssetUrl(entry?.staged_assets?.overworld || entry?.assets?.overworld),
      shiny_strategy: "hue_shift"
    }),
    world_data: normalizeWorldData(gameData.world_data || {}),
    fusion_meta: normalizeFusionMeta(gameData.fusion_meta || {
      rule: fusionRule
    }, fusionRule),
    export_meta: normalizeExportMeta({
      author: creator,
      pack_name: sourcePack,
      version: entry?.pack_version || "1.0.0",
      tags: ["imported_pack", entry?.pack_slug].filter(Boolean)
    })
  };
}

function normalizeImportedStats(stats) {
  const source = stats || {};
  return normalizeStats({
    HP: Number(source.HP ?? source.hp ?? 0),
    ATTACK: Number(source.ATTACK ?? source.attack ?? 0),
    DEFENSE: Number(source.DEFENSE ?? source.defense ?? 0),
    SPECIAL_ATTACK: Number(source.SPECIAL_ATTACK ?? source.sp_attack ?? source.special_attack ?? 0),
    SPECIAL_DEFENSE: Number(source.SPECIAL_DEFENSE ?? source.sp_defense ?? source.special_defense ?? 0),
    SPEED: Number(source.SPEED ?? source.speed ?? 0)
  });
}

function loadSpeciesIntoForm(entry) {
  if (!entry) {
    return;
  }
  state.selectedId = entry.id;
  state.pendingAssets = { front_data_url: null, back_data_url: null, icon_data_url: null };
  state.lastExport = null;
  state.suspendHistory = true;
  applyDraftToForm(buildDraftFromSource(normalizeCreatorSpeciesEntry(entry), { nameSuffix: "" }), {
    existingId: entry.id,
    lockInternalId: true,
    pendingAssets: state.pendingAssets
  });
  state.suspendHistory = false;
  captureHistorySnapshot(true);
  setMode("creator");
  setCreatorTab("overview");
  refreshWorkspace();
}

function applyDraftToForm(draft, options = {}) {
  setValue("existingId", options.existingId || "");
  setValue("kind", draft.kind || "fakemon");
  setValue("name", draft.name || "");
  setValue("internalId", options.existingId || draft.internal_id || buildSuggestedInternalId(draft.name || "CUSTOMMON"));
  document.getElementById("internalId").disabled = Boolean(options.lockInternalId);
  setValue("category", draft.category || "");
  setValue("generation", draft.generation || 9);
  setValue("fusionRule", draft.fusion_rule || "blocked");
  setValue("baseSpecies", draft.base_species || "");
  setValue("fallbackSpecies", draft.fallback_species || "");
  setValue("variantSourceMode", draft.variant_source_mode || (isFusionSymbol(draft.base_species || "") ? "fusion" : "species"));
  setValue("variantScope", draft.variant_scope || "single_species");
  setValue("variantFusionHead", draft.fusion_source_head || normalizeFusionSourceValue(draft.base_species)?.head?.id || "");
  setValue("variantFusionBody", draft.fusion_source_body || normalizeFusionSourceValue(draft.base_species)?.body?.id || "");
  setValue("variantFamily", draft.variant_family || "");
  setChecked("starterEligible", Boolean(draft.starter_eligible));
  setChecked("encounterEligible", Boolean(draft.encounter_eligible));
  setChecked("trainerEligible", Boolean(draft.trainer_eligible));
  setValue("type1", draft.type1 || "NORMAL");
  setValue("type2", draft.type2 || "");
  setValue("growthRate", draft.growth_rate || "Medium");
  setValue("genderRatio", draft.gender_ratio || "Female50Percent");
  setValue("primaryAbility", draft.primary_ability || "");
  setValue("secondaryAbility", draft.secondary_ability || "");
  setValue("hiddenAbility", draft.hidden_ability || "");
  setValue("eggGroup1", draft.egg_group_1 || "Field");
  setValue("eggGroup2", draft.egg_group_2 || "");
  setValue("baseExp", draft.base_exp || 64);
  setValue("catchRate", draft.catch_rate || 45);
  setValue("happiness", draft.happiness || 70);
  setValue("hatchSteps", draft.hatch_steps || 5120);
  setValue("height", draft.height || 6);
  setValue("weight", draft.weight || 60);
  setValue("color", draft.color || "Red");
  setValue("shape", draft.shape || "Head");
  setValue("habitat", draft.habitat || "None");
  setValue("statHp", draft.hp || 50);
  setValue("statAttack", draft.attack || 50);
  setValue("statDefense", draft.defense || 50);
  setValue("statSpecialAttack", draft.special_attack || 50);
  setValue("statSpecialDefense", draft.special_defense || 50);
  setValue("statSpeed", draft.speed || 50);
  setValue("pokedexEntry", draft.pokedex_entry || "");
  setValue("designNotes", draft.design_notes || "");
  setValue("templateSourceLabel", draft.template_source_label || "");
  setValue("encounterRarity", draft.encounter_rarity || "");
  setValue("encounterZones", draft.encounter_zones || "");
  setValue("trainerRoles", draft.trainer_roles || "");
  setValue("trainerNotes", draft.trainer_notes || "");
  setValue("encounterLevelMin", draft.encounter_level_min || 0);
  setValue("encounterLevelMax", draft.encounter_level_max || 0);
  setValue("headOffsetX", draft.head_offset_x || 0);
  setValue("headOffsetY", draft.head_offset_y || 0);
  setValue("bodyOffsetX", draft.body_offset_x || 0);
  setValue("bodyOffsetY", draft.body_offset_y || 0);
  setValue("fusionNamingNotes", draft.fusion_naming_notes || "");
  setValue("fusionSpriteHints", draft.fusion_sprite_hints || "");
  setValue("exportAuthor", draft.export_author || "");
  setValue("exportVersion", draft.export_version || "");
  setValue("exportPackName", draft.export_pack_name || "");
  setValue("exportTags", draft.export_tags || "");

  renderLevelMoves(draft.moves || []);
  renderSimpleMoves("tmMovesList", draft.tm_moves || []);
  renderSimpleMoves("tutorMovesList", draft.tutor_moves || []);
  renderSimpleMoves("eggMovesList", draft.egg_moves || []);
  renderEvolutions(draft.evolutions || []);
  applyDeliveryPayloadToForm(options.deliveryPayload || null, draft);
  state.pendingAssets = options.pendingAssets || { front_data_url: null, back_data_url: null, icon_data_url: null };
  syncRegionalFusionFields();
  refreshAssetPreviews();
  updateKindUi();
  maybeSuggestInternalId(true);
}

function renderLevelMoves(moves) {
  const list = document.getElementById("movesList");
  list.innerHTML = "";
  moves.forEach((move) => addLevelMoveRow(move));
}

function addLevelMoveRow(move = { level: 1, move: "" }) {
  const row = document.getElementById("levelMoveTemplate").content.firstElementChild.cloneNode(true);
  row.querySelector(".row-level").value = move.level ?? 1;
  row.querySelector(".row-move").value = move.move || "";
  document.getElementById("movesList").appendChild(row);
}

function renderSimpleMoves(listId, moves) {
  const list = document.getElementById(listId);
  list.innerHTML = "";
  moves.forEach((move) => addSimpleMoveRow(listId, typeof move === "string" ? move : move.id || move.move || ""));
}

function addSimpleMoveRow(listId, move = "") {
  const row = document.getElementById("simpleMoveTemplate").content.firstElementChild.cloneNode(true);
  row.querySelector(".row-move").value = move || "";
  document.getElementById(listId).appendChild(row);
}

function renderEvolutions(evolutions) {
  const list = document.getElementById("evolutionsList");
  list.innerHTML = "";
  evolutions.forEach((entry) => addEvolutionRow(entry));
}

function addEvolutionRow(evolution = { species: "", method: "Level", parameter: "" }) {
  const row = document.getElementById("evolutionTemplate").content.firstElementChild.cloneNode(true);
  const methodSelect = row.querySelector(".row-method");
  populateSelect(methodSelect, catalogEntries("evolution_methods"), { allowBlank: false });
  row.querySelector(".row-species").value = evolution.species || "";
  methodSelect.value = evolution.method || "Level";
  row.querySelector(".row-parameter").value = evolution.parameter ?? "";
  methodSelect.addEventListener("change", () => {
    applyEvolutionParameterUi(row);
    handleFormMutation();
  });
  applyEvolutionParameterUi(row);
  document.getElementById("evolutionsList").appendChild(row);
}

function serializeLevelMoves() {
  return [...document.querySelectorAll("#movesList .repeater-row")]
    .map((row) => ({
      level: Number(row.querySelector(".row-level").value || 1),
      move: normalizeLookupValue(row.querySelector(".row-move").value)
    }))
    .filter((row) => row.move);
}

function serializeSimpleMoveList(listId) {
  return [...document.querySelectorAll(`#${listId} .repeater-row`)]
    .map((row) => normalizeLookupValue(row.querySelector(".row-move").value))
    .filter(Boolean);
}

function serializeEvolutions() {
  return [...document.querySelectorAll("#evolutionsList .repeater-row")]
    .map((row) => ({
      species: normalizeLookupValue(row.querySelector(".row-species").value),
      method: normalizeLookupValue(row.querySelector(".row-method").value),
      parameter: row.querySelector(".row-parameter").value.trim()
    }))
    .filter((row) => row.species && row.method);
}

function gatherSpeciesPayload() {
  const kind = document.getElementById("kind").value;
  const variantSourceMode = document.getElementById("variantSourceMode").value || "species";
  const variantScope = document.getElementById("variantScope").value || "single_species";
  const fusionHeadId = normalizeLookupValue(document.getElementById("variantFusionHead").value);
  const fusionBodyId = normalizeLookupValue(document.getElementById("variantFusionBody").value);
  const fusionHeadEntry = fusionComponentEntryById(fusionHeadId);
  const fusionBodyEntry = fusionComponentEntryById(fusionBodyId);
  const fusionSymbol = kind === "regional_variant" && variantSourceMode === "fusion" && fusionHeadEntry && fusionBodyEntry
    ? buildFusionSymbol(fusionBodyEntry.id_number, fusionHeadEntry.id_number)
    : "";
  const baseSpeciesValue = fusionSymbol || document.getElementById("baseSpecies").value.trim();
  const fallbackSpeciesValue = fusionSymbol || document.getElementById("fallbackSpecies").value.trim();
  return {
    kind,
    name: document.getElementById("name").value.trim(),
    internal_id: document.getElementById("internalId").value.trim(),
    category: document.getElementById("category").value.trim(),
    template_source_label: document.getElementById("templateSourceLabel").value.trim(),
    generation: document.getElementById("generation").value,
    fusion_rule: document.getElementById("fusionRule").value,
    base_species: baseSpeciesValue,
    fallback_species: fallbackSpeciesValue,
    variant_source_mode: kind === "regional_variant" ? variantSourceMode : "species",
    variant_scope: kind === "regional_variant" ? variantScope : "",
    fusion_source_head: kind === "regional_variant" ? fusionHeadId : "",
    fusion_source_body: kind === "regional_variant" ? fusionBodyId : "",
    variant_family: document.getElementById("variantFamily").value.trim(),
    starter_eligible: document.getElementById("starterEligible").checked,
    encounter_eligible: document.getElementById("encounterEligible").checked,
    trainer_eligible: document.getElementById("trainerEligible").checked,
    type1: document.getElementById("type1").value,
    type2: document.getElementById("type2").value,
    growth_rate: document.getElementById("growthRate").value,
    gender_ratio: document.getElementById("genderRatio").value,
    primary_ability: document.getElementById("primaryAbility").value.trim(),
    secondary_ability: document.getElementById("secondaryAbility").value.trim(),
    hidden_ability: document.getElementById("hiddenAbility").value.trim(),
    egg_group_1: document.getElementById("eggGroup1").value,
    egg_group_2: document.getElementById("eggGroup2").value,
    base_exp: document.getElementById("baseExp").value,
    catch_rate: document.getElementById("catchRate").value,
    happiness: document.getElementById("happiness").value,
    hatch_steps: document.getElementById("hatchSteps").value,
    height: document.getElementById("height").value,
    weight: document.getElementById("weight").value,
    color: document.getElementById("color").value,
    shape: document.getElementById("shape").value,
    habitat: document.getElementById("habitat").value,
    hp: document.getElementById("statHp").value,
    attack: document.getElementById("statAttack").value,
    defense: document.getElementById("statDefense").value,
    special_attack: document.getElementById("statSpecialAttack").value,
    special_defense: document.getElementById("statSpecialDefense").value,
    speed: document.getElementById("statSpeed").value,
    pokedex_entry: document.getElementById("pokedexEntry").value.trim(),
    design_notes: document.getElementById("designNotes").value.trim(),
    moves: serializeLevelMoves(),
    tm_moves: serializeSimpleMoveList("tmMovesList"),
    tutor_moves: serializeSimpleMoveList("tutorMovesList"),
    egg_moves: serializeSimpleMoveList("eggMovesList"),
    evolutions: serializeEvolutions(),
    encounter_rarity: document.getElementById("encounterRarity").value.trim(),
    encounter_zones: document.getElementById("encounterZones").value.trim(),
    trainer_roles: document.getElementById("trainerRoles").value.trim(),
    trainer_notes: document.getElementById("trainerNotes").value.trim(),
    encounter_level_min: document.getElementById("encounterLevelMin").value,
    encounter_level_max: document.getElementById("encounterLevelMax").value,
    head_offset_x: document.getElementById("headOffsetX").value,
    head_offset_y: document.getElementById("headOffsetY").value,
    body_offset_x: document.getElementById("bodyOffsetX").value,
    body_offset_y: document.getElementById("bodyOffsetY").value,
    fusion_naming_notes: document.getElementById("fusionNamingNotes").value.trim(),
    fusion_sprite_hints: document.getElementById("fusionSpriteHints").value.trim(),
    export_author: document.getElementById("exportAuthor").value.trim(),
    export_version: document.getElementById("exportVersion").value.trim(),
    export_pack_name: document.getElementById("exportPackName").value.trim(),
    export_tags: document.getElementById("exportTags").value.trim()
  };
}

async function saveSpecies() {
  try {
    const payload = {
      existing_id: document.getElementById("existingId").value,
      species: gatherSpeciesPayload(),
      assets: state.pendingAssets
    };
    const result = await fetchJson("/api/species/save", {
      fetchOptions: {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      }
    });

    state.species = result.data.all_species || state.species;
    state.selectedId = result.data.species?.id || null;
    state.pendingAssets = { front_data_url: null, back_data_url: null, icon_data_url: null };
    state.assetNonce = Date.now();
    invalidateDexCaches();
    state.assetDataCache.clear();
    state.pendingAssetData.clear();
    populateCatalogDrivenControls();
    renderStarterEditor();
    if (state.selectedId) {
      const saved = state.species.find((entry) => entry.id === state.selectedId);
      if (saved) {
        loadSpeciesIntoForm(saved);
      }
    }
    showMessage(`Saved ${result.data.species?.name || "species"} successfully. Restart the game before testing it in-engine.`, "success");
  } catch (error) {
    showMessage(error.message, "error");
  }
}

async function publishSpeciesToHomePc() {
  const validation = computeValidation(currentDraftPayload());
  if (validation.errors.length) {
    setMode("creator");
    setCreatorTab("publish");
    renderHomePcDeliveryPanel();
    renderWizardProgress();
    showMessage("Clear the blocking validation issues before publishing this species to the bedroom PC.", "error");
    return;
  }

  try {
    const payload = {
      existing_id: document.getElementById("existingId").value,
      species: gatherSpeciesPayload(),
      assets: state.pendingAssets,
      delivery: gatherDeliveryPayload()
    };
    const result = await fetchJson("/api/delivery/publish", {
      fetchOptions: {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      }
    });

    state.species = result.data.all_species || state.species;
    state.deliveryQueue = result.data.delivery_queue || state.deliveryQueue;
    state.selectedId = result.data.species?.id || null;
    state.pendingAssets = { front_data_url: null, back_data_url: null, icon_data_url: null };
    state.assetNonce = Date.now();
    invalidateDexCaches();
    state.assetDataCache.clear();
    state.pendingAssetData.clear();
    populateCatalogDrivenControls();
    renderStarterEditor();
    if (state.selectedId) {
      const saved = state.species.find((entry) => entry.id === state.selectedId);
      if (saved) {
        loadSpeciesIntoForm(saved);
      }
    }
    setMode("creator");
    setCreatorTab("publish");
    refreshWorkspace();
    showMessage(`Saved and queued ${result.data.species?.name || "the species"} for bedroom PC pickup. Restart the game if the species is new or changed, then claim it from the bedroom PC list.`, "success");
  } catch (error) {
    showMessage(error.message, "error");
  }
}

async function deleteSpecies() {
  const existingId = document.getElementById("existingId").value;
  if (!existingId) {
    showMessage("This draft has not been saved yet, so there is nothing to delete.", "error");
    return;
  }
  if (!window.confirm(`Delete ${existingId}? This removes the creator entry and imported art files.`)) {
    return;
  }
  try {
    const result = await fetchJson("/api/species/delete", {
      fetchOptions: {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: existingId })
      }
    });
    state.species = result.data.all_species || [];
    state.selectedId = null;
    state.assetNonce = Date.now();
    invalidateDexCaches();
    state.assetDataCache.clear();
    state.pendingAssetData.clear();
    populateCatalogDrivenControls();
    newSpeciesDraft();
    renderStarterEditor();
    showMessage(`Deleted ${existingId}.`, "success");
  } catch (error) {
    showMessage(error.message, "error");
  }
}

function duplicateSpecies() {
  const currentId = document.getElementById("existingId").value;
  const source = state.species.find((entry) => entry.id === currentId);
  if (!source) {
    showMessage("Load a saved creator species first if you want to duplicate it.", "error");
    return;
  }
  newSpeciesDraft(normalizeCreatorSpeciesEntry(source), { nameSuffix: " Copy" });
  showMessage("Duplicated the current species into a new draft.", "success");
}

async function saveStarterTrio() {
  try {
    const species = [
      document.getElementById("starterSpecies1").value,
      document.getElementById("starterSpecies2").value,
      document.getElementById("starterSpecies3").value
    ];
    const chosenSpecies = species.filter(Boolean);
    if (chosenSpecies.length !== 3) {
      showMessage("Choose exactly 3 species for the starter trio.", "error");
      return;
    }
    if ((new Set(chosenSpecies)).size !== 3) {
      showMessage("Choose 3 different species for the starter trio.", "error");
      return;
    }

    const rivalCounterpick = {};
    species.forEach((speciesId, index) => {
      if (!speciesId) {
        return;
      }
      rivalCounterpick[speciesId] = document.getElementById(`starterCounter${index + 1}`).value;
    });

    const result = await fetchJson("/api/starter-trio/save", {
      fetchOptions: {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          label: document.getElementById("starterLabel").value.trim(),
          activate_as_default: document.getElementById("starterActivate").checked,
          species,
          rival_counterpick: rivalCounterpick
        })
      }
    });
    state.creatorStarterSet = result.data.starter_set;
    renderStarterEditor();
    renderIntegrationSummary();
    showMessage("Saved the creator starter trio. Start a fresh save after restarting the game to see it in the intro menu.", "success");
  } catch (error) {
    showMessage(error.message, "error");
  }
}

async function exportSpeciesPack() {
  const existingId = document.getElementById("existingId").value;
  if (!existingId) {
    showMessage("Save the species first so the exporter can package the written files cleanly.", "error");
    return;
  }
  try {
    const result = await fetchJson("/api/export/species", {
      fetchOptions: {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: existingId })
      }
    });
    state.lastExport = result.data;
    renderExportManifest();
    setMode("integration");
    setIntegrationTab("export");
    showMessage(`Packaged ${result.data.species_name || existingId} into a downloadable framework bundle.`, "success");
  } catch (error) {
    showMessage(error.message, "error");
  }
}

function applyTemplate(templateId) {
  const template = CREATOR_TEMPLATES[templateId];
  if (!template) {
    return;
  }
  const source = {
    id: "",
    name: "",
    kind: "fakemon",
    category: template.category || "",
    types: uniqueTypes([template.type1, template.type2]),
    base_stats: normalizeStats(template.base_stats),
    growth_rate: namedCatalogEntry("growth_rates", template.growth_rate || "Medium"),
    gender_ratio: namedCatalogEntry("gender_ratios", template.gender_ratio || "Female50Percent"),
    abilities: normalizeNamedList((template.abilities || []).map((id) => namedCatalogEntry("abilities", id))),
    hidden_abilities: normalizeNamedList((template.hidden_abilities || []).map((id) => namedCatalogEntry("abilities", id))),
    egg_groups: normalizeNamedList((template.egg_groups || ["Field"]).map((id) => namedCatalogEntry("egg_groups", id))),
    base_exp: template.base_exp || 64,
    catch_rate: template.catch_rate || 45,
    happiness: template.happiness || 70,
    hatch_steps: template.hatch_steps || 5120,
    height: template.height || 6,
    weight: template.weight || 60,
    color: namedCatalogEntry("body_colors", template.color || "Red"),
    shape: namedCatalogEntry("body_shapes", template.shape || "Head"),
    habitat: namedCatalogEntry("habitats", template.habitat || "None"),
    generation: template.generation || 9,
    starter_eligible: Boolean(template.starter_eligible),
    encounter_eligible: Boolean(template.encounter_eligible),
    trainer_eligible: Boolean(template.trainer_eligible),
    fusion_rule: template.fusion_rule || "blocked",
    pokedex_entry: template.pokedex_entry || "",
    moves: normalizeMoveList((template.moves || []).map((move) => ({ level: move.level, ...moveCatalogEntry(move.move) }))),
    tm_moves: normalizeMoveList((template.tm_moves || []).map((id) => moveCatalogEntry(id))),
    tutor_moves: normalizeMoveList((template.tutor_moves || []).map((id) => moveCatalogEntry(id))),
    egg_moves: normalizeMoveList((template.egg_moves || []).map((id) => moveCatalogEntry(id))),
    evolutions: [],
    world_data: normalizeWorldData({}),
    fusion_meta: normalizeFusionMeta({ rule: template.fusion_rule || "blocked" }, template.fusion_rule || "blocked"),
    export_meta: normalizeExportMeta({})
  };
  newSpeciesDraft(source, { nameSuffix: "", templateLabel: titleizeToken(templateId) });
  showMessage(`Loaded the ${titleizeToken(templateId)} template into a new draft.`, "success");
}

async function cloneSelectedDexSpecies() {
  let entry = selectedDexEntry();
  if (!entry) {
    showMessage("Select a species in the Pokédex first.", "error");
    return;
  }
  entry = await ensureDexSpeciesDetail(entry.id, { silent: true }) || entry;
  newSpeciesDraft(entry, {
    kind: "regional_variant",
    nameSuffix: " Variant",
    templateLabel: `Regional variant of ${entry.name}`,
    variantScope: "single_species",
    variantFamily: ""
  });
  showMessage(`Started a regional variant draft from ${entry.name}. It begins as a single-species variant, so the rest of the line stays unchanged unless you expand it.`, "success");
}

async function cloneSelectedDexSpeciesAsFakemon() {
  let entry = selectedDexEntry();
  if (!entry) {
    showMessage("Select a species in the Pokédex first.", "error");
    return;
  }
  entry = await ensureDexSpeciesDetail(entry.id, { silent: true }) || entry;
  newSpeciesDraft(entry, { kind: "fakemon", nameSuffix: " Copy" });
  showMessage(`Cloned ${entry.name} into the creator as a Fakemon-style template.`, "success");
}

function setCompareSlot(side) {
  const entry = selectedDexEntry();
  if (!entry) {
    showMessage("Select a species in the Pokédex first.", "error");
    return;
  }
  state.dexCompareIds[side] = entry.id;
  renderDexSpeciesList();
  renderPokedexPanels();
}

function clearComparison() {
  state.dexCompareIds = { left: null, right: null };
  renderDexSpeciesList();
  renderPokedexPanels();
}

function clearDexFilters() {
  setValue("dexSearch", "");
  setValue("dexTypeFilter", "");
  setValue("dexKindFilter", "all");
  setValue("dexAbilityFilter", "");
  setValue("dexSort", "dex");
  renderDexSpeciesList();
}

function updateKindUi() {
  const isRegional = document.getElementById("kind").value === "regional_variant";
  const sourceMode = document.getElementById("variantSourceMode").value || "species";
  document.getElementById("regionalFields").classList.toggle("hidden", !isRegional);
  document.getElementById("regionalSingleSourceFields").classList.toggle("hidden", !isRegional || sourceMode === "fusion");
  document.getElementById("regionalFusionSourceFields").classList.toggle("hidden", !isRegional || sourceMode !== "fusion");
  document.getElementById("kindBadge").textContent = isRegional ? "Regional Variant" : "Fakemon";
  syncRegionalFusionFields();
}

function syncRegionalFusionFields() {
  const fusionBaseInput = document.getElementById("variantFusionBase");
  if (!fusionBaseInput) {
    return;
  }
  const isRegional = document.getElementById("kind").value === "regional_variant";
  const sourceMode = document.getElementById("variantSourceMode").value || "species";
  if (!isRegional || sourceMode !== "fusion") {
    fusionBaseInput.value = "";
    return;
  }
  const headEntry = fusionComponentEntryById(document.getElementById("variantFusionHead").value);
  const bodyEntry = fusionComponentEntryById(document.getElementById("variantFusionBody").value);
  const fusionSymbol = headEntry && bodyEntry ? buildFusionSymbol(bodyEntry.id_number, headEntry.id_number) : "";
  fusionBaseInput.value = fusionSymbol;
  if (fusionSymbol) {
    document.getElementById("baseSpecies").value = fusionSymbol;
    document.getElementById("fallbackSpecies").value = fusionSymbol;
  }
}

function updateSummaryBadges() {
  const existingId = document.getElementById("existingId").value;
  const currentEntry = state.species.find((entry) => entry.id === existingId);
  document.getElementById("slotBadge").textContent = currentEntry ? `Slot ${currentEntry.slot}` : (document.getElementById("name").value.trim() ? "New Draft" : "Unsaved");
}

function updateBst() {
  document.getElementById("bstValue").textContent = String(calculateBst({
    HP: Number(document.getElementById("statHp").value || 0),
    ATTACK: Number(document.getElementById("statAttack").value || 0),
    DEFENSE: Number(document.getElementById("statDefense").value || 0),
    SPECIAL_ATTACK: Number(document.getElementById("statSpecialAttack").value || 0),
    SPECIAL_DEFENSE: Number(document.getElementById("statSpecialDefense").value || 0),
    SPEED: Number(document.getElementById("statSpeed").value || 0)
  }));
}

function handleFormMutation() {
  if (!state.suspendHistory) {
    queueHistorySnapshot();
  }
  persistAutosaveSoon();
  refreshWorkspace();
}

async function fetchAssetDataUrl(path) {
  const cleanPath = String(path || "").trim().split("?")[0];
  if (!cleanPath) {
    throw new Error("Choose an installed sprite path first.");
  }
  if (state.assetDataCache.has(cleanPath)) {
    return state.assetDataCache.get(cleanPath);
  }
  if (state.pendingAssetData.has(cleanPath)) {
    return state.pendingAssetData.get(cleanPath);
  }
  const pending = fetchJson(`/api/asset-data?path=${encodeURIComponent(cleanPath)}`, { allowError: true, timeoutMs: 15000 })
    .then((result) => {
      if (!result.ok || !result.data?.ok || !result.data?.data_url) {
        throw new Error(result.data?.error || "The selected installed sprite could not be read.");
      }
      state.assetDataCache.set(cleanPath, result.data.data_url);
      return result.data.data_url;
    })
    .finally(() => {
      state.pendingAssetData.delete(cleanPath);
    });
  state.pendingAssetData.set(cleanPath, pending);
  return pending;
}

async function handleDraftVariantGalleryClick(event) {
  const button = event.target.closest("[data-variant-kind][data-variant-path]");
  if (!button) {
    return;
  }
  const assetKind = button.dataset.variantKind;
  const assetPath = button.dataset.variantPath;
  const assetLabel = button.dataset.variantLabel || titleizeToken(assetKind);
  try {
    const dataUrl = await fetchAssetDataUrl(assetPath);
    const pngDataUrl = typeof dataUrl === "string" && dataUrl.startsWith("data:image/png")
      ? dataUrl
      : await convertDataUrlToPng(dataUrl, assetLabel);
    if (assetKind === "front") {
      state.pendingAssets.front_data_url = pngDataUrl;
    } else if (assetKind === "back") {
      state.pendingAssets.back_data_url = pngDataUrl;
    } else if (assetKind === "icon") {
      state.pendingAssets.icon_data_url = pngDataUrl;
    } else {
      return;
    }
    refreshAssetPreviews();
    handleFormMutation();
    showMessage(`Loaded ${assetLabel} into the ${titleizeToken(assetKind)} slot for this draft.`, "success");
  } catch (error) {
    showMessage(error?.message || `Couldn't copy ${assetLabel} into the draft.`, "error");
  }
}

async function handleAssetSelection(event) {
  const file = event.target.files?.[0];
  if (!file) {
    return;
  }
  const dataUrl = await readFileAsPngDataUrl(file);
  if (event.target.id === "frontAsset") {
    state.pendingAssets.front_data_url = dataUrl;
  } else if (event.target.id === "backAsset") {
    state.pendingAssets.back_data_url = dataUrl;
  } else if (event.target.id === "iconAsset") {
    state.pendingAssets.icon_data_url = dataUrl;
  }
  refreshAssetPreviews();
  if (file.type && file.type !== "image/png") {
    showMessage(`${file.name} was converted to PNG automatically for game compatibility.`, "success");
  }
  handleFormMutation();
}

function refreshAssetPreviews() {
  const currentEntry = state.species.find((entry) => entry.id === document.getElementById("existingId").value);
  const normalized = currentEntry ? normalizeCreatorSpeciesEntry(currentEntry) : null;
  setImageSourceWithFallback(
    document.getElementById("frontPreview"),
    state.pendingAssets.front_data_url ? [state.pendingAssets.front_data_url] : visualUrlCandidatesForEntry(normalized, "front")
  );
  setImageSourceWithFallback(
    document.getElementById("backPreview"),
    state.pendingAssets.back_data_url ? [state.pendingAssets.back_data_url] : visualUrlCandidatesForEntry(normalized, "back")
  );
  setImageSourceWithFallback(
    document.getElementById("iconPreview"),
    state.pendingAssets.icon_data_url ? [state.pendingAssets.icon_data_url] : visualUrlCandidatesForEntry(normalized, "icon")
  );
  ["frontAsset", "backAsset", "iconAsset"].forEach((inputId) => {
    document.getElementById(inputId).value = "";
  });
}

function setPreviewFace(face) {
  state.preview.face = face;
  renderLivePreview();
}

function togglePreviewShiny() {
  state.preview.shiny = !state.preview.shiny;
  renderLivePreview();
}

function previewImageUrl(entry) {
  return previewImageCandidates(entry)[0] || BLANK_IMAGE;
}

function previewIconUrl(entry) {
  return previewIconCandidates(entry)[0] || BLANK_IMAGE;
}

function previewImageCandidates(entry) {
  if (!entry) {
    return [BLANK_IMAGE];
  }
  const desiredFace = state.preview.face === "back" ? "back" : "front";
  const candidates = [];
  if (desiredFace === "front" && state.pendingAssets.front_data_url) {
    candidates.push(state.pendingAssets.front_data_url);
  }
  if (desiredFace === "back" && state.pendingAssets.back_data_url) {
    candidates.push(state.pendingAssets.back_data_url);
  }
  if (desiredFace === "back" && state.pendingAssets.front_data_url) {
    candidates.push(state.pendingAssets.front_data_url);
  }
  if (state.preview.shiny) {
    const shinyKind = desiredFace === "back" ? "shiny_back" : "shiny_front";
    candidates.push(entry.visuals?.[shinyKind]);
  }
  candidates.push(...visualUrlCandidatesForEntry(entry, desiredFace));
  if (desiredFace === "back") {
    candidates.push(...visualUrlCandidatesForEntry(entry, "front"));
  }
  return uniqueAssetCandidates(candidates);
}

function previewIconCandidates(entry) {
  const candidates = [];
  if (state.pendingAssets.icon_data_url) {
    candidates.push(state.pendingAssets.icon_data_url);
  }
  if (state.pendingAssets.front_data_url) {
    candidates.push(state.pendingAssets.front_data_url);
  }
  candidates.push(...visualUrlCandidatesForEntry(entry, "icon"));
  return uniqueAssetCandidates(candidates);
}

function setImageSourceWithFallback(element, candidates) {
  if (!element) {
    return;
  }
  const queue = uniqueAssetCandidates(candidates);
  if (queue.length === 0) {
    element.onerror = null;
    element.onload = null;
    element.src = BLANK_IMAGE;
    return;
  }

  const token = `${Date.now()}-${Math.random()}`;
  element.dataset.imageToken = token;
  let index = 0;

  const loadNext = async () => {
    if (element.dataset.imageToken !== token) {
      return;
    }
    if (index >= queue.length) {
      element.onerror = null;
      element.onload = null;
      element.src = BLANK_IMAGE;
      return;
    }
    try {
      const resolved = await resolveRenderableImageSource(queue[index]);
      if (element.dataset.imageToken !== token) {
        return;
      }
      element.src = resolved || BLANK_IMAGE;
    } catch (error) {
      index += 1;
      loadNext();
    }
  };

  element.onload = () => {
    if (element.dataset.imageToken === token) {
      element.onerror = null;
    }
  };
  element.onerror = () => {
    if (element.dataset.imageToken !== token) {
      return;
    }
    index += 1;
    loadNext();
  };
  loadNext();
}

async function resolveRenderableImageSource(candidate) {
  const normalized = normalizeAssetCandidate(candidate);
  if (!normalized || normalized === BLANK_IMAGE) {
    return BLANK_IMAGE;
  }

  const assetPath = normalized.split("?")[0];
  if (!assetPath.startsWith("/game/") && !assetPath.startsWith("/mod/")) {
    return normalized;
  }
  return normalized;
}

function visualUrlForEntry(entry, kind) {
  return visualUrlCandidatesForEntry(entry, kind)[0] || BLANK_IMAGE;
}

function visualUrlCandidatesForEntry(entry, kind, visited = new Set()) {
  if (!entry) {
    return [];
  }
  const entryId = String(entry.id || "").trim();
  if (entryId && visited.has(entryId)) {
    return [];
  }
  const traversal = new Set(visited);
  if (entryId) {
    traversal.add(entryId);
  }
  const visuals = entry.visuals || {};
  const rawCandidates = [];
  const derivedCandidates = derivedGameVisualCandidates(entry, kind);
  if (entry.source === "base_game") {
    rawCandidates.push(...derivedCandidates);
  }
  if (kind === "icon") {
    rawCandidates.push(visuals.icon, visuals.front);
  } else if (kind === "back") {
    rawCandidates.push(visuals.back, visuals.front, visuals.icon);
  } else {
    rawCandidates.push(visuals.front, visuals.icon);
  }
  if (entry.source !== "base_game") {
    rawCandidates.push(...derivedCandidates);
  }
  rawCandidates.push(...fallbackVisualCandidatesForEntry(entry, kind, traversal));
  return uniqueAssetCandidates(rawCandidates);
}

function fallbackVisualCandidatesForEntry(entry, kind, visited = new Set()) {
  const fallbackId = entry?.fallback_species?.id || entry?.base_species?.id || "";
  if (!fallbackId || visited.has(fallbackId) || fallbackId === entry?.id) {
    return [];
  }
  const fallbackEntry = speciesEntryById(fallbackId);
  if (!fallbackEntry) {
    return [];
  }
  return visualUrlCandidatesForEntry(fallbackEntry, kind, visited);
}

function derivedGameVisualCandidates(entry, kind) {
  const idNumber = Number(entry?.id_number || 0);
  const internalId = String(entry?.id || "").trim();
  const candidates = [];
  const fusionParts = parseFusionSymbol(internalId);
  if (fusionParts) {
    if (kind === "icon") {
      candidates.push(`/game/Graphics/Pokemon/FusionIcons/icon${idNumber}.png`);
      candidates.push(`/game/Graphics/Icons/icon${idNumber}.png`);
      return candidates;
    }
    candidates.push(`/game/Graphics/Battlers/${fusionParts.headDex}/${fusionParts.headDex}.${fusionParts.bodyDex}.png`);
    return candidates;
  }
  if (kind === "icon") {
    if (internalId) {
      candidates.push(`/game/Graphics/Pokemon/Icons/${internalId}.png`);
    }
    if (idNumber > 0) {
      candidates.push(`/game/Graphics/Icons/icon${idNumber}.png`);
    }
    return candidates;
  }

  if (idNumber > 0) {
    candidates.push(`/game/Graphics/BaseSprites/${idNumber}.png`);
    candidates.push(`/game/Graphics/Battlers/${idNumber}/${idNumber}.png`);
  }
  if (internalId) {
    candidates.push(`/game/Graphics/Pokemon/${kind === "back" ? "Back" : "Front"}/${internalId}.png`);
  }
  return candidates;
}

function uniqueAssetCandidates(candidates) {
  const seen = new Set();
  return (candidates || [])
    .flatMap(expandAssetCandidateVariants)
    .map(normalizeAssetCandidate)
    .filter((candidate) => {
      if (!candidate || seen.has(candidate)) {
        return false;
      }
      seen.add(candidate);
      return true;
    });
}

function expandAssetCandidateVariants(raw) {
  if (!raw) {
    return [raw];
  }
  const text = String(raw).trim();
  if (!text) {
    return [raw];
  }
  const withoutQuery = text.split("?")[0];
  const baseSpriteMatch = withoutQuery.match(/^(\/game\/Graphics\/BaseSprites\/(\d+))[A-Za-z]+\.png$/i);
  if (baseSpriteMatch) {
    return [`${baseSpriteMatch[1]}.png`, text];
  }
  return [raw];
}

function normalizeAssetCandidate(raw) {
  if (!raw) {
    return null;
  }
  const text = String(raw).trim();
  if (!text) {
    return null;
  }
  if (text === BLANK_IMAGE) {
    return null;
  }
  if (text.startsWith("data:")) {
    return text;
  }
  return text.includes("?") ? text : `${text}?v=${state.assetNonce}`;
}

function resolveStudioAssetUrl(path) {
  if (!path) {
    return BLANK_IMAGE;
  }
  const raw = String(path).trim();
  if (!raw) {
    return BLANK_IMAGE;
  }
  if (raw.startsWith("data:") || raw.startsWith("http://") || raw.startsWith("https://") || raw.startsWith("/")) {
    return raw;
  }

  const clean = raw.replace(/\\/g, "/");
  const ensureImageExtension = (value) => (/\.[a-z0-9]+$/i.test(value) ? value : `${value}.png`);
  if (/^[A-Za-z]:\//.test(clean)) {
    const modMarker = "/Mods/custom_species_framework/";
    const gameMarker = "/Graphics/";
    const modIndex = clean.indexOf(modMarker);
    if (modIndex >= 0) {
      return `/mod/${ensureImageExtension(clean.slice(modIndex + modMarker.length))}`;
    }
    const gameIndex = clean.indexOf(gameMarker);
    if (gameIndex >= 0) {
      return `/game/Graphics/${ensureImageExtension(clean.slice(gameIndex + gameMarker.length))}`;
    }
    return BLANK_IMAGE;
  }

  if (clean.startsWith("Graphics/")) {
    return `/mod/${ensureImageExtension(clean)}`;
  }
  return `/mod/${ensureImageExtension(clean.replace(/^\/+/, ""))}`;
}

function modAssetUrl(relativePath) {
  return resolveStudioAssetUrl(relativePath);
}

function computeValidation(payload) {
  const errors = [];
  const warnings = [];
  const suggestions = [];
  const existingId = document.getElementById("existingId").value;
  const normalizedInternalId = buildSuggestedInternalId(payload.internal_id || payload.name || "CUSTOMMON");
  const duplicate = state.species.find((entry) => entry.id === normalizedInternalId && entry.id !== existingId);
  const bst = calculateBst({
    HP: Number(payload.hp || 0),
    ATTACK: Number(payload.attack || 0),
    DEFENSE: Number(payload.defense || 0),
    SPECIAL_ATTACK: Number(payload.special_attack || 0),
    SPECIAL_DEFENSE: Number(payload.special_defense || 0),
    SPEED: Number(payload.speed || 0)
  });
  const regionalSource = fusionSourceStateFromPayload(payload);
  const canReuseBaseArt = Boolean(regionalSource.canReuseBaseArt);

  if (!payload.name) {
    errors.push({ title: "Display name required", body: "Every species needs a visible in-game name." });
  }
  if (!payload.internal_id) {
    errors.push({ title: "Internal ID required", body: "The framework needs a stable internal identifier before the species can be saved." });
  }
  if (duplicate) {
    errors.push({ title: "Duplicate internal ID", body: `${normalizedInternalId} is already used by another creator species.` });
  }
  if (!payload.primary_ability) {
    errors.push({ title: "Primary ability required", body: "At least one valid ability must be assigned." });
  }
  if (!payload.moves.length) {
    errors.push({ title: "Level-up learnset required", body: "Add at least one level-up move so the species can function in battle safely." });
  }
  if (payload.starter_eligible && !payload.moves.some((move) => Number(move.level || 99) <= 5)) {
    errors.push({ title: "Starter moves missing", body: "Starter-eligible species need at least one move available by level 5." });
  }
  if (payload.kind === "regional_variant" && !regionalSource.ready) {
    errors.push({ title: "Base species required", body: "Regional variants must reference an installed Pokémon they can safely coexist beside." });
  }
  if (!existingId && !state.pendingAssets.front_data_url && !canReuseBaseArt) {
    errors.push({ title: "Front sprite required", body: "A new species needs front art before it can be saved cleanly into the framework." });
  }

  if (bst < 180) {
    warnings.push({ title: "Very low BST", body: `The current stat total is ${bst}, which is far below most battle-ready species.` });
  }
  if (bst > 720) {
    warnings.push({ title: "Very high BST", body: `The current stat total is ${bst}, which is above standard non-form species ranges.` });
  }
  if (payload.starter_eligible && payload.fusion_rule !== "blocked") {
    warnings.push({ title: "Starter fusion rule", body: "Official-style starter trios are usually blocked from fusion in this framework to avoid broken preview/output states." });
  }
  if (!payload.hidden_ability) {
    suggestions.push({ title: "Hidden ability missing", body: "Consider adding a hidden ability for broader balance and encounter variety." });
  }
  if (!payload.pokedex_entry) {
    suggestions.push({ title: "Pokédex entry missing", body: "A short in-game dex entry helps the species feel like a complete official entry once it reaches the bedroom PC." });
  }
  if (payload.kind === "regional_variant" && canReuseBaseArt && !state.pendingAssets.front_data_url) {
    suggestions.push({ title: "Using inherited base art", body: "This regional variant will reuse the original species visuals until you upload replacement art, which is fine for the guided first-run workflow." });
  }
  if (!payload.export_pack_name) {
    suggestions.push({ title: "Export pack name missing", body: "Adding a pack name makes shared export bundles easier to track later." });
  }
  if (!payload.tm_moves.length && !payload.tutor_moves.length) {
    suggestions.push({ title: "Sparse move coverage", body: "TM or tutor compatibility can help the species feel more complete in the wider game." });
  }

  return { errors, warnings, suggestions };
}

function computeRoleEstimate(stats) {
  const safe = normalizeStats(stats);
  const offense = safe.ATTACK + safe.SPECIAL_ATTACK;
  const bulk = safe.HP + safe.DEFENSE + safe.SPECIAL_DEFENSE;
  const speed = safe.SPEED;
  if (speed >= 95 && offense >= bulk * 0.55) {
    return { title: "Fast Attacker", summary: "This spread leans into tempo, offensive pressure, and early initiative." };
  }
  if (bulk >= 240 && speed <= 70) {
    return { title: "Bulky Anchor", summary: "This spread looks comfortable soaking hits and stabilizing longer battles." };
  }
  if (safe.SPECIAL_ATTACK - safe.ATTACK >= 25) {
    return { title: "Special Attacker", summary: "The stat line clearly favors special damage and supportive coverage." };
  }
  if (safe.ATTACK - safe.SPECIAL_ATTACK >= 25) {
    return { title: "Physical Attacker", summary: "The stat line leans toward physical pressure and contact-based move options." };
  }
  return { title: "Balanced", summary: "The spread is flexible and can support several battle roles depending on moves and abilities." };
}

function describeTypeCoverage(types) {
  if (!types.length) {
    return {
      offense: "No STAB types set yet",
      defense: "No defensive profile available yet",
      weaknesses: [],
      resistances: []
    };
  }
  const strong = new Set();
  types.forEach((type) => {
    (TYPE_EFFECTIVENESS[type]?.strong || []).forEach((target) => strong.add(titleizeToken(target)));
  });
  const weaknesses = [];
  const resistances = [];
  Object.keys(TYPE_EFFECTIVENESS).forEach((attackType) => {
    const multiplier = types.reduce((product, defendType) => product * typeMultiplier(attackType, defendType), 1);
    if (multiplier > 1) weaknesses.push(titleizeToken(attackType));
    if (multiplier < 1 && multiplier > 0) resistances.push(titleizeToken(attackType));
  });
  return {
    offense: `STAB threatens ${strong.size} types super-effectively`,
    defense: weaknesses.length ? `Weak to ${weaknesses.length} attacking types` : "No standard weaknesses",
    weaknesses,
    resistances
  };
}

function typeMultiplier(attackType, defendType) {
  const chart = TYPE_EFFECTIVENESS[attackType];
  if (!chart) {
    return 1;
  }
  if (chart.immune.includes(defendType)) {
    return 0;
  }
  if (chart.strong.includes(defendType)) {
    return 2;
  }
  if (chart.weak.includes(defendType)) {
    return 0.5;
  }
  return 1;
}

function describeEvolutionCurve(entry) {
  const nodes = familyNodes(entry);
  if (nodes.length <= 1) {
    return "No multi-stage curve is stored for this species yet.";
  }
  return nodes.map((node) => `${node.name} (${node.bst || "?"})`).join(" -> ");
}

function buildEvolutionTreeNodes(entry) {
  const nodes = [];
  const family = familyNodes(entry);
  family.forEach((node, index) => {
    if (index > 0) {
      nodes.push({ type: "arrow", label: "→" });
    }
    nodes.push({ type: "node", label: `${node.name} (${node.bst || "?"})` });
  });
  return nodes;
}

function familyNodes(entry) {
  const map = new Map();
  const current = entry || currentDraftViewerEntry();
  const currentNode = { id: current.id, name: current.name, id_number: current.id_number, bst: current.bst };
  map.set(currentNode.id, currentNode);
  const singleSpeciesRegional = current.kind === "regional_variant" && (current.variant_scope || "single_species") !== "lineage";
  if (singleSpeciesRegional) {
    if (current.base_species?.id) {
      const baseResolved = speciesEntryById(current.base_species.id);
      map.set(current.base_species.id, {
        id: current.base_species.id,
        name: current.base_species.name,
        id_number: current.base_species.id_number || baseResolved?.id_number || 0,
        bst: baseResolved?.bst || 0
      });
    }
    if (current.fallback_species?.id && current.fallback_species.id !== current.base_species?.id) {
      const fallbackResolved = speciesEntryById(current.fallback_species.id);
      map.set(current.fallback_species.id, {
        id: current.fallback_species.id,
        name: current.fallback_species.name,
        id_number: current.fallback_species.id_number || fallbackResolved?.id_number || 0,
        bst: fallbackResolved?.bst || 0
      });
    }
    return [...map.values()].sort((a, b) => (a.id_number || 999999) - (b.id_number || 999999));
  }
  (current.family_species || []).forEach((species) => {
    const resolved = speciesEntryById(species.id);
    map.set(species.id, {
      id: species.id,
      name: species.name,
      id_number: species.id_number || resolved?.id_number || 0,
      bst: resolved?.bst || 0
    });
  });
  (current.evolutions || []).forEach((evo) => {
    if (!evo.species?.id) {
      return;
    }
    const resolved = speciesEntryById(evo.species.id);
    map.set(evo.species.id, {
      id: evo.species.id,
      name: evo.species.name,
      id_number: evo.species.id_number || resolved?.id_number || 0,
      bst: resolved?.bst || 0
    });
  });
  return [...map.values()].sort((a, b) => (a.id_number || 999999) - (b.id_number || 999999));
}

function renderEvolutionChainHtml(entry) {
  const nodes = buildEvolutionTreeNodes(entry);
  if (!nodes.length) {
    return "No evolution data yet.";
  }
  return nodes.map((node) => {
    if (node.type === "arrow") {
      return `<span class="tree-arrow">${escapeHtml(node.label)}</span>`;
    }
    return `<span class="tree-node">${escapeHtml(node.label)}</span>`;
  }).join("");
}

function renderMoveColumn(title, moves, showLevels = false) {
  return `
    <article class="info-card">
      <h4>${escapeHtml(title)}</h4>
      <div class="move-list">
        ${moves.length ? moves.slice(0, 18).map((move) => `
          <div class="move-pill">
            <strong>${escapeHtml(move.name || move.id || "Unknown Move")}</strong>
            <span>${showLevels && typeof move.level !== "undefined" ? `Lv. ${escapeHtml(String(move.level))} · ` : ""}${escapeHtml(move.type ? `${titleizeToken(move.type)} · ${move.category_name || ""}` : move.id || "")}</span>
          </div>
        `).join("") : `<p class="muted-copy">No ${escapeHtml(title.toLowerCase())} data.</p>`}
      </div>
    </article>
  `;
}

function renderStatsBars(stats) {
  const order = [
    ["HP", "HP"],
    ["ATTACK", "Attack"],
    ["DEFENSE", "Defense"],
    ["SPECIAL_ATTACK", "Sp. Atk"],
    ["SPECIAL_DEFENSE", "Sp. Def"],
    ["SPEED", "Speed"]
  ];
  return order.map(([key, label]) => {
    const value = Number(stats[key] || 0);
    const width = Math.max(6, Math.min(100, Math.round((value / 180) * 100)));
    return `
      <div class="stat-bar">
        <div class="stat-label-row"><span>${escapeHtml(label)}</span><strong>${escapeHtml(String(value))}</strong></div>
        <div class="stat-track"><div class="stat-fill" style="width:${width}%"></div></div>
      </div>
    `;
  }).join("");
}

function renderTypeChips(types) {
  if (!types.length) {
    return `<span class="type-chip" style="background:#919aa2">Unknown</span>`;
  }
  return types.map((type) => `<span class="type-chip" style="background:${escapeAttribute(TYPE_COLORS[type] || "#919aa2")}">${escapeHtml(titleizeToken(type))}</span>`).join("");
}

function renderKeyValueRow(label, value) {
  return `<div class="key-value-row"><span>${escapeHtml(String(label))}</span><strong>${escapeHtml(String(value))}</strong></div>`;
}

function parameterAsInput(parameter) {
  if (!parameter) {
    return "";
  }
  if (typeof parameter === "string" || typeof parameter === "number") {
    return String(parameter);
  }
  return parameter.id || parameter.name || "";
}

function evolutionRequirementText(evolution) {
  const methodName = evolution.method?.name || evolution.method?.id || "Method";
  const parameter = parameterAsInput(evolution.parameter);
  return parameter ? `${methodName} · ${parameter}` : methodName;
}

function buildCreatorFamily(entry) {
  const current = {
    id: entry.id,
    name: entry.name || entry.id,
    id_number: Number(entry.id_number || 0)
  };
  const family = [current];
  if (entry.base_species) {
    family.push(speciesReference(entry.base_species));
  }
  if (entry.fallback_species && entry.fallback_species !== entry.base_species) {
    family.push(speciesReference(entry.fallback_species));
  }
  const variantScope = entry.variant_scope || "single_species";
  if (entry.kind === "regional_variant" && variantScope !== "lineage") {
    const merged = new Map();
    family.filter(Boolean).forEach((member) => merged.set(member.id, member));
    return [...merged.values()];
  }
  (entry.evolutions || []).forEach((evolution) => {
    const reference = speciesReference(evolution.species);
    if (reference) {
      family.push(reference);
    }
  });
  const merged = new Map();
  family.filter(Boolean).forEach((member) => merged.set(member.id, member));
  return [...merged.values()];
}

function queueHistorySnapshot() {
  window.clearTimeout(state.historyTimer);
  state.historyTimer = window.setTimeout(() => captureHistorySnapshot(), 250);
}

function captureHistorySnapshot(force = false) {
  const snapshot = serializeCurrentSnapshot();
  const serialized = JSON.stringify(snapshot);
  if (!force && state.history[state.history.length - 1] === serialized) {
    return;
  }
  state.history.push(serialized);
  if (state.history.length > 100) {
    state.history.shift();
  }
  state.future = [];
  updateUndoRedoButtons();
}

function serializeCurrentSnapshot() {
  return {
    selectedId: state.selectedId,
    existingId: document.getElementById("existingId").value,
    internalIdLocked: document.getElementById("internalId").disabled,
    payload: gatherSpeciesPayload(),
    delivery: gatherDeliveryPayload(),
    pendingAssets: deepClone(state.pendingAssets)
  };
}

function restoreSnapshot(snapshot) {
  state.suspendHistory = true;
  state.selectedId = snapshot.selectedId || null;
  applyDraftToForm(snapshot.payload, {
    existingId: snapshot.existingId || "",
    lockInternalId: Boolean(snapshot.internalIdLocked),
    deliveryPayload: snapshot.delivery || null,
    pendingAssets: snapshot.pendingAssets || { front_data_url: null, back_data_url: null, icon_data_url: null }
  });
  state.suspendHistory = false;
  refreshWorkspace();
}

function undoDraft() {
  if (state.history.length <= 1) {
    return;
  }
  const current = state.history.pop();
  state.future.push(current);
  const previous = state.history[state.history.length - 1];
  restoreSnapshot(JSON.parse(previous));
  updateUndoRedoButtons();
}

function redoDraft() {
  if (!state.future.length) {
    return;
  }
  const next = state.future.pop();
  state.history.push(next);
  restoreSnapshot(JSON.parse(next));
  updateUndoRedoButtons();
}

function updateUndoRedoButtons() {
  document.getElementById("undoBtn").disabled = state.history.length <= 1;
  document.getElementById("redoBtn").disabled = state.future.length === 0;
}

function persistAutosaveSoon() {
  window.clearTimeout(state.autosaveTimer);
  state.autosaveTimer = window.setTimeout(persistAutosave, 350);
}

function persistAutosave() {
  try {
    localStorage.setItem(state.autosaveKey, JSON.stringify({
      snapshot: serializeCurrentSnapshot(),
      timestamp: Date.now()
    }));
  } catch (_error) {
    // Ignore localStorage failures in unsupported browsers.
  }
}

function restoreAutosaveIfAvailable() {
  try {
    const raw = localStorage.getItem(state.autosaveKey);
    if (!raw) {
      return false;
    }
    const data = JSON.parse(raw);
    if (!data?.snapshot?.payload) {
      return false;
    }
    restoreSnapshot(data.snapshot);
    captureHistorySnapshot(true);
    showMessage("Restored your last autosaved draft from this browser.", "success");
    return true;
  } catch (_error) {
    return false;
  }
}

function applyEvolutionParameterUi(row) {
  const methodId = row.querySelector(".row-method").value;
  const parameterField = row.querySelector(".row-parameter");
  const config = evolutionParameterUiConfig(methodId);
  parameterField.type = config.type || "text";
  parameterField.placeholder = config.placeholder || "";
  parameterField.disabled = Boolean(config.disabled);
  if (config.listId) {
    parameterField.setAttribute("list", config.listId);
  } else {
    parameterField.removeAttribute("list");
  }
  if (typeof config.min !== "undefined") {
    parameterField.min = String(config.min);
  } else {
    parameterField.removeAttribute("min");
  }
  if (typeof config.step !== "undefined") {
    parameterField.step = String(config.step);
  } else {
    parameterField.removeAttribute("step");
  }
  if (config.disabled) {
    parameterField.value = "";
  }
}

function evolutionParameterUiConfig(methodId) {
  const methodEntry = catalogEntries("evolution_methods").find((entry) => entry.id === methodId) || null;
  const parameterKind = methodEntry?.parameter_kind || "";
  if (!parameterKind) {
    return { disabled: true, placeholder: "No extra parameter needed" };
  }
  switch (parameterKind) {
    case "Integer":
      return { type: "number", min: 0, step: 1, placeholder: "Number" };
    case "Item":
      return { type: "text", listId: "item-options", placeholder: "THUNDERSTONE" };
    case "Move":
      return { type: "text", listId: "move-options", placeholder: "ANCIENTPOWER" };
    case "Type":
      return { type: "text", listId: "type-options", placeholder: "DARK" };
    case "Species":
      return { type: "text", listId: "species-options", placeholder: "REMORAID" };
    default:
      return { type: "text", placeholder: `Enter ${titleizeToken(parameterKind)}` };
  }
}

function normalizeInternalIdField() {
  const field = document.getElementById("internalId");
  if (!field || field.disabled) {
    return;
  }
  const normalized = buildSuggestedInternalId(field.value || document.getElementById("name").value);
  field.value = normalized;
  state.lastSuggestedInternalId = normalized;
}

function maybeSuggestInternalId(force = false) {
  const existingId = document.getElementById("existingId").value;
  const field = document.getElementById("internalId");
  if (existingId || field.disabled) {
    return;
  }
  const suggestion = buildSuggestedInternalId(document.getElementById("name").value);
  if (force || !field.value.trim() || field.value === state.lastSuggestedInternalId) {
    field.value = suggestion;
  }
  state.lastSuggestedInternalId = suggestion;
}

function buildSuggestedInternalId(value) {
  const token = normalizeToken(value) || "CUSTOMMON";
  return token.startsWith("CSF_") ? token : `CSF_${token}`;
}

function moveCatalogEntry(id) {
  const entry = catalogEntries("moves").find((move) => move.id === id);
  if (entry) {
    return entry;
  }
  return { id, name: titleizeToken(id || "MOVE"), type: "", category_name: "" };
}

function evolutionMethodEntry(id) {
  const entry = catalogEntries("evolution_methods").find((method) => method.id === id);
  if (entry) {
    return entry;
  }
  return { id, name: titleizeToken(id || "Method") };
}

function speciesEntryById(id) {
  const normalizedId = normalizeLookupValue(id);
  if (!normalizedId) {
    return null;
  }
  const syntheticEntry = state.syntheticDexEntries.get(normalizedId);
  if (syntheticEntry) {
    return syntheticEntry;
  }
  const directEntry = mergedDexEntries().find((entry) => entry.id === normalizedId) || null;
  if (directEntry) {
    return directEntry;
  }
  if (isFusionSymbol(normalizedId)) {
    return buildFusionSpeciesEntryFromSymbol(normalizedId);
  }
  return null;
}

function normalizeFusionSourceValue(value) {
  if (!value) {
    return null;
  }
  if (typeof value === "object" && value.head && value.body) {
    return {
      head: normalizeSpeciesReference(value.head),
      body: normalizeSpeciesReference(value.body)
    };
  }
  const parsed = parseFusionSymbol(value);
  if (!parsed) {
    return null;
  }
  return {
    head: speciesReference(standardFusionComponentEntryByDexNumber(parsed.headDex)?.id || ""),
    body: speciesReference(standardFusionComponentEntryByDexNumber(parsed.bodyDex)?.id || "")
  };
}

function speciesReference(id) {
  if (!id) {
    return null;
  }
  if (typeof id === "object" && id.id) {
    return normalizeSpeciesReference(id);
  }
  const entry = speciesEntryById(String(id));
  if (entry) {
    return { id: entry.id, name: entry.name, id_number: entry.id_number };
  }
  const parsed = parseFusionSymbol(id);
  if (parsed) {
    const headEntry = standardFusionComponentEntryByDexNumber(parsed.headDex);
    const bodyEntry = standardFusionComponentEntryByDexNumber(parsed.bodyDex);
    const fusionReference = buildFusionReference(headEntry, bodyEntry);
    if (fusionReference) {
      return fusionReference;
    }
  }
  return { id: String(id), name: titleizeToken(String(id)), id_number: 0 };
}

function namedCatalogEntry(key, id) {
  if (!id) {
    return null;
  }
  const entry = catalogEntries(key).find((item) => item.id === id);
  if (entry) {
    return { id: entry.id, name: entry.name || entry.id, description: entry.description || "" };
  }
  return { id, name: titleizeToken(id) };
}

function normalizeNamedEntry(entry) {
  if (!entry) {
    return null;
  }
  if (typeof entry === "string") {
    return { id: entry, name: titleizeToken(entry) };
  }
  return {
    id: entry.id,
    name: entry.name || titleizeToken(entry.id),
    description: entry.description || ""
  };
}

function normalizeNamedList(entries) {
  return (entries || []).map(normalizeNamedEntry).filter(Boolean);
}

function normalizeMoveList(entries) {
  return (entries || []).map((entry) => {
    if (!entry) {
      return null;
    }
    if (typeof entry === "string") {
      return moveCatalogEntry(entry);
    }
    const base = moveCatalogEntry(entry.id || entry.move || "");
    return {
      ...base,
      level: typeof entry.level !== "undefined" ? Number(entry.level) : undefined
    };
  }).filter(Boolean);
}

function normalizeSpeciesReference(entry) {
  if (!entry) {
    return null;
  }
  if (typeof entry === "string") {
    return speciesReference(entry);
  }
  return {
    id: entry.id,
    name: entry.name || titleizeToken(entry.id),
    id_number: Number(entry.id_number || 0)
  };
}

function normalizeSpeciesReferenceList(entries) {
  return (entries || []).map(normalizeSpeciesReference).filter(Boolean);
}

function normalizeEvolutionList(entries) {
  return (entries || []).map((entry) => {
    if (!entry) {
      return null;
    }
    const method = entry.method?.id ? entry.method : evolutionMethodEntry(entry.method || "");
    return {
      species: normalizeSpeciesReference(entry.species),
      method,
      parameter: entry.parameter
    };
  }).filter(Boolean);
}

function evolutionParameterDisplay(parameter, methodId) {
  if (parameter === null || typeof parameter === "undefined") {
    return "";
  }
  if (typeof parameter === "number" || typeof parameter === "string") {
    return parameter;
  }
  if (parameter.id) {
    return parameter.id;
  }
  return parameter;
}

function normalizeStats(stats) {
  const source = stats || {};
  return {
    HP: Number(source.HP || 0),
    ATTACK: Number(source.ATTACK || 0),
    DEFENSE: Number(source.DEFENSE || 0),
    SPECIAL_ATTACK: Number(source.SPECIAL_ATTACK || 0),
    SPECIAL_DEFENSE: Number(source.SPECIAL_DEFENSE || 0),
    SPEED: Number(source.SPEED || 0)
  };
}

function calculateBst(stats) {
  const safe = normalizeStats(stats);
  return safe.HP + safe.ATTACK + safe.DEFENSE + safe.SPECIAL_ATTACK + safe.SPECIAL_DEFENSE + safe.SPEED;
}

function normalizeWorldData(worldData = {}) {
  return {
    encounter_rarity: worldData.encounter_rarity || "",
    encounter_zones: normalizeListValue(worldData.encounter_zones),
    trainer_roles: normalizeListValue(worldData.trainer_roles),
    trainer_notes: worldData.trainer_notes || "",
    encounter_level_min: Number(worldData.encounter_level_min || 0),
    encounter_level_max: Number(worldData.encounter_level_max || 0)
  };
}

function normalizeFusionMeta(fusionMeta = {}, fallbackRule = "blocked") {
  return {
    rule: fusionMeta.rule || fallbackRule || "blocked",
    head_offset_x: Number(fusionMeta.head_offset_x || 0),
    head_offset_y: Number(fusionMeta.head_offset_y || 0),
    body_offset_x: Number(fusionMeta.body_offset_x || 0),
    body_offset_y: Number(fusionMeta.body_offset_y || 0),
    naming_notes: fusionMeta.naming_notes || "",
    sprite_hints: fusionMeta.sprite_hints || ""
  };
}

function normalizeExportMeta(exportMeta = {}) {
  return {
    framework_managed: Boolean(exportMeta.framework_managed),
    slot: Number(exportMeta.slot || 0),
    json_filename: exportMeta.json_filename || "",
    recommended_internal_id: exportMeta.recommended_internal_id || "",
    author: exportMeta.author || "",
    version: exportMeta.version || "",
    pack_name: exportMeta.pack_name || "",
    tags: normalizeListValue(exportMeta.tags)
  };
}

function normalizeVisuals(visuals = {}) {
  return {
    front: visuals.front || BLANK_IMAGE,
    back: visuals.back || visuals.front || BLANK_IMAGE,
    icon: visuals.icon || visuals.front || BLANK_IMAGE,
    shiny_front: visuals.shiny_front || "",
    shiny_back: visuals.shiny_back || "",
    overworld: visuals.overworld || "",
    shiny_strategy: visuals.shiny_strategy || "hue_shift"
  };
}

function normalizeListValue(value) {
  if (!value) {
    return [];
  }
  if (Array.isArray(value)) {
    return value.map((entry) => String(entry).trim()).filter(Boolean);
  }
  return String(value)
    .split(/[\r\n,;]+/)
    .map((entry) => entry.trim())
    .filter(Boolean);
}

function uniqueTypes(types) {
  return [...new Set((types || []).map((type) => String(type || "").trim().toUpperCase()).filter(Boolean))];
}

function readFileAsDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(new Error(`Failed to read ${file.name}.`));
    reader.readAsDataURL(file);
  });
}

async function readFileAsPngDataUrl(file) {
  const dataUrl = await readFileAsDataUrl(file);
  if (typeof dataUrl === "string" && dataUrl.startsWith("data:image/png")) {
    return dataUrl;
  }
  return convertDataUrlToPng(dataUrl, file.name);
}

function convertDataUrlToPng(dataUrl, fileName = "image") {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => {
      const canvas = document.createElement("canvas");
      canvas.width = image.naturalWidth || image.width || 1;
      canvas.height = image.naturalHeight || image.height || 1;
      const context = canvas.getContext("2d");
      if (!context) {
        reject(new Error("Could not prepare the image converter for this browser."));
        return;
      }
      context.clearRect(0, 0, canvas.width, canvas.height);
      context.drawImage(image, 0, 0);
      resolve(canvas.toDataURL("image/png"));
    };
    image.onerror = () => reject(new Error(`Failed to convert ${fileName} into a PNG sprite.`));
    image.src = dataUrl;
  });
}

function setValue(id, value) {
  const element = document.getElementById(id);
  if (element) {
    element.value = value ?? "";
  }
}

function setChecked(id, value) {
  const element = document.getElementById(id);
  if (element) {
    element.checked = Boolean(value);
  }
}

function deepClone(value) {
  return JSON.parse(JSON.stringify(value));
}

function normalizeLookupValue(value) {
  return String(value || "").trim();
}

function normalizeToken(value) {
  return String(value || "")
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9_]/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function formatDexNumber(number) {
  if (!number) {
    return "---";
  }
  return String(number).padStart(4, "0");
}

function titleizeToken(token) {
  return String(token || "")
    .replace(/_/g, " ")
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/([A-Za-z])(\d)/g, "$1 $2")
    .replace(/(\d)([A-Za-z])/g, "$1 $2")
    .replace(/\s+/g, " ")
    .trim()
    .toLowerCase()
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function escapeAttribute(value) {
  return escapeHtml(value).replace(/"/g, "&quot;");
}
