/*
DAEX_assembly.scad

Assembly visualization and interference-checking file for the DAEX-9-4SM
vibrotactile actuator assembly.

Required files in the same folder:
    DAEX_dimensions.scad
    DAEX_upper_housing.scad
    DAEX_lower_plate.scad
    DAEX_tapper.scad

This file does NOT reproduce the part geometry. It imports the named modules
from the three part files, positions them, and provides visualization tools.

OpenSCAD command summary
------------------------

include <file.scad>
    Reads variables, functions, modules, and top-level geometry from a file.
    Here it is used for the common dimensional specification.

use <file.scad>
    Imports modules and functions from a file, but ignores that file's
    top-level rendered objects. This is ideal for assembly files because the
    part scripts may render themselves when opened directly, while this file
    calls only their named modules.

translate([x, y, z])
    Moves the following object by the specified X, Y, and Z distances.
    Example:
        translate([0, 0, 5])
            DAEX_tapper();
    moves the tapper upward by 5 mm.

color([r, g, b, a])
    Changes the display color of the following object.
    r, g, and b range from 0 to 1.
    Optional a is opacity: 1 = opaque, 0 = invisible.
    Example:
        color([0.2, 0.6, 0.9, 0.4])
    displays a translucent blue object.

intersection() {
    object_A();
    object_B();
}
    Keeps only volume occupied by BOTH objects. In interference mode, any
    visible result represents physical overlap between two nominally separate
    parts.

difference() {
    object_A();
    object_B();
}
    Keeps object A after subtracting object B.

intersection() used with a large cube
    provides a section view: only the portion of the assembly inside the cube
    remains visible.
*/


// ============================================================================
// Imported dimensions and part modules
// ============================================================================

include <DAEX_dimensions.scad>

use <DAEX_upper_housing.scad>
use <DAEX_lower_plate.scad>
use <DAEX_tapper.scad>


// ============================================================================
// Main controls
// ============================================================================

// Select one:
// "assembled"
// "exploded"
// "transparent"
// "section_xz"
// "section_yz"
// "interference_all"
// "interference_upper_plate"
// "interference_upper_tapper"
// "interference_plate_tapper"
view_mode = "exploded";


// Z separation controls, in millimeters.
//
// These are visualization settings rather than manufactured dimensions, so
// they belong in this assembly file rather than DAEX_dimensions.scad.
//
// Set all three to zero for the nominal assembled positions.
// Positive values move a part upward; negative values move it downward.
upper_z_separation = 0;
plate_z_separation = 0;
tapper_z_separation = -1;

// Convenient default exploded-view distances. These are used only when
// view_mode = "exploded".
exploded_upper_gap = 8;
exploded_plate_gap = -8;
exploded_tapper_gap = -2;


// Section-plane controls.
//
// For section_xz, Y material greater than section_y is removed.
// section_y = 0 gives a center XZ half-section.
//
// For section_yz, X material greater than section_x is removed.
// section_x = 0 gives a center YZ half-section.
section_x = 0;
section_y = 0;

// Size of the clipping cube used for section views.
section_box_size = 120;


// Display colors: [red, green, blue, opacity]
upper_color = [0.78, 0.82, 0.88, 1.00];
plate_color = [0.30, 0.34, 0.40, 1.00];
tapper_color = [0.90, 0.45, 0.15, 1.00];

transparent_upper_color = [0.78, 0.82, 0.88, 0.35];
transparent_plate_color = [0.30, 0.34, 0.40, 0.35];
transparent_tapper_color = [0.90, 0.45, 0.15, 0.85];

interference_color = [1.00, 0.00, 0.00, 1.00];


// ============================================================================
// Nominal assembly placement
// ============================================================================

// The upper housing module is centered on its own origin.
upper_nominal_z = 0;

// The lower plate top face mates to the upper housing bottom face.
//
// Upper bottom face: -housing_z/2
// Plate top face:    plate_center_z + plate_z/2
//
// Therefore:
// plate_center_z = -housing_z/2 - plate_z/2
plate_nominal_z = -(housing_z + plate_z)/2;


// Nominal tapper placement
// -------------------------
//
// The tapper's broad middle cylinder is assumed to lie below the housing's
// center-hole roof, with the top of the middle cylinder aligned to the upper
// surface of the main DAEX cavity:
//
// cavity_roof_z = -housing_z/2 + cavity_depth
//
// In DAEX_tapper, the top face of the broad cylinder is:
// tapper_mid_center_z + tapper_mid_z/2
//
// The expression below aligns those two surfaces. This is a useful nominal
// assembly location, but tapper_z_separation can be adjusted to represent
// adhesive thickness, DAEX suspension position, or alternate tapper heights.
cavity_roof_z = -housing_z/2 + cavity_depth;

tapper_mid_top_local_z =
    tapper_mid_center_z + tapper_mid_z/2;

