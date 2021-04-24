import ProjectDescription

let setup = Setup([
  .homebrew(packages: ["swiftformat", "mockolo"]),
  .custom(name: "Mockolo", meet: ["./mockolo.sh"], isMet: ["test -f Tests/Mockolo.swift"]),
])
