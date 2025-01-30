variable "SOURCE_DATE_EPOCH" {
  default = "0"
}

variable "REPOSITORY" {
  default = "islandora"
}

variable "TAG" {
  # "local" is to distinguish remote images from those produced locally.
  default = "local"
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
  result = ["type=registry,ref=${REPOSITORY}/cache:${image}-main-${arch}", "type=registry,ref=${REPOSITORY}/cache:${image}-${TAG}-${arch}"]
}

function "cacheTo" {
  params = [image, arch]
  result = ["type=registry,oci-mediatypes=true,mode=max,compression=estargz,compression-level=5,ref=${REPOSITORY}/cache:${image}-${TAG}-${arch}"]
}

###############################################################################
# Groups
###############################################################################
group "default" {
  targets = [
    "leptonica",
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
# Targets
###############################################################################
target "common" {
  args = {
    # Required for reproduciable builds.
    # Requires Buildkit 0.11+
    # See: https://reproducible-builds.org/docs/source-date-epoch/
    SOURCE_DATE_EPOCH = "${SOURCE_DATE_EPOCH}",
  }
}

target "leptonica-common" {
  inherits = ["common"]
  context  = "leptonica"
  contexts = {
    # The digest (sha256 hash) is not platform specific but the digest for the manifest of all platforms.
    # It will be the digest printed when you do: docker pull alpine:3.17.1
    # Not the one displayed on DockerHub.
    # N.B. This should match the value used in <https://github.com/Islandora-Devops/isle-buildkit>
    alpine = "docker-image://alpine:3.21.2@sha256:56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099"
  }
}

target "leptonica-amd64" {
  inherits   = ["leptonica-common"]
  tags       = tags("leptonica", "amd64")
  cache-from = cacheFrom("leptonica", "amd64")
  platforms  = ["linux/amd64"]
}

target "leptonica-amd64-ci" {
  inherits = ["leptonica-amd64"]
  cache-to = cacheTo("leptonica", "amd64")
}

target "leptonica-arm64" {
  inherits   = ["leptonica-common"]
  tags       = tags("leptonica", "arm64")
  cache-from = cacheFrom("leptonica", "arm64")
  platforms  = ["linux/arm64"]
}

target "leptonica-arm64-ci" {
  inherits = ["leptonica-arm64"]
  cache-to = cacheTo("leptonica", "arm64")
}

target "leptonica" {
  inherits   = ["leptonica-common"]
  cache-from = cacheFrom("leptonica", hostArch())
  tags       = tags("leptonica", "")
}
