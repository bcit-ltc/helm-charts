{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    kubernetes-helm
    kubectl
    git
    jq
    nixd
  ];

  shellHook = ''
    echo ""
    echo "Helm Development Environment"
    echo "Available tools:"
    echo "  - helm $(helm version | head -n1)"
    echo "  - kubectl $(kubectl version --short | head -n1)"
    echo "  - git $(git --version)"
    echo "  - jq $(jq --version)"
    echo ""
    echo "Run 'helm template ./charts/{chart_name}' to render a chart"
    echo "Run 'kubectl config use-context <context>' to switch context"
    echo ""
  '';
}
