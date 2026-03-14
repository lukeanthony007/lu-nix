const runtime = {
  node: process.version,
  profile: "2026 nix dev environment",
  workspace: "lu-nix",
} as const

console.log(`${runtime.workspace}: ${runtime.profile} on ${runtime.node}`)
