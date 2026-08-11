# DAEX Housing

This directory contains the source and fabrication files for the finger-mounted housing used with the Dayton Audio DAEX-9-4SM exciter in the vCR Glove.

The housing consists of three 3D-printed parts:

- Upper housing
- Lower plate
- Tapper

The DAEX-9-4SM is mounted within the housing, and the tapper provides the mechanical contact between the moving portion of the actuator and the finger.

## Directory Contents

- `OpenSCAD_Source/` - editable parametric OpenSCAD source files and an assembly model for viewing the completed housing
- `STL/` - rendered STL files for manufacturing the three individual housing components

See the README files within these directories for additional information.

## Manufacturing

The parts used in the project were manufactured by JLC3DP using:

- **Process:** Multi Jet Fusion (MJF)
- **Material:** Nylon
- **Color:** Black

The STL files in this repository correspond to the current OpenSCAD source files.

Manufacturing tolerances can vary with process, material, and supplier. Users employing a different manufacturing process or material should review critical dimensions before fabrication.

## License

These mechanical design files are licensed under CERN-OHL-P-2.0. See `LICENSE-HARDWARE.txt` in the repository root.