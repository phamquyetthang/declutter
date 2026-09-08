#!/usr/bin/env bash
register_dev_node() {
  local H="$HOME"
  have npm  && add green pkg-node cmd "npm cache clean --force" \
      "npm cache" "$H/.npm/_cacache"
  have yarn && add green pkg-node cmd "yarn cache clean" \
      "yarn cache" "$H/.cache/yarn" "$H/Library/Caches/Yarn"
  have pnpm && add green pkg-node cmd "pnpm store prune" \
      "pnpm store (chỉ gói mồ côi)" \
      "$H/.local/share/pnpm/store" "$H/Library/pnpm/store"
  have bun  && add green pkg-node cmd "bun pm cache rm" "bun cache" "$H/.bun/install/cache"

  add green  pkg-node rm "" "npx cache" "$H/.npm/_npx"
  add yellow pkg-node rm "" "Electron / electron-builder cache" \
    "$H/.cache/electron" "$H/.electron" "$H/.cache/electron-builder" \
    "$H/Library/Caches/electron" "$H/Library/Caches/electron-builder"
  add red pkg-node note "" \
    "node_modules — xem: declutter --projects" ""
}
