/*
DAEX_tapper.scad

Two-step screw-adjustable tapper for the DAEX-9-4SM actuator assembly.

All fixed and shared derived dimensions are supplied by:
    DAEX_dimensions.scad

The centered through-hole is printed at 2.15 mm and is intended to be tapped
for the nylon M2.5 adjustment screw.

Coordinate convention:
X/Y = radial directions
Z = stack direction
Top = +Z, toward finger
Bottom = -Z, toward DAEX moving element
Origin = center of complete two-cylinder tapper
*/

include <DAEX_dimensions.scad>

$fn = tapper_fn;


module DAEX_tapper() {
    difference() {
        union() {
            // Lower locating cylinder
            translate([0, 0, tapper_bottom_center_z])
                cylinder(
                    d = tapper_bottom_d,
                    h = tapper_bottom_z,
                    center = true
                );

            // Broad upper cylinder
            translate([0, 0, tapper_mid_center_z])
                cylinder(
                    d = tapper_mid_d,
                    h = tapper_mid_z,
                    center = true
                );
        }

        // Center through-hole.
        // The extra eps at each end guarantees a clean Boolean opening.
        cylinder(
            d = tapper_hole_d,
            h = tapper_total_z + 2*eps,
            center = true
        );
    }
}


// Render this part when the file is opened directly.
DAEX_tapper();
