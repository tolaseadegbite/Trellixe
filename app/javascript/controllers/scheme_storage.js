// Scoped light/dark/system storage shared by the color-scheme and
// theme-preview controllers. Scheme preference is remembered per
// workspace (keyed by account public id); pages without an account
// (signed-out) use the global slot. The legacy single `color_scheme`
// key migrates into the global slot on first read, so nobody loses
// their current preference.
const MAP_KEY = "color_schemes"
const LEGACY_KEY = "color_scheme"
const GLOBAL_SLOT = "global"

function loadMap() {
  try {
    return JSON.parse(localStorage.getItem(MAP_KEY)) || {}
  } catch {
    return {}
  }
}

function saveMap(map) {
  localStorage.setItem(MAP_KEY, JSON.stringify(map))
}

function migrateLegacy(map) {
  const legacy = localStorage.getItem(LEGACY_KEY)
  if (legacy && map[GLOBAL_SLOT] === undefined) {
    map[GLOBAL_SLOT] = legacy
    saveMap(map)
    localStorage.removeItem(LEGACY_KEY)
  }
  return map
}

function slotFor(accountId) {
  return accountId || GLOBAL_SLOT
}

export function readScheme(accountId) {
  const map = migrateLegacy(loadMap())
  const scoped = map[slotFor(accountId)]
  if (scoped) return scoped
  // New workspaces inherit the global habit; fresh users get "system".
  return map[GLOBAL_SLOT] || "system"
}

export function writeScheme(accountId, value) {
  const map = migrateLegacy(loadMap())
  map[slotFor(accountId)] = value
  saveMap(map)
}
