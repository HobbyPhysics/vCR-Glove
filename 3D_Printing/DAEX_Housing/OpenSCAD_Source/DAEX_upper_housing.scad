/*
DAEX_upper_housing.scad

Upper DAEX-9-4SM actuator housing.

All fixed and shared derived dimensions are supplied by:
    DAEX_dimensions.scad

This file contains only the OpenSCAD geometry processes used to construct
the upper housing.

Coordinate convention:
X = along finger / actuator length
Y = across finger / actuator width
Z = thickness
Top = +Z finger-groove side
Bottom = -Z DAEX-cavity side
Origin = center of housing
*/

include <DAEX_dimensions.scad>

$fn = upper_fn;


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

// Positive housing body with vertical corner fillets and top outside roundover.
// Bottom perimeter edges are intentionally left sharp.
module exterior_body_top_and_vertical_filleted(l, w, h, r, steps=12) {
    z_bot = -h/2;
    z_top =  h/2;

    // Main lower portion: vertical outside corner radius only.
    translate([0, 0, z_bot])
        linear_extrude(height = h - r + eps)
            rounded_rect_2d(l, w, r);

    // Top roundover, approximated by hulling thin rounded-rectangle slices.
    for (i = [0:steps-1]) {
        hull() {
            exterior_top_slice(l, w, h, r, steps, i);
            exterior_top_slice(l, w, h, r, steps, i+1);
        }
    }
}

module exterior_top_slice(l, w, h, r, steps, i) {
    t = i / steps;
    dz = r * t;
    inset = r - sqrt(max(0, r*r - dz*dz));
    z = h/2 - r + dz;

    // Inward offset creates the top edge roundover.
    // Corner radius is reduced by the same inset to blend the vertical corners.
    translate([0, 0, z])
        linear_extrude(height = eps)
            rounded_rect_2d(l - 2*inset, w - 2*inset, max(0.001, r - inset));
}


// Finger-groove 2D plan for one Z slice.
// Open at +X, rounded closed end at -X.  The +X end extends slightly past
// the housing edge to prevent a thin artifact wall.
module finger_groove_plan_2d(x_len, y_width, x_offset, plan_r, x_open_max) {
    x_min = x_offset - x_len/2;
    x_max = x_open_max;
    r = min(plan_r, y_width/2 - 0.001, x_len/2 - 0.001);

    // Hull of the two closed-end corner circles and a thin right-end rectangle.
    // This makes a rounded closed -X end and an open +X end whose limit is
    // explicitly tied to the housing side rather than to the nominal groove
    // length. That keeps the groove open when housing_x changes.
    hull() {
        translate([x_min + r, -y_width/2 + r]) circle(r = r);
        translate([x_min + r,  y_width/2 - r]) circle(r = r);
        translate([x_max, 0]) square([eps, y_width], center=true);
    }
}

module finger_groove_plan_2d_expand(x_len, y_width, x_offset, plan_r, x_open_max, expand=0) {
    // Positive expand enlarges the groove cutter. For a convex remaining
    // solid lip, the cutter must be largest at the top face and reduce to the
    // nominal groove profile at the bottom of the fillet.
    if (expand <= 0) {
        finger_groove_plan_2d(x_len, y_width, x_offset, plan_r, x_open_max);
    } else {
        offset(delta = expand)
            finger_groove_plan_2d(x_len, y_width, x_offset, plan_r, x_open_max);
    }
}

module finger_groove_plan_2d_side_and_rim(x_len, y_width, x_offset, plan_r, x_open_max, side_inset=0, rim_expand=0) {
    // Apply the sidewall inset to the entire groove plan, not only to the Y
    // width. This lets the sidewall radius continue around the rounded closed
    // end of the finger groove.
    //
    // Important: offset(delta = -side_inset) also pulls the open +X edge back
    // in X.  To keep the groove truly open, extend the nominal open edge by
    // side_inset before applying the inward offset.  This is the parametric
    // version of moving the cutter farther in +X, without using destructive
    // rectangular cleanup cuts that remove the side fillets.
    x_open_compensated = x_open_max + side_inset + small_extension;

    offset(delta = rim_expand)
        offset(delta = -side_inset)
            finger_groove_plan_2d(
                x_len,
                y_width,
                x_offset,
                plan_r,
                x_open_compensated
            );
}

