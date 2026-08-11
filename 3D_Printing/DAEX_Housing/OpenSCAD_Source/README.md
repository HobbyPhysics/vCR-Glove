# OpenSCAD Source Files

This directory contains the editable OpenSCAD source files for the 3D-printed mechanical components used in the vCR Glove project.

The OpenSCAD files are the authoritative source for the current mechanical design. STL files should be generated from these sources after the design parameters have been reviewed and, if necessary, adjusted for the selected manufacturing process.

## Opening the Files

Install OpenSCAD and open the desired `.scad` file.

After opening a file:

1. Review the adjustable parameters near the beginning of the source file.
2. Press **F5** for Preview.
3. Press **F6** for Render.
4. Rotate and inspect the model to verify the geometry.
5. After rendering, export the model using:

**File → Export → Export as STL**

## Parametric Design

The mechanical parts were designed parametrically. Important dimensions are defined near the beginning of each OpenSCAD file so that the geometry can be adjusted without rewriting the model.

When modifying dimensions, render and inspect the model before exporting an STL.

## Manufacturing

The project parts were produced using JLC3DP.

The final STL files used for manufacturing are provided separately in:

`../STL/`

Because 3D-printing tolerances and material behavior vary by process and supplier, dimensional adjustments may be required for a different printer, material, or fabrication method.

## License

The OpenSCAD source files in this directory are hardware design files and are licensed under CERN-OHL-P-2.0. See the repository root file:

`LICENSE-HARDWARE.txt`