{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
}:

rustPlatform.buildRustPackage rec {
  pname = "celld";
  version = "0.1.0-hive.1";

  src = fetchFromGitHub {
    owner = "denoland";
    repo = "celld";
    rev = "553ae73";
    hash = "sha256-Iew3/ugHftS1Ui6tiVRPj3FguYmGx9vwMfS6pY00CWQ=";
  };

  patches = [ ./celld-rpc-output-gate.patch ];

  cargoHash = "sha256-g3b2gFeHkqlUVLydWs/HiieK2dtw7BC2o9eNwCGAHT0=";

  RUSTY_V8_ARCHIVE = fetchurl {
    url = "https://github.com/denoland/rusty_v8/releases/download/v152.0.0/librusty_v8_release_x86_64-unknown-linux-gnu.a.gz";
    hash = "sha256-nS++EYCa01QTDVw3gmNqE89YaNptLAAtqIJ7hT01x+w=";
  };

  cargoBuildFlags = [ "-p celld" ];
  cargoTestFlags = [ "-p celld" ];

  meta = {
    description = "Stateful server runtime for Durable Objects";
    homepage = "https://github.com/denoland/celld";
    license = lib.licenses.asl20;
    mainProgram = "celld";
    platforms = [ "x86_64-linux" ];
  };
}
