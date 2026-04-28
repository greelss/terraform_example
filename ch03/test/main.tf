variable "server_list" {
    default = ["web","db","api"]
}

resource "local_file" "config" {
    for_each = toset([for s in var.server_list: s if s != "db"]) 
    content = each.value
    filename = "config-${each.value}.txt"

    provisioner "local-exec" {
        command = "echo Deploy config for ${self.content}"

    }
}  

resource "local_file" "summary" {
    count = 1
    filename = "summary.log"
    content = join(",", [for f in local_file.config : f.filename])
}

output "report" {
    value = [for f in local_file.config : f.id]
}



