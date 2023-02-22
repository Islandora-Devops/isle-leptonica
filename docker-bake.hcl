###############################################################################
# Variables
###############################################################################
variable "REPOSITORY" {
  default = "islandora"
}

variable "CACHE_FROM_REPOSITORY" {
  default = "islandora"
}

variable "CACHE_TO_REPOSITORY" {
  default = "islandora"
}

variable "TAG" {
  # "local" is to distinguish that from builds produced locally.
  default = "local"
}

variable "SOURCE_DATE_EPOCH" {
  default = "0"
}

###############################################################################
# Functions
###############################################################################
function hostArch {
  params = []
  result = equal("linux/amd64", BAKE_LOCAL_PLATFORM) ? "amd64" : "arm64" # Only two platforms supported.
}

function "tags" {
  params = [image, arch]
  result = ["${REPOSITORY}/${image}:${TAG}-${arch}"]
}

function "cacheFrom" {
  params = [image, arch]
  result = ["type=registry,ref=${CACHE_FROM_REPOSITORY}/cache:${image}-main-${arch}", "type=registry,ref=${CACHE_FROM_REPOSITORY}/cache:${image}-${TAG}-${arch}"]
}

function "cacheTo" {
  params = [image, arch]
  result =  ["type=registry,oci-mediatypes=true,mode=max,compression=estargz,compression-level=5,ref=${CACHE_TO_REPOSITORY}/cache:${image}-${TAG}-${arch}"]
}

###############################################################################
# Groups
###############################################################################
group "default" {
  targets = [
    "leptonica"
  ]
}

group "amd64" {
  targets = [
    "leptonica-amd64",
  ]
}

group "arm64" {
  targets = [
    "leptonica-arm64",
  ]
}

# CI should build both and push to the remote cache.
group "ci" {
  targets = [
    "leptonica-amd64-ci",
    "leptonica-arm64-ci",
  ]
}

###############################################################################
# Common target properties.
###############################################################################
target "common" {
  args = {
    # Required for reproduciable builds.
    # Requires Buildkit 0.11+
    # See: https://reproducible-builds.org/docs/source-date-epoch/
    SOURCE_DATE_EPOCH = "${SOURCE_DATE_EPOCH}",
  }
}

target "amd64-common" {
  platforms = ["linux/amd64"]
}

target "arm64-common" {
  platforms = ["linux/arm64"]
}

target "leptonica-common" {
  inherits = ["common"]
  context  = "leptonica"
  contexts = {
    # The digest (sha256 hash) is not platform specific but the digest for the manifest of all platforms.
    # It will be the digest printed when you do: docker pull alpine:3.17.1
    # Not the one displayed on DockerHub.
    # N.B. This should match the value used in:
    # - <https://github.com/Islandora-Devops/isle-imagemagick>
    # - <https://github.com/Islandora-Devops/isle-leptonica>
    alpine = "docker-image://alpine:3.17.1@sha256:f271e74b17ced29b915d351685fd4644785c6d1559dd1f2d4189a5e851ef753a"
  }
}

###############################################################################
# Default Image targets for local builds.
###############################################################################
target "leptonica" {
  inherits   = ["leptonica-common"]
  cache-from = cacheFrom("leptonica", hostArch())
  tags       = tags("leptonica", "")
}

###############################################################################
# linux/amd64 targets.
###############################################################################
target "leptonica-amd64" {
  inherits   = ["leptonica-common", "amd64-common"]
  cache-from = cacheFrom("leptonica", "amd64")
  tags       = tags("leptonica", "amd64")
}

target "leptonica-amd64-ci" {
  inherits = ["leptonica-amd64"]
  cache-to = cacheTo("leptonica", "amd64")
}

###############################################################################
# linux/arm64 targets.
###############################################################################
target "leptonica-arm64" {
  inherits   = ["leptonica-common", "arm64-common"]
  cache-from = cacheFrom("leptonica", "arm64")
  tags       = tags("leptonica", "arm64")
}

target "leptonica-arm64-ci" {
  inherits = ["leptonica-arm64"]
  cache-to = cacheTo("leptonica", "arm64")
}