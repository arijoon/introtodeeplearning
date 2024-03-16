{ python310
, python310Packages
, lib
, fetchPypi
}:
let
  baseDeps = with python310Packages;[
    numpy
    regex
    tqdm
    gym
    tensorflow
    matplotlib
    ipython
  ];

  mitdeeplearning = python310.pkgs.buildPythonPackage rec {
    pname = "mitdeeplearning";
    version = "0.6.1";

    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-ruMdfPFcU90nMuidBHCQwrWoDy28nhWkPel9pqmHeoI=";
    };

    propagatedBuildInputs = baseDeps;

    doCheck = false;

    meta = with lib; {
      homepage = "https://github.com/pytoolz/toolz";
      description = "MIT deep learning";
      license = licenses.mit;
    };
  };
in
python310.withPackages (ps: with ps;[
    numpy
    regex
    tqdm
    gym
    tensorflow
    matplotlib
    ipython
    mitdeeplearning
    h5py
    opencv4
    keras
    # Required by vscode Jupyter plugin
    # to easily run cells within the IDE
    ipykernel
    pip
])
