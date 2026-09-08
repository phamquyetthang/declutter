#!/usr/bin/env bash
register_dev_node() {
  local H="$HOME"
  have npm  && add green pkg-node cmd "npm cache clean --force" \
      "$(L "npm cache" "npm cache")" "$H/.npm/_cacache"
  have yarn && add green pkg-node cmd "yarn cache clean" \
      "$(L "yarn cache" "yarn cache")" "$H/.cache/yarn" "$H/Library/Caches/Yarn"
  have pnpm && add green pkg-node cmd "pnpm store prune" \
      "$(L "pnpm store (orphaned packages only)" "pnpm store (chỉ gói mồ côi)")" \
      "$H/.local/share/pnpm/store" "$H/Library/pnpm/store"
  have bun  && add green pkg-node cmd "bun pm cache rm" \
      "$(L "bun cache" "bun cache")" "$H/.bun/install/cache"

  add green  pkg-node rm "" "$(L "npx cache" "npx cache")" "$H/.npm/_npx"
  add yellow pkg-node rm "" \
    "$(L "Electron / electron-builder cache" "Electron / electron-builder cache")" \
    "$H/.cache/electron" "$H/.electron" "$H/.cache/electron-builder" \
    "$H/Library/Caches/electron" "$H/Library/Caches/electron-builder"
  add red pkg-node note "" \
    "$(L "node_modules — see: declutter --projects" \
         "node_modules — xem: declutter --projects")" ""
}
