#!/usr/bin/env bash
register_docker() {
  have docker || return 0
  docker info >/dev/null 2>&1 || return 0

  add green  docker cmd "docker builder prune -af" "Docker: cache build" ""
  add green  docker cmd "docker image prune -f"    "Docker: image dangling (<none>)" ""
  add yellow docker cmd "docker container prune -f" "Docker: container đã dừng" ""
  add yellow docker cmd "docker image prune -af"   "Docker: image không container nào dùng" ""
  add red    docker note "" \
    "Docker volume — chứa DB. Tự xóa bằng docker volume rm" ""
}
