# Electronics Enclosure OpenSCAD Source

This directory contains the editable OpenSCAD source file for the vCR Glove electronics enclosure.

A single OpenSCAD file defines both printable components of the enclosure and also provides assembled and exploded views for inspection.

## Selecting the Output

The variable `output_part` near the beginning of the OpenSCAD file selects what is displayed:

- `output_part = "box";` - enclosure bottom
- `output_part = "top";` - enclosure top (lid)
- `output_part = "assembly";` - assembled view for inspection
- `output_part = "exploded";` - exploded view for inspection

The `assembly` and `exploded` options are provided for visualization and are not intended to generate manufacturing STL files.

## Generating the STL Files

Two STL files are required for fabrication.

### Enclosure Bottom

Set:

`output_part = "box";`

Press **F6** to render the model, inspect it, and then select:

**File → Export → Export as STL**

Save the result using the `_bottom.stl` filename.

### Enclosure Top

Set:

`output_part = "top";`

Press **F6** to render the model, inspect it, and then select:

**File → Export → Export as STL**

Save the result using the `_top.stl` filename.

The resulting STL files are provided in:

`../STL/`

## Viewing the Complete Enclosure

For an assembled view, set:

`output_part = "assembly";`

For a separated view showing the relationship between the components, set:

`output_part = "exploded";`

These modes are useful for inspecting the enclosure design without generating separate manufacturing parts.

## Parametric Design

The enclosure is designed parametrically. Important dimensions are defined near the beginning of the OpenSCAD source file.

If dimensions are changed, both the top and bottom should be reviewed and new STL files generated as necessary.

## Manufacturing

The enclosure used in the project was manufactured by JLC3DP using:

- **Process:** SLA
- **Material:** Black resin

Manufacturing tolerances, shrinkage, and warping can vary with material and process. Critical dimensions should therefore be reviewed if a different manufacturing process or material is used.

## License

The OpenSCAD source file is a hardware design file licensed under CERN-OHL-P-2.0. See `LICENSE-HARDWARE.txt` in the repository root.