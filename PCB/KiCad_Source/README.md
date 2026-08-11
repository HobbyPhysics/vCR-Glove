# KiCad Source Files
# KiCad Source Files

This directory contains the editable KiCad source files for the vCR Glove printed circuit board.

The project was created using KiCad. To open the complete project, start KiCad and open the `.kicad_pro` project file. The schematic and PCB layout can then be opened from the KiCad Project Manager.

## Files

- `.kicad_pro` - KiCad project file
- `.kicad_sch` - schematics
- `.kicad_pcb` - PCB layout

## Schematic DNP Markings

Some components in the schematic are marked with a red X. These components have been designated **DNP (Do Not Populate)** in KiCad.

The components are intentionally retained in the schematic but are not installed on the manufactured PCB. The red X is therefore not an error indication. It provides a visual record of optional or unused components and identifies the configuration used for production.

## Viewing the PCB

Open the `.kicad_pcb` file from the KiCad Project Manager to view the PCB layout.

KiCad can also display a three-dimensional representation of the assembled PCB. With the PCB Editor open, select:

**View → 3D Viewer**

The 3D Viewer can be rotated and zoomed to inspect the component placement and overall board assembly.

## Manufacturing Files

The files used to order the PCB and assembled board are provided separately in:

`../JLCPCB_Production/`

Those production files should be used for reproducing the manufactured board. The files in this directory are provided for viewing or modifying the design.