function groove_side_inset(z_down, r) =
    r - sqrt(max(0, r*r - z_down*z_down));

function groove_rim_expand_convex(z_down, r) =
    (z_down < r) ? r - sqrt(max(0, r*r - (r - z_down)*(r - z_down))) : 0;

module finger_groove_slice(i) {
    t = i / finger_groove_steps;
    z_down = finger_groove_depth * t;
    side_inset = groove_side_inset(z_down, finger_groove_side_radius);
    rim_expand = groove_rim_expand_convex(z_down, finger_groove_fillet_radius);
    z_now = housing_z/2 + small_extension - z_down;

    translate([0, 0, z_now - eps])
        linear_extrude(height = eps)
            finger_groove_plan_2d_side_and_rim(
                finger_groove_x,
                finger_groove_y,
                finger_groove_x_offset,
                finger_groove_plan_radius,
                housing_x/2 + groove_open_end_beyond_housing,
                side_inset,
                rim_expand
            );
}

module finger_groove_cut() {
    // Hull between neighboring slices gives a smooth, layered,
    // 3D-print-oriented groove wall rather than a fragile Boolean shell.
    for (i = [0:finger_groove_steps-1]) {
        hull() {
            finger_groove_slice(i);
            finger_groove_slice(i+1);
        }
    }

    // Small bottom cleanup layer ensures the deepest surface subtracts cleanly.
    // It uses the same whole-plan side inset as the groove slices, so the
    // sidewall radius continues around the closed plan-radius end.
    translate([0, 0, housing_z/2 - finger_groove_depth - small_extension - eps])
        linear_extrude(height = small_extension + 2*eps)
            finger_groove_plan_2d_side_and_rim(
                finger_groove_x,
                finger_groove_y,
                finger_groove_x_offset,
                finger_groove_plan_radius,
                housing_x/2 + groove_open_end_beyond_housing,
                groove_side_inset(finger_groove_depth, finger_groove_side_radius),
                0
            );
}


module finger_groove_open_x_floor_edge_fillet_cut() {
    // Convex fillet on the +X breakout edge where the groove floor exits
    // the housing side.  Axis is along Y.
    //
    // For a convex remaining fillet, subtract the square corner region
    // OUTSIDE the radius cylinder, not the cylinder itself.
    r = finger_groove_fillet_radius;

    fillet_center_x = housing_x/2 - r;
    fillet_center_z = housing_z/2 - finger_groove_depth - r;

    bottom_side_inset =
        groove_side_inset(finger_groove_depth, finger_groove_side_radius);

    bottom_groove_y = finger_groove_y - 2*bottom_side_inset;

    // Limit the fillet along Y to the central straight portion of the actual
    // groove floor. Do not extend into the rounded Y-side portions.
    y_len = bottom_groove_y - 2*small_extension;

    difference() {
        // Corner block at the +X / +Z side of the fillet center.
        translate([
            fillet_center_x + r/2,
            0,
            fillet_center_z + r/2
        ])
            cube([
                r + 2*small_extension,
                y_len,
                r + 2*small_extension
            ], center=true);

        // Remove the cylinder from the cut block, leaving only the material
        // outside the quarter circle to be subtracted from the part.
        translate([fillet_center_x, 0, fillet_center_z])
            rotate([90, 0, 0])
                cylinder(r = r, h = y_len + 2*eps, center=true);
    }
}


// ---------- Bottom cut features ----------

module main_daex_cavity_cut() {
    translate([0, 0, -housing_z/2 + cavity_depth/2 - eps])
        cube([cavity_x, cavity_y, cavity_depth + 2*eps], center=true);
}

module ledge_cuts() {
    for (sx = [-1, 1]) {
        translate([sx*(cavity_x/2 + ledge_x/2), 0, -housing_z/2 + ledge_depth/2 - eps])
            cube([ledge_x + 2*small_extension, ledge_y, ledge_depth + 2*eps], center=true);
    }
}

module contact_cavity_cuts() {
    // Symmetric pockets between each ledge and the inner face of the closed
    // +/-X end wall.
    contact_center_x =
        cavity_x/2 + ledge_x + contact_cavity_x/2;

    for (sx = [-1, 1]) {
        translate([
            sx*contact_center_x,
            0,
            -housing_z/2 + contact_cavity_depth/2 - eps
        ])
            cube([
                contact_cavity_x + 2*small_extension,
                contact_cavity_y,
                contact_cavity_depth + 2*eps
            ], center=true);
    }
}



module perimeter_wire_step_cuts() {
    // Shallow L-shaped routing steps for the DAEX leads.
    //
    // The machined prototype used a 3/16-inch end mill.  To reproduce that
    // geometry, the sharp outer corner of the -X,-Y L is replaced by a
    // quarter-circle with radius wire_step_corner_r = 2.38125 mm.
    //
    // The +X,-Y step is generated by mirroring the same rounded polygon.
    //
    // The cut begins slightly below the bottom mating surface and extends
    // slightly beyond wire_step_depth to prevent residual Boolean skins.

    module rounded_left_wire_step_plan() {
        // Original key vertices, using the shared dimensional definitions.
        p0 = wire_step_left_points[0];
        p1 = wire_step_left_points[1];  // sharp corner being replaced
        p2 = wire_step_left_points[2];
        p3 = wire_step_left_points[3];
        p4 = wire_step_left_points[4];
        p5 = wire_step_left_points[5];

        r = wire_step_corner_r;
        cx = wire_step_left_corner_center_x;
        cy = wire_step_left_corner_center_y;

        // Tangency points:
        // bottom edge: from p0 toward original p1
        bottom_tangent = [p1[0] + r, p1[1]];
        // outer vertical edge: from original p1 toward p2
        vertical_tangent = [p1[0], p1[1] + r];

        // Quarter-circle from bottom tangent to vertical tangent.
        // Angles run from -90 degrees to -180 degrees.
        arc_points = [
            for (i = [0:wire_step_corner_steps])
                let(a = -90 - 90*i/wire_step_corner_steps)
                    [cx + r*cos(a), cy + r*sin(a)]
        ];

        polygon(
            points = concat(
                [p0, bottom_tangent],
                arc_points,
                [vertical_tangent, p2, p3, p4, p5]
            )
        );
    }

    module one_wire_step_cut(mirror_x=false) {
        translate([0, 0, -housing_z/2 - small_extension])
            linear_extrude(
                height = wire_step_depth + small_extension + eps
            )
                if (mirror_x)
                    mirror([1, 0, 0])
                        rounded_left_wire_step_plan();
                else
                    rounded_left_wire_step_plan();
    }

    one_wire_step_cut(false);
    one_wire_step_cut(true);
}


module wire_exit_slot_cuts() {
    // Rectangular wire exits through the -Y wall.
    // Width is along X, length is along Y, and depth is measured upward
    // from the bottom mating surface.
    //
    // The Y dimension already includes small_extension at both ends.
    // A small Z overcut below the mating surface and above the nominal depth
    // prevents residual Boolean skins.
    for (sx = [-1, 1]) {
        translate([
            sx*wire_groove_x,
            wire_groove_center_y,
            -housing_z/2 + wire_groove_depth/2 - small_extension/2
        ])
            cube([
                wire_groove_width,
                wire_groove_length,
                wire_groove_depth + small_extension + eps
            ], center=true);
    }
}

module center_through_hole_cut() {
    translate([0, 0, -housing_z/2 - eps])
        cylinder(d = center_hole_d, h = housing_z + 2*eps);
}

module tap_hole_cuts() {
    for (sx = [-1, 1])
        for (sy = [-1, 1])
            translate([
                sx*screw_center_x,
                sy*screw_center_y,
                -housing_z/2 - eps
            ])
                cylinder(d = tap_hole_d, h = tap_hole_depth + eps);
}


// ---------- Final part ----------

module DAEX_upper_housing() {
    difference() {
        exterior_body_top_and_vertical_filleted(
            housing_x,
            housing_y,
            housing_z,
            comfort_r,
            comfort_steps
        );

        // Top side
        finger_groove_cut();
        finger_groove_open_x_floor_edge_fillet_cut();

        // Bottom side
        main_daex_cavity_cut();
        ledge_cuts();
        contact_cavity_cuts();
        perimeter_wire_step_cuts();
        wire_exit_slot_cuts();

        // Holes are subtracted after exterior filleting, so hole edges are not filleted.
        center_through_hole_cut();
        tap_hole_cuts();
    }
}

// Render this part when the file is opened directly.
DAEX_upper_housing();
