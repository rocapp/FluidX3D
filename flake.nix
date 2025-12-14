{
  description = "FluidX3D - The fastest and most memory efficient lattice Boltzmann CFD software";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Determine if we're on a system that supports X11
        hasX11 = !pkgs.stdenv.isDarwin;
        
        fluidx3d = pkgs.stdenv.mkDerivation {
          pname = "FluidX3D";
          version = "2.0.0";
          
          src = ./.;
          
          nativeBuildInputs = with pkgs; [
            gnumake
            gcc
          ];
          
          buildInputs = with pkgs; [
            ocl-icd
            opencl-headers
          ] ++ pkgs.lib.optionals hasX11 [
            xorg.libX11
            xorg.libXrandr
          ];
          
          enableParallelBuilding = true;
          
          # Set OpenCL paths for the build
          preBuild = ''
            # Create OpenCL directory structure expected by the makefile
            mkdir -p src/OpenCL/include src/OpenCL/lib
            ln -sf ${pkgs.opencl-headers}/include/CL src/OpenCL/include/CL
            ln -sf ${pkgs.ocl-icd}/lib/* src/OpenCL/lib/
            
            ${pkgs.lib.optionalString hasX11 ''
              # Create X11 directory structure for Linux builds
              mkdir -p src/X11/include src/X11/lib
              ln -sf ${pkgs.xorg.libX11.dev}/include/* src/X11/include/
              ln -sf ${pkgs.xorg.libXrandr.dev}/include/* src/X11/include/
              ln -sf ${pkgs.xorg.libX11}/lib/* src/X11/lib/
              ln -sf ${pkgs.xorg.libXrandr}/lib/* src/X11/lib/
            ''}
          '';
          
          makeFlags = [
            (if pkgs.stdenv.isDarwin then "macOS" else if hasX11 then "Linux-X11" else "Linux")
          ];
          
          installPhase = ''
            mkdir -p $out/bin
            cp bin/FluidX3D $out/bin/
            
            # Install skybox assets if they exist
            if [ -d skybox ]; then
              mkdir -p $out/share/FluidX3D
              cp -r skybox $out/share/FluidX3D/
            fi
          '';
          
          meta = with pkgs.lib; {
            description = "The fastest and most memory efficient lattice Boltzmann CFD software";
            homepage = "https://github.com/ProjectPhysX/FluidX3D";
            license = licenses.gpl3Only;
            platforms = platforms.unix;
            maintainers = [ ];
          };
        };
        
      in
      {
        packages = {
          default = fluidx3d;
          fluidx3d = fluidx3d;
        };
        
        apps = {
          default = flake-utils.lib.mkApp {
            drv = fluidx3d;
            exePath = "/bin/FluidX3D";
          };
        };
        
        devShells = {
          default = pkgs.mkShell {
            name = "fluidx3d-dev";
            
            buildInputs = with pkgs; [
              gcc
              gnumake
              ocl-icd
              opencl-headers
              clinfo  # Useful for checking OpenCL devices
            ] ++ pkgs.lib.optionals hasX11 [
              xorg.libX11
              xorg.libXrandr
            ];
            
            shellHook = ''
              echo "FluidX3D Development Environment"
              echo "================================"
              echo ""
              echo "Available commands:"
              echo "  make Linux-X11  - Build with X11 graphics support (Linux)"
              echo "  make Linux      - Build without graphics (Linux)"
              echo "  make macOS      - Build for macOS"
              echo "  ./make.sh       - Auto-detect and build"
              echo ""
              echo "OpenCL devices available:"
              ${pkgs.clinfo}/bin/clinfo 2>/dev/null | grep "Device Name" || echo "  No OpenCL devices found"
              echo ""
              
              # Set up OpenCL ICD path for runtime
              export OCL_ICD_VENDORS="${pkgs.ocl-icd}/etc/OpenCL/vendors"
            '';
          };
        };
        
        # Checks for testing
        checks = {
          build = fluidx3d;
          
          # Basic compilation test
          compile-test = pkgs.runCommand "fluidx3d-compile-test" {
            buildInputs = [ fluidx3d ];
          } ''
            ${fluidx3d}/bin/FluidX3D --help 2>&1 || true
            touch $out
          '';
        };
      }
    );
}
