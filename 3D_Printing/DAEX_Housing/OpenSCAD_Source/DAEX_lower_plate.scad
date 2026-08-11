/*
DAEX_lower_plate.scad

Lower plate for the DAEX-9-4SM actuator housing.

All fixed and shared derived dimensions are supplied by:
    DAEX_dimensions.scad

This file contains only the OpenSCAD geometry processes used to construct
the lower plate.

Coordinate convention:
X = along finger / actuator length
Y = across finger / actuator width
Z = thickness
Top = +Z mating side
Bottom = -Z screw-head and PSA side
Origin = center of plate
*/

include <DAEX_dimensions.scad>

$fn = lower_fn;


// ---------- Utility geometry ----------

module rounded_rect_2d(l, w, r) {
    rr = min(r, l/2 - 0.001, w/2 - 0.001);
    hull() {
        for (sx = [-1, 1])
            for (sy = [-1, 1])
                translate([sx*(l/2 - rr), sy*(w/2 - rr)])
                    circle(r = rr);
    }
}

// Positive plate body with vertical outside corner fillets and bottom roundover.
// Top perimeter edge is intentionally left square for mating to upper housing.
module exterior_body_bottom_and_vertical_filleted(l, w, h, r, steps=10) {
    z_bot = -h/2;

    // Main upper portion: vertical outside corner radius only.
    translate([0, 0, z_bot + r - eps])
        linear_extrude(height = h - r + eps)
            rounded_rect_2d(l, w, r);

    // Bottom roundover, approximated by hulling thin rounded-rectangle slices.
    for (i = [0:steps-1]) {
        hull() {
            exterior_bottom_slice(l, w, h, r, steps, i);
            exterior_bottom_slice(l, w, h, r, steps, i+1);
        }
    }
}

module exterior_bottom_slice(l, w, h, r, steps, i) {
    t = i / steps;
    dz = r * t;
    inset = r - sqrt(max(0, r*r - dz*dz));
    z = -h/2 + r - dz;

    translate([0, 0, z])
        linear_extrude(height = eps)
            rounded_rect_2d(l - 2*inset, w - 2*inset, max(0.001, r - inset));
}


// ---------- Cut features ----------

module top_cavity_pocket_cut() {
    translate([0, 0, plate_z/2 - cavity_z/2 + eps])
        cube([cavity_x, cavity_y, cavity_z + 2*eps], center=true);
}

module top_contact_cavity_cuts() {
    for (sx = [-1, 1]) {
        translate([
            sx*lower_contact_cavity_center_x,
            contact_cavity_center_y,
            plate_z/2 - contact_cavity_z/2 + eps
        ])
            cube([
                lower_contact_cavity_x + 2*small_extension,
                contact_cavity_y,
                contact_cavity_z + 2*eps
            ], center=true);
    }
}

module wire_clamp_groove_cuts() {
    for (sx = [-1, 1]) {
        translate([
            sx*wire_groove_x,
            wire_groove_center_y,
            lower_wire_groove_center_z
        ])
            rotate([90, 0, 0])
                cylinder(
                    d = wire_groove_d,
                    h = wire_groove_length,
                    center = true
                );
    }
}

module vent_slot_cuts() {
    for (sx = [-1, 1]) {
        translate([sx*vent_center_x, 0, 0])
            cube([vent_x, vent_y, plate_z + 2*eps], center=true);
    }
}

module clearance_hole_cuts() {
    for (sx = [-1, 1])
        for (sy = [-1, 1])
            translate([
                sx*screw_center_x,
                sy*screw_center_y,
                -plate_z/2 - eps
            ])
                cylinder(d = clearance_hole_d, h = plate_z + 2*eps);
}

module counterbore_cuts() {
    for (sx = [-1, 1])
        for (sy = [-1, 1])
            translate([
                sx*screw_center_x,
                sy*screw_center_y,
                -plate_z/2 - eps
            ])
                cylinder(d = counterbore_d, h = counterbore_depth + eps);
}


// ---------- Final part ----------

module DAEX_lower_plate() {
    difference() {
        exterior_body_bottom_and_vertical_filleted(
            plate_x,
            plate_y,
            plate_z,
            plate_fillet_radius,
            plate_fillet_steps
        );

        // Top mating features
        top_cavity_pocket_cut();
        top_contact_cavity_cuts();
        wire_clamp_groove_cuts();

        // Through features
        vent_slot_cuts();
        clearance_hole_cuts();

        // Bottom screw-head counterbores
        counterbore_cuts();
    }
}

// Render this part when the file is opened directly.
DAEX_lower_plate();
