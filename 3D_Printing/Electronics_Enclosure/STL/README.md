# Electronics Enclosure STL Files

This directory contains the STL files used to manufacture the electronics enclosure components.

The STL files were generated from the corresponding OpenSCAD source files in:

`../OpenSCAD_Source/`

## Generating the STL Files

Open the corresponding `.scad` file in OpenSCAD, perform an **F6 Render**, and then select:

**File → Export → Export as STL**

## Manufacturing

The enclosure parts used in the project were manufactured by JLC3DP using:

- **Process:** SLA
- **Material:** Black resin

Before ordering, inspect the uploaded model in the JLC3DP viewer and confirm the part dimensions and geometry.

## Source Files

The OpenSCAD files in `../OpenSCAD_Source/` are the authoritative editable source.

If dimensions are changed, regenerate the corresponding STL rather than editing the STL directly.

## License

These STL files are derived from hardware designs licensed under CERN-OHL-P-2.0. See `LICENSE-HARDWARE.txt` in the repository root.elec enclosure stl