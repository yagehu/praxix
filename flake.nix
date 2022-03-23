{ description = "Praxix"
; inputs =
  { nixpkgs.url = "github:nixos/nixpkgs?ref=release-21.11"
  ; flake-utils.url = "github:numtide/flake-utils"
  ; rust-overlay.url = "github:oxalica/rust-overlay"
  ; rust-overlay.inputs.nixpkgs.follows = "nixpkgs"
  ; rust-overlay.inputs.flake-utils.follows = "flake-utils"
  ; }
; outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs
        { inherit system
        ; overlays = [ (import rust-overlay) ]
        ; };
      rust =
        (pkgs.rust-bin.selectLatestNightlyWith (toolchain:
          toolchain.default.override
            { extensions = [ "rust-src" ]
            ; targets = [ "riscv64imac-unknown-none-elf" ]
            ; }
        ));
    in rec
      { devShell = pkgs.mkShell
        { buildInputs =
          [ rust
          ]
        ; shellHook =
          ''
          set -eux
          
          ls ${ rust }/lib/rustlib/src/rust/library/core

          set +eux
          ''
        ; RUST_ROOT = "${ rust }"
        ; }
      ; }
  )
; }