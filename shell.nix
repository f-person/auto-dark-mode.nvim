{
  pkgs ? import <nixpkgs> {
    config = { };
    overlays = [ ];
  },
}:
pkgs.mkShell {
  packages = with pkgs; [
    (lua5_1.withPackages (
      ps: with ps; [
        busted
        nlua
      ]
    ))
    stylua
  ];
}
