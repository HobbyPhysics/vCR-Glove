# JLCPCB Production Files

This directory contains the production files used to manufacture and assemble the vCR Glove printed circuit board using JLCPCB.

These files were generated from the KiCad design contained in the adjacent `KiCad_Source` directory.

Detailed ordering instructions are provided in the vCR Glove Project articles on the Hobby Physics blog. The notes below identify several issues that may be encountered when using the JLCPCB ordering system.

## PCB Fabrication

The ZIP file contains the Gerber and drill files required to manufacture the bare PCB.

Upload the ZIP file directly to the JLCPCB PCB ordering system. It is not necessary to extract the individual Gerber and drill files before uploading.

## PCB Assembly

The two CSV files are used for JLCPCB PCB assembly:

- **BOM (Bill of Materials)** - identifies the components and their reference designators.
- **Top Position / Pick-and-Place file** - specifies the location and orientation of the components installed on the top side of the PCB.

These files are uploaded during the PCB assembly portion of the JLCPCB ordering process.

## Important Assembly Checks

The JLCPCB assembly configuration and component placement should be carefully reviewed before placing an order. The production files provide the design information, but some selections and corrections may be required in the JLCPCB ordering interface.

### Component Availability

JLCPCB/LCSC component availability, pricing, and minimum order quantities can change.

A component specified in the BOM may become unavailable or may require a different minimum quantity. The JLCPCB system may report an error or suggest substitute components.

Any substitute should be checked for electrical specifications, package, footprint, and pinout before accepting it.

### DNP Components

Some components in the KiCad schematic are designated **DNP (Do Not Populate)** and are marked with a red X.

These components are intentionally not installed. JLCPCB may display warnings or comments associated with these unpopulated locations. These should not be interpreted as missing components that must necessarily be added.

The intended populated configuration should be compared with the schematic before responding to DNP-related warnings.

### Component Orientation and Position

Do not assume that all components shown in the JLCPCB assembly viewer have the correct orientation or exact position.

Differences between the KiCad placement data and the JLCPCB assembly system can result in some components appearing rotated or displaced in the JLCPCB viewer.

In the board used for this project, particular attention should be paid to:

- **JST connectors** - some may require rotation by 90 or 180 degrees and adjustment of their position so that they align correctly with the PCB through holes.
- **Electrolytic capacitor** - the capacitor may require a 180-degree rotation and position adjustment. Polarity must be checked carefully.

The JLCPCB assembly editing tools can be used during the ordering process to correct component rotation and position.

## Before Ordering

Before approving PCB assembly:

1. Review all BOM component selections and resolve unavailable components carefully.
2. Confirm that DNP components remain unpopulated.
3. Inspect the orientation and position of every component in the JLCPCB assembly viewer.
4. Pay particular attention to connectors and polarized components.
5. Compare the JLCPCB assembly preview with the KiCad PCB layout, schematic, and 3D view.

Do not approve the assembly solely because the BOM and placement files were accepted without errors.

## Design Version

These production files correspond to the PCB version documented in this repository. JLCPCB component inventory and its ordering interface may change over time.