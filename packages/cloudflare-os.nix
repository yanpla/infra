{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs_24,
  pnpm_11,
  pnpmConfigHook,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cloudflare-os";
  version = "0-unstable-2026-08-06";

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-os";
    rev = "0eaec6c5e8fc6b3298ea1aa73bf5c3e47b923c7f";
    hash = "sha256-eiApNC4hloxVvVcM6Ke8ezzlDMeCvDMGUKSFG4jYzDo=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_11;
    fetcherVersion = 4;
    hash = "sha256-AOtx6GizkWC4jD4m7cMb2UqU6SsByxFOzq/MlOE7tEA=";
  };

  nativeBuildInputs = [
    nodejs_24
    pnpm_11
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    pnpm --filter @gadgets/typed-storage build
    pnpm --filter @gadgets/workshop-frontend exec vite build
    node packages/workshop-backend/scripts/build-format-blueprints.mjs
    pnpm --dir packages/workshop-backend run build:worker
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share
    cp -r . $out/share/cloudflare-os
    cp ${./cloudflare-os-wrangler.jsonc} \
      $out/share/cloudflare-os/packages/workshop-backend/wrangler.jsonc
    runHook postInstall
  '';
})
