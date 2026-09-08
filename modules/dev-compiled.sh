#!/usr/bin/env bash
# Rust, Go, Java/Gradle/Maven — các hệ build sinh cache lớn.
register_dev_compiled() {
  local H="$HOME"

  add green pkg-rust rm "" "Cargo registry cache (tải lại khi build)" \
    "$H/.cargo/registry/cache" "$H/.cargo/registry/src"
  add red pkg-rust note "" "target/ — xem: declutter --projects" ""

  if have go; then
    add green  pkg-go cmd "go clean -cache -testcache" "Go build + test cache" \
      "$(go env GOCACHE 2>/dev/null)"
    add yellow pkg-go cmd "go clean -modcache" "Go module cache (tải lại lâu)" \
      "$(go env GOMODCACHE 2>/dev/null)"
  fi

  add green  pkg-java findrm "1|build-cache-*" "Gradle build-cache tăng tiến" "$H/.gradle/caches"
  add green  pkg-java rm "" "Gradle daemon log" "$H/.gradle/daemon"
  add yellow pkg-java rm "" "Gradle caches (build sau tải lại dependency)" "$H/.gradle/caches"
  add yellow pkg-java rm "" "Gradle wrapper dists" "$H/.gradle/wrapper/dists"
  add red    pkg-java note "" \
    "Maven repo — có thể chứa artifact tự mvn install" "$H/.m2/repository"
}
