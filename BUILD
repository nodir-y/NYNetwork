load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NYNetwork",
    module_name = "NYNetwork",
    srcs = glob([
        "Sources/NYNetwork/**/*.swift",
    ]),
    deps = [
        "Alamofire:Alamofire",
    ],
    visibility = [
        "//visibility:public",
    ],
)
