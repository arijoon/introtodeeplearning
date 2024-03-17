{ pkgs ? import ./nix/pkgs.nix { }
}:
let
in pkgs.mkShell {
  buildInputs = with pkgs; [
    myPython

    # Used in lab1/part 2 for music generation
    abcmidi
    timidity
    cudatoolkit
    cudaPackages.cudnn_8_7
  ];

  # From nix docs: https://nixos.wiki/wiki/CUDA
  # Validate the env has GPU support
  # $(nix build -f ./nix/pkgs.nix myPython  --print-out-paths)/bin/python3 -c 'import tensorflow as tf; print(tf.sysconfig.get_build_info()); print(tf.config.list_physical_devices("GPU"))'
  shellHook = ''
      export CUDA_PATH=${pkgs.cudatoolkit}
      export CUDNN_PATH=${pkgs.cudaPackages.cudnn_8_7}
      export LD_LIBRARY_PATH=/usr/lib/wsl/lib:${pkgs.cudaPackages.cudnn_8_7}/lib:${pkgs.cudatoolkit}/lib64:${pkgs.cudatoolkit.lib}/lib:
      # export LD_LIBRARY_PATH=/usr/lib/wsl/lib:${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib
      # export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
      # export EXTRA_CCFLAGS="-I/usr/include"
  '';
}
