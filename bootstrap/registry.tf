resource "yandex_container_registry" "registry-docker" {
    name = var.name-registry   
    folder_id = var.folder_id
}