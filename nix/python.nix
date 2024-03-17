{ python310
, python310Packages
, lib
, fetchPypi
, fetchurl
, stdenv
, autoPatchelfHook
, addOpenGLRunpath
, cudaPackages
, withTensorboard ? false
}:
let
  inherit (python310.pkgs)
    buildPythonPackage;
  inherit (cudaPackages)
    nccl
    cudnn_8_7
    cudatoolkit;
  pyPkgs = python310Packages;

  keras = (pyPkgs.callPackage (import ./keras.nix) { });
  mtensorflowWithCuda = buildPythonPackage rec {
    pname = "tensorflow";
    version = "2.14.1";
    format = "wheel";

    src = fetchurl {
      name = "${pname}-${version}-py3-none-any.whl";
      url = "https://files.pythonhosted.org/packages/99/77/4f31cd29cab69ebc344a529df48b91a14543a83b6fb90efbf82db29a34be/tensorflow-2.14.1-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
      sha256 = "sha256-mpVcQhZO/011FzLBJ0ykvwWdtgyeI2IJjOHu1xd8P+k=";
    };

    # nativeBuildInputs = [ pyPkgs.wheel ];
    nativeBuildInputs = [ pyPkgs.wheel ] ++ lib.optionals stdenv.isLinux [ autoPatchelfHook ];

    # tensorflow/tools/pip_package/setup.py
    propagatedBuildInputs = with pyPkgs; [
      absl-py
      # abseil-cpp
      astunparse
      flatbuffers
      gast
      google-pasta
      grpcio
      h5py
      keras-preprocessing
      numpy
      opt-einsum
      packaging
      # protobuf-python
      six
      tensorflow-estimator-bin
      termcolor
      typing-extensions
      wrapt
      # No longer in 310 packages, had to be copied
      # from upstream's 311 packages
      (pyPkgs.callPackage (import ./mldtypes.nix) { })
    ] ++ lib.optionals withTensorboard [
      tensorboard
    ];

    # During installation it can't find the deps provided above
    # but if we disable this, can assert the module works after
    pipInstallFlags = "--no-deps";

    postFixup = ''
      find $out -type f \( -name '*.so' -or -name '*.so.*' \) | while read lib; do
        # addOpenGLRunpath "$lib"
        echo [MANUAL] patching $lib

        patchelf --set-rpath "${cudatoolkit}/lib64:${cudatoolkit.lib}/lib:${cudnn_8_7}/lib:${nccl}/lib:$(patchelf --print-rpath "$lib")" "$lib"
      done
    '';

    doCheck = false;
    checkPhase = ''
      ${python310.interpreter} <<EOF
      # A simple "Hello world"
      import tensorflow as tf
      hello = tf.constant("Hello, world!")
      tf.print(hello)

      tf.random.set_seed(0)
      width = 512
      choice = 48
      t_in = tf.Variable(tf.random.uniform(shape=[width]))
      with tf.GradientTape() as tape:
          t_out = tf.slice(tf.nn.softmax(t_in), [choice], [1])
      diff = tape.gradient(t_out, t_in)
      assert(0 < tf.reduce_min(tf.slice(diff, [choice], [1])))
      assert(0 > tf.reduce_max(tf.slice(diff, [1], [choice - 1])))
      EOF
    '';
  };

  baseDeps = with python310Packages;[
    numpy
    regex
    tqdm
    gym
    mtensorflowWithCuda
    matplotlib
    ipython
  ];

  mitdeeplearning = buildPythonPackage rec {
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

  everett = buildPythonPackage rec {
    pname = "everett";
    version = "3.3.0";

    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-0+zFXMG98kCMqCvI21o/xYj8TA8jamq5WZk49BlwuBQ=";
    };

    propagatedBuildInputs = baseDeps;

    doCheck = false;
  };

  cometml = buildPythonPackage rec {
    pname = "comet-ml";
    version = "3.39.0";
    format = "wheel";

    # Trash non standard lib without published source
    src = fetchurl {
      name = "comet_ml-${version}-py2.py3-none-any.whl";
      url = "https://files.pythonhosted.org/packages/53/23/36c859c1ccb63916a09489ec4e8efc8be199cdd2ef63603b92642cf1976c/comet_ml-3.39.0-py3-none-any.whl";
      sha256 = "sha256-wHC7EKmZ3d/pRMPokr2Pq8Dai3/HRO18m/hABB4Y/64=";
    };

    nativeBuildInputs = [ pyPkgs.wheel ] ++ lib.optionals stdenv.isLinux [ autoPatchelfHook ];

    propagatedBuildInputs = with python310Packages; [
      rich
      rich-rst
      sentry-sdk
      everett
      wurlitzer
      wrapt
      websocket-client
      semantic-version
      dulwich
      requests
      jsonschema
      requests-toolbelt
      configobj
      python-box
      # setuptools
    ];

    # During installation it can't find the deps provided above
    # but if we disable this, can assert the module works after
    pipInstallFlags = "--no-deps";

    doCheck = true;

    meta = with lib; {
      homepage = "https://pypi.org/project/comet-ml";
      description = "Comet ml";
    };
  };
in
python310.withPackages (ps: with ps;[
  numpy
  regex
  tqdm
  gym
  mtensorflowWithCuda
  matplotlib
  ipython
  mitdeeplearning
  h5py
  opencv4
  keras

  # For custom tensorflow
  # tensorrt

  # Music generation
  cometml
  
  # Tensorflow deps but added
  # here for a faster feedback loop
  scipy
  dm-tree

  # Required by vscode Jupyter plugin
  # to easily run cells within the IDE
  ipykernel
  pip
])