tapper_nominal_z =
    cavity_roof_z - tapper_mid_top_local_z;


// Final positions after applying user-controlled visual separations.
upper_position_z =
    upper_nominal_z + upper_z_separation;

plate_position_z =
    plate_nominal_z + plate_z_separation;

tapper_position_z =
    tapper_nominal_z + tapper_z_separation;


// ============================================================================
// Positioned part modules
// ============================================================================

module positioned_upper() {
    translate([0, 0, upper_position_z])
        DAEX_upper_housing();
}

module positioned_plate() {
    translate([0, 0, plate_position_z])
        DAEX_lower_plate();
}

module positioned_tapper() {
    translate([0, 0, tapper_position_z])
        DAEX_tapper();
}


// Exploded positions use the nominal positions plus dedicated exploded gaps.
module exploded_upper() {
    translate([0, 0, upper_nominal_z + exploded_upper_gap])
        DAEX_upper_housing();
}

module exploded_plate() {
    translate([0, 0, plate_nominal_z + exploded_plate_gap])
        DAEX_lower_plate();
}

module exploded_tapper() {
    translate([0, 0, tapper_nominal_z + exploded_tapper_gap])
        DAEX_tapper();
}


// ============================================================================
// Assembly display modules
// ============================================================================

module assembled_view(transparent=false) {
    if (transparent) {
        color(transparent_upper_color)
            positioned_upper();

        color(transparent_plate_color)
            positioned_plate();

        color(transparent_tapper_color)
            positioned_tapper();
    } else {
        color(upper_color)
            positioned_upper();

        color(plate_color)
            positioned_plate();

        color(tapper_color)
            positioned_tapper();
    }
}


module exploded_view() {
    color(upper_color)
        exploded_upper();

    color(plate_color)
        exploded_plate();

    color(tapper_color)
        exploded_tapper();
}


// A geometry-only assembly without colors.
// This is used by section and other Boolean operations.
module complete_assembly_geometry() {
    positioned_upper();
    positioned_plate();
    positioned_tapper();
}


// ============================================================================
// Section views
// ============================================================================

module section_xz_view() {
    // Keeps the half of the assembly at Y <= section_y.
    //
    // intersection() returns only the volume common to:
    //   1. the complete assembly
    //   2. the large clipping cube
    //
    // Because the cube ends at section_y, the result is an XZ cutaway.
    intersection() {
        complete_assembly_geometry();

        translate([
            -section_box_size/2,
            section_y - section_box_size,
            -section_box_size/2
        ])
            cube([
                section_box_size,
                section_box_size,
                section_box_size
            ]);
    }
}


module section_yz_view() {
    // Keeps the half of the assembly at X <= section_x.
    // The clipping cube creates a YZ cutaway.
    intersection() {
        complete_assembly_geometry();

        translate([
            section_x - section_box_size,
            -section_box_size/2,
            -section_box_size/2
        ])
            cube([
                section_box_size,
                section_box_size,
                section_box_size
            ]);
    }
}


// ============================================================================
// Interference checks
// ============================================================================

// Important:
// Coincident mating faces may occasionally display extremely thin numerical
// artifacts in preview mode. Use F6 Render before judging an interference.
//
// A real visible red solid indicates volume overlap.

module interference_upper_plate() {
    color(interference_color)
        intersection() {
            positioned_upper();
            positioned_plate();
        }
}


module interference_upper_tapper() {
    color(interference_color)
        intersection() {
            positioned_upper();
            positioned_tapper();
        }
}


module interference_plate_tapper() {
    color(interference_color)
        intersection() {
            positioned_plate();
            positioned_tapper();
        }
}


module interference_all() {
    // Each pairwise intersection is shown in red.
    interference_upper_plate();
    interference_upper_tapper();
    interference_plate_tapper();
}


// ============================================================================
// Mode selection
// ============================================================================

if (view_mode == "assembled") {
    assembled_view(false);

} else if (view_mode == "exploded") {
    exploded_view();

} else if (view_mode == "transparent") {
    assembled_view(true);

} else if (view_mode == "section_xz") {
    color(upper_color)
        section_xz_view();

} else if (view_mode == "section_yz") {
    color(upper_color)
        section_yz_view();

} else if (view_mode == "interference_all") {
    interference_all();

} else if (view_mode == "interference_upper_plate") {
    interference_upper_plate();

} else if (view_mode == "interference_upper_tapper") {
    interference_upper_tapper();

} else if (view_mode == "interference_plate_tapper") {
    interference_plate_tapper();

} else {
    echo("Unknown view_mode: ", view_mode);
    echo("Use assembled, exploded, transparent, section_xz, section_yz,");
    echo("interference_all, interference_upper_plate,");
    echo("interference_upper_tapper, or interference_plate_tapper.");
}
