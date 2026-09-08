#!/usr/bin/env bash
register_docker() {
  have docker || return 0
  docker info >/dev/null 2>&1 || return 0

  add green  docker cmd "docker builder prune -af" \
    "$(L "Docker: build cache" "Docker: cache build")" ""
  add green  docker cmd "docker image prune -f" \
    "$(L "Docker: dangling images (<none>)" "Docker: image dangling (<none>)")" ""
  add yellow docker cmd "docker container prune -f" \
    "$(L "Docker: stopped containers" "Docker: container đã dừng")" ""
  add yellow docker cmd "docker image prune -af" \
    "$(L "Docker: images no container uses" "Docker: image không container nào dùng")" ""
  add red    docker note "" \
    "$(L "Docker volumes — they hold databases. Use docker volume rm yourself" \
         "Docker volume — chứa DB. Tự xóa bằng docker volume rm")" ""
}
