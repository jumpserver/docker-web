variable "VERSION" {
    default = "dev"
}

variable "BUILD_ARM" {
    default = false
}

variable "LUNA_BRANCH" {
    default = "dev"
}

variable "LINA_BRANCH" {
    default = "dev"
}

variable "PUSH_ENABLED" {
    default = false
}

group "default" {
    targets = ["ce"]
}



target "lina" {
    context = "https://github.com/jumpserver/lina.git#${LINA_BRANCH}"
    dockerfile = "Dockerfile"
    tags = ["jumpserver/lina:${VERSION}"]
    output = ["type=docker"]
    args = {
        VERSION = "${VERSION}"
    }
}

target "luna" {
    dockerfile = "Dockerfile"
    context = "https://github.com/jumpserver/luna.git#${LUNA_BRANCH}"
    tags = ["jumpserver/luna:${VERSION}"]
    output = ["type=docker"]
    args = {
        VERSION = "${VERSION}"
    }
}


target "ce" {
    context = "."
    dockerfile = "Dockerfile"
    tags = ["jumpserver/web:${VERSION}-ce"]
    output = PUSH_ENABLED ? ["type=registry"] : ["type=docker"]
    args = {
        VERSION = "${VERSION}"
    }
    contexts = {
        "jumpserver/lina:${VERSION}" = "target:lina"
        "jumpserver/luna:${VERSION}" = "target:luna"
    }
    VERSION = "${VERSION}"
}

target "ee" {
    context = "."
    dockerfile = "Dockerfile-ee"
    tags = ["jumpserver/web:${VERSION}-ee"]
    output = PUSH_ENABLED ? ["type=registry"] : ["type=docker"]
    args = {
        VERSION = "${VERSION}"
    }
    contexts = {
        "jumpserver/web:${VERSION}-ce" = "target:ce"
    }
    VERSION = "${VERSION}"
}