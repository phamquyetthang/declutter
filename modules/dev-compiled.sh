#!/usr/bin/env bash
# Rust, Go, Java/Gradle/Maven — build systems with large caches.
register_dev_compiled() {
  local H="$HOME"

  add green pkg-rust rm "" \
    "$(L "Cargo registry cache (re-fetched on build)" \
         "Cargo registry cache (tải lại khi build)")" \
    "$H/.cargo/registry/cache" "$H/.cargo/registry/src"
  add red pkg-rust note "" \
    "$(L "target/ — see: declutter --projects" "target/ — xem: declutter --projects")" ""

  if have go; then
    add green  pkg-go cmd "go clean -cache -testcache" \
      "$(L "Go build + test cache" "Go build + test cache")" \
      "$(go env GOCACHE 2>/dev/null)"
    add yellow pkg-go cmd "go clean -modcache" \
      "$(L "Go module cache (slow to re-download)" \
           "Go module cache (tải lại lâu)")" \
      "$(go env GOMODCACHE 2>/dev/null)"
  fi

  add green  pkg-java findrm "1|build-cache-*" \
    "$(L "Gradle incremental build-cache" "Gradle build-cache tăng tiến")" "$H/.gradle/caches"
  add green  pkg-java rm "" \
    "$(L "Gradle daemon logs" "Gradle daemon log")" "$H/.gradle/daemon"
  add yellow pkg-java rm "" \
    "$(L "Gradle caches (next build re-downloads dependencies)" \
         "Gradle caches (build sau tải lại dependency)")" "$H/.gradle/caches"
  add yellow pkg-java rm "" \
    "$(L "Gradle wrapper distributions" "Gradle wrapper dists")" "$H/.gradle/wrapper/dists"
  add red    pkg-java note "" \
    "$(L "Maven repo — may hold your own mvn install artifacts" \
         "Maven repo — có thể chứa artifact tự mvn install")" "$H/.m2/repository"
}
