import ProjectDescription

let setup = Setup([
  .homebrew(packages: ["swiftformat", "mockolo"]),
  .custom(name: "Generate mocks", meet: ["./mockolo.sh"], isMet: ["test -f Tests/Mockolo.swift"]),
])
