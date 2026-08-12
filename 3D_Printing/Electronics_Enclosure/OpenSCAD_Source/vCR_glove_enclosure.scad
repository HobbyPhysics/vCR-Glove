/*
Vibrotactile CR Glove Electronics Enclosure

Units: mm

User coordinate system for all supplied plan-view dimensions:
  origin = upper-left outside corner of box
  X = left to right
  Y = upper/back edge toward lower/front edge
  Z = outside bottom upward

OpenSCAD uses Y upward in top view.  The script converts user Y coordinates
internally with: Y_scad = Box_length - Y_user.

STL export:
  Set output_part to "box" or "top", render (F6), then export STL.
  "assembly" and "exploded" are intended for visual review.
*/

// -------------------------
// Display / export controls
// -------------------------
output_part = "top";   // "box", "top", "assembly", "exploded"
show_reference_parts = true;
exploded_gap = 8;

$fn = 48;
eps = 0.05;

// -------------------------
// PCB independent dimensions
// -------------------------
PCB_width       = 54.6;
PCB_length      = 45.2;
PCB_cor_width   = 7.0;
PCB_cor_length  = 8.0;

PCB_h1C_X       = 4.5;
PCB_h1C_Y       = 4.5;
PCB_h2C_X       = 43.73;
PCB_h2C_Y       = 4.5;

PCB_USBC_Y      = 34.55;
PCB_LED_X       = 11.75;
PCB_LED_Y       = 11.0;

PCB_t           = 1.61;
PCB_xiao_t      = 6.1;
PCB_usb_t       = 4.4;
PCB_conn_t      = 5.0;

// -------------------------
// Box independent dimensions
// -------------------------
Box_width           = 60.0;
Box_length          = 64.0;
Box_wall_thickness  = 2.0;
Box_fillet_radius   = 1.0;

Box_conn_slot_width = 32.0;
Box_usb_slot_width  = 13.0;

Box_post_d          = 5.5;
Box_post_tap        = 2.25;
Box_post_hole_depth = 8.0;

// Vertical reinforcing ribs from each cover post to its nearest side wall.
// Post 1 connects to the +X wall; post 2 connects to the -X wall.
Box_post_fin_t      = 2.0;

Box_standoff_d      = 5.5;
Box_standoff_tap    = 2.25;  // approximately a 4-40 tap-drill diameter

Box_Switch_d        = 6.4;
Box_Button_d        = 11.8;
Box_Pot_d           = 7.1;

Box_potC_X          = 13.9;
Box_swC_X           = 48.0;


// Front panel embossed ON label
Box_On_text        = "ON";
Box_OnC_X          = (Box_width + (Box_swC_X + Box_Switch_d/2))/2;
Box_OnC_Y          = Box_length;
Box_On_size        = 3.5;
Box_On_depth       = 0.5;
Box_On_font        = "Arial:style=Bold";

// -------------------------
// Top independent dimensions
// -------------------------
Top_thickness       = 4.0;
Top_post_d          = 3.3;
Top_LED_hole_d      = 3.05;
Top_LED_pitch       = 8.25;
Top_gap             = 1.0;

// Independent flat-head countersink depth.
// The taper is defined by Top_post_d, Top_counter_d, and Top_counter_depth.
Top_counter_d     = 6.5;
Top_counter_depth = 2.4;

// 3 mm LED package geometry.
// If the top is thicker than the straight cylindrical LED body,
// a bottom-side recess is automatically added around each LED hole.
LED_cyl_z           = 3.3;
LED_base_dia        = 3.7;
LED_recess_z        = max(0, Top_thickness - LED_cyl_z);

// Radius removed from the upper perimeter of the top plate.
// The underside remains flat and full size for mating to the box.
Top_edge_radius     = 1.0;

// -------------------------
// Battery independent dimensions
// -------------------------
Battery_t           = 8.0;
Battery_tape_t      = 1.0;
Battery_PCB_gap     = 2.2;

// Reference-only battery plan dimensions; edit when known.
Battery_width       = 34.0;
Battery_length      = 44.0;

// Convert a user-coordinate Y center (measured down from the upper edge)
// to the native OpenSCAD Y coordinate.
function user_y_to_scad(y_user) = Box_length - y_user;

// -------------------------
// Derived dimensions
// -------------------------
Box_inner_depth = Battery_tape_t
                + Battery_t
                + Battery_PCB_gap
                + PCB_t
                + PCB_xiao_t
                + Top_gap;

// Box shell height is independent of the removable top thickness.
// It consists of the bottom wall plus the required clear internal depth.
Box_shell_height = Box_wall_thickness + Box_inner_depth;

// Overall assembled enclosure depth includes the separate top.
Box_depth = Box_shell_height + Top_thickness;

Box_inner_width  = Box_width  - 2*Box_wall_thickness;
Box_inner_length = Box_length - 2*Box_wall_thickness;
Box_inner_corner_radius = max(0.5, Box_fillet_radius - Box_wall_thickness);

Box_PCB_dx = Box_width - PCB_width - Box_wall_thickness;
Box_PCB_dy = Box_wall_thickness;

Box_post1C_X = Box_PCB_dx + PCB_width - PCB_cor_width/2;
Box_post1C_Y = Box_PCB_dy + PCB_cor_length/2;
Box_post2C_X = Box_width - Box_post1C_X;
Box_post2C_Y = Box_length - Box_post1C_Y;
Box_post_height = Box_inner_depth;

Box_stand1C_X = PCB_h1C_X + Box_PCB_dx;
Box_stand1C_Y = PCB_h1C_Y + Box_PCB_dy;
Box_stand2C_X = PCB_h2C_X + Box_PCB_dx;
Box_stand2C_Y = PCB_h2C_Y + Box_PCB_dy;
Box_stand_height = Battery_tape_t + Battery_t + Battery_PCB_gap;

Box_conn_slotC_X = (PCB_h2C_X + PCB_h1C_X)/2 + Box_PCB_dx;
Box_conn_slotC_Y = Box_wall_thickness/2;
Box_conn_slot_depth = Top_gap + PCB_conn_t + PCB_t;

Box_usb_slotC_X = Box_width - Box_wall_thickness/2;
Box_usb_slotC_Y = PCB_USBC_Y + Box_PCB_dy;
Box_usb_slot_depth = Top_gap + PCB_usb_t;

Box_button_X = (Box_potC_X + Box_swC_X)/2;
Box_crtlC_Z = Box_inner_depth/2 + Box_wall_thickness;

Top_LED1C_X = PCB_LED_X + Box_PCB_dx;
Top_LED2C_X = Top_LED1C_X + Top_LED_pitch;
Top_LED3C_X = Top_LED2C_X + Top_LED_pitch;
Top_LED4C_X = Top_LED3C_X + Top_LED_pitch;
Top_LEDC_Y = PCB_LED_Y + Box_PCB_dy;

PCB_bottom_Z = Box_wall_thickness + Box_stand_height;
PCB_top_Z = PCB_bottom_Z + PCB_t;

// Native OpenSCAD Y coordinates derived from the user's upper-left origin.
PCB_scad_y = Box_length - Box_PCB_dy - PCB_length;

Box_post1C_Y_scad = user_y_to_scad(Box_post1C_Y);
Box_post2C_Y_scad = user_y_to_scad(Box_post2C_Y);

Box_stand1C_Y_scad = user_y_to_scad(Box_stand1C_Y);
Box_stand2C_Y_scad = user_y_to_scad(Box_stand2C_Y);

Box_conn_slotC_Y_scad = user_y_to_scad(Box_conn_slotC_Y);
Box_usb_slotC_Y_scad = user_y_to_scad(Box_usb_slotC_Y);

Top_LEDC_Y_scad = user_y_to_scad(Top_LEDC_Y);
Box_OnC_Y_scad = user_y_to_scad(Box_OnC_Y);

// -------------------------
// Utility geometry
// -------------------------

module rounded_cuboid(size=[10,10,10], r=1) {
    assert(min(size) >= 2*r,
        "rounded_cuboid radius is too large for the requested size");
    minkowski() {
        translate([r, r, r])
            cube([size[0]-2*r, size[1]-2*r, size[2]-2*r]);
        sphere(r=r);
    }
}

module rounded_xy_prism(size=[10,10,10], r=1) {
    // Exact overall X-Y size: 0..size[0] and 0..size[1].
    // The translation is essential because offset() expands in all directions.
    linear_extrude(height=size[2])
        offset(r=r)
            translate([r,r])
                square([size[0]-2*r, size[1]-2*r]);
}

module box_outer_with_square_top(size=[10,10,10], r=1) {
    // Rounded bottom and vertical outside edges, but a square upper perimeter
    // for full contact with the flat underside of the cover.
    union() {
        rounded_cuboid(size, r);
        translate([0,0,r])
            rounded_xy_prism([size[0], size[1], size[2]-r], r);
    }
}


module top_plate_with_upper_edge_fillet(size=[10,10,2], r=1) {
    /*
    Produces a plate with:
      - a flat, full-size lower mating surface;
      - vertical sides over the lower portion;
      - a convex fillet around the entire upper perimeter.

    Construction:
      A fully rounded cuboid is shifted downward by r so its lower fillet
      finishes exactly at Z=0.  Cropping it to Z=0..size[2] retains only
      the upper edge fillet.
    */
    assert(r > 0, "Top edge fillet radius must be greater than zero");
    assert(size[2] >= r,
        "Top thickness must be at least as large as Top_edge_radius");

    intersection() {
        translate([0,0,-r])
            rounded_cuboid(
                [size[0], size[1], size[2] + r],
                r
            );

        cube(size);
    }
}



module box_on_label_cut()
{
    /*
    Recessed front-wall lettering.

    Box_OnC_Y uses the user's upper-left drawing coordinates.
    Box_OnC_Y = Box_length converts to native OpenSCAD Y = 0,
    which is the front wall.

    The text cutter starts Box_On_depth inside the front wall and
    extrudes outward through the surface.  The additional eps avoids
    a coincident cutter/part surface during the Boolean subtraction.
    */
    translate([
        Box_OnC_X,
        Box_OnC_Y_scad + Box_On_depth,
        Box_crtlC_Z
    ])
        rotate([90,0,0])
            linear_extrude(height=Box_On_depth + eps)
                text(Box_On_text,
                     size=Box_On_size,
                     font=Box_On_font,
                     halign="center",
                     valign="center");
}

module post_fin_to_x_wall(post_x, post_y, direction=1) {
    /*
    Full-height vertical reinforcing rib.

    direction = +1: rib extends from the post center toward the +X wall.
    direction = -1: rib extends from the -X wall toward the post center.

    The rib overlaps the cylindrical post and the side wall so the exported
    part is one continuous solid.
    */
    inner_left_x  = Box_wall_thickness;
    inner_right_x = Box_width - Box_wall_thickness;

    if (direction > 0) {
        translate([
            post_x,
            post_y - Box_post_fin_t/2,
            Box_wall_thickness
        ])
            cube([
                inner_right_x - post_x + eps,
                Box_post_fin_t,
                Box_post_height
            ]);
    }
    else {
        translate([
            inner_left_x - eps,
            post_y - Box_post_fin_t/2,
            Box_wall_thickness
        ])
            cube([
                post_x - inner_left_x + eps,
                Box_post_fin_t,
                Box_post_height
            ]);
    }
}

module vertical_tapped_hole(x, y, z_top, depth, d) {
    translate([x, y, z_top-depth])
        cylinder(h=depth+eps, d=d);
}

module front_control_hole(x, z, d) {
    // Front wall is Y=0 in native OpenSCAD coordinates.
    // Start well outside the enclosure and cut through the complete wall.
    translate([x, -1.0, z])
        rotate([-90,0,0])
            cylinder(h=Box_wall_thickness+2.0, d=d);
}

module top_fastener_hole(x, y) {
    translate([x, y, -eps])
        cylinder(h=Top_thickness+2*eps, d=Top_post_d);

    translate([x, y, Top_thickness-Top_counter_depth])
        cylinder(
            h=Top_counter_depth+eps,
            d1=Top_post_d,
            d2=Top_counter_d
        );
}

// -------------------------
// Bottom shell
// -------------------------

module enclosure_box() {
    difference() {
        union() {
            difference() {
                box_outer_with_square_top(
                    [Box_width, Box_length, Box_shell_height],
                    Box_fillet_radius
                );

                // Open-top inner cavity.
                translate([
                    Box_wall_thickness,
                    Box_wall_thickness,
                    Box_wall_thickness
                ])
                    rounded_xy_prism(
                        [
                            Box_inner_width,
                            Box_inner_length,
                            Box_shell_height
                        ],
                        Box_inner_corner_radius
                    );

                // Rear JST opening, open at the upper rim.
                translate([
                    Box_conn_slotC_X - Box_conn_slot_width/2,
                    Box_length - Box_wall_thickness - eps,
                    Box_shell_height - Box_conn_slot_depth
                ])
                    cube([
                        Box_conn_slot_width,
                        Box_wall_thickness + 2*eps,
                        Box_conn_slot_depth + eps
                    ]);

                // Right-side USB-C opening, open at the upper rim.
                translate([
                    Box_width - Box_wall_thickness - 1.0,
                    Box_usb_slotC_Y_scad - Box_usb_slot_width/2,
                    Box_shell_height - Box_usb_slot_depth
                ])
                    cube([
                        Box_wall_thickness + 2.0 + 2*eps,
                        Box_usb_slot_width,
                        Box_usb_slot_depth + eps
                    ]);

                // Front controls.
                front_control_hole(Box_potC_X,   Box_crtlC_Z, Box_Pot_d);
                front_control_hole(Box_button_X, Box_crtlC_Z, Box_Button_d);
                front_control_hole(Box_swC_X,    Box_crtlC_Z, Box_Switch_d);
            }

            // Diagonal full-height cover posts.
            translate([Box_post1C_X, Box_post1C_Y_scad, Box_wall_thickness])
                cylinder(h=Box_post_height, d=Box_post_d);

            translate([Box_post2C_X, Box_post2C_Y_scad, Box_wall_thickness])
                cylinder(h=Box_post_height, d=Box_post_d);

            // Full-height reinforcing fins to the nearest side walls.
            post_fin_to_x_wall(
                Box_post1C_X,
                Box_post1C_Y_scad,
                +1
            );

            post_fin_to_x_wall(
                Box_post2C_X,
                Box_post2C_Y_scad,
                -1
            );

            // PCB standoffs.
            translate([Box_stand1C_X, Box_stand1C_Y_scad, Box_wall_thickness])
                cylinder(h=Box_stand_height, d=Box_standoff_d);

            translate([Box_stand2C_X, Box_stand2C_Y_scad, Box_wall_thickness])
                cylinder(h=Box_stand_height, d=Box_standoff_d);
        }

        // Blind tapped holes in cover posts.
        vertical_tapped_hole(
            Box_post1C_X, Box_post1C_Y_scad,
            Box_shell_height, Box_post_hole_depth, Box_post_tap
        );
        vertical_tapped_hole(
            Box_post2C_X, Box_post2C_Y_scad,
            Box_shell_height, Box_post_hole_depth, Box_post_tap
        );

        // PCB standoff tap holes; floor remains intact.
        translate([
            Box_stand1C_X,
            Box_stand1C_Y_scad,
            Box_wall_thickness-eps
        ])
            cylinder(h=Box_stand_height+2*eps, d=Box_standoff_tap);

        translate([
            Box_stand2C_X,
            Box_stand2C_Y_scad,
            Box_wall_thickness-eps
        ])
            cylinder(h=Box_stand_height+2*eps, d=Box_standoff_tap);

        // Recessed front-panel ON lettering.
        //box_on_label_cut();
    }
}

// -------------------------
// Top cover
// -------------------------

module enclosure_top() {
    difference() {
        // Flat full-size underside with a 1 mm fillet removed from
        // the entire upper perimeter edge.
        top_plate_with_upper_edge_fillet(
            [Box_width, Box_length, Top_thickness],
            Top_edge_radius
        );

        top_fastener_hole(Box_post1C_X, Box_post1C_Y_scad);
        top_fastener_hole(Box_post2C_X, Box_post2C_Y_scad);

        for (x = [
            Top_LED1C_X,
            Top_LED2C_X,
            Top_LED3C_X,
            Top_LED4C_X
        ]) {
            // Through hole for the 3 mm LED cylindrical body.
            translate([x, Top_LEDC_Y_scad, -eps])
                cylinder(h=Top_thickness+2*eps, d=Top_LED_hole_d);

            // Bottom-side counterbore for the wider LED base/flange.
            // This exists only when Top_thickness > LED_cyl_z.
            if (LED_recess_z > 0)
                translate([x, Top_LEDC_Y_scad, -eps])
                    cylinder(h=LED_recess_z+eps, d=LED_base_dia);
        }
    }
}

// -------------------------
// Reference-only components
// -------------------------

module pcb_reference() {
    board_pts = [
        [0,0],
        [PCB_width-PCB_cor_width,0],
        [PCB_width-PCB_cor_width,PCB_cor_length],
        [PCB_width,PCB_cor_length],
        [PCB_width,PCB_length],
        [0,PCB_length]
    ];

    %translate([Box_PCB_dx, PCB_scad_y, PCB_bottom_Z])
        linear_extrude(height=PCB_t)
            polygon(board_pts);

    %translate([
        Box_PCB_dx + PCB_width - 18,
        user_y_to_scad(Box_PCB_dy + PCB_USBC_Y) - 9,
        PCB_top_Z
    ])
        cube([18,18,PCB_xiao_t]);
}

module battery_reference() {
    %translate([
        (Box_width-Battery_width)/2,
        (Box_length-Battery_length)/2,
        Box_wall_thickness + Battery_tape_t
    ])
        cube([Battery_width, Battery_length, Battery_t]);
}

module assembly(explode=0) {
    enclosure_box();

    translate([0,0,Box_shell_height+explode])
        enclosure_top();

    if (show_reference_parts) {
        pcb_reference();
        battery_reference();
    }
}

// -------------------------
// Output selector
// -------------------------

if (output_part == "box") {
    enclosure_box();
}
else if (output_part == "top") {
    enclosure_top();
}
else if (output_part == "exploded") {
    assembly(exploded_gap);
}
else {
    assembly(0);
}

// -------------------------
// Console checks
// -------------------------
echo("Box_inner_depth =", Box_inner_depth);
echo("Box_shell_height =", Box_shell_height);
echo("Top_thickness =", Top_thickness);
echo("LED_recess_z =", LED_recess_z);
echo("Box_depth assembled =", Box_depth);
echo("PCB bottom Z =", PCB_bottom_Z);
echo("PCB top Z =", PCB_top_Z);
echo("Cover post 1 user XY =", [Box_post1C_X, Box_post1C_Y]);
echo("Cover post 1 SCAD XY =", [Box_post1C_X, Box_post1C_Y_scad]);
echo("Cover post 2 user XY =", [Box_post2C_X, Box_post2C_Y]);
echo("Cover post 2 SCAD XY =", [Box_post2C_X, Box_post2C_Y_scad]);
echo("PCB standoff 1 user XY =", [Box_stand1C_X, Box_stand1C_Y]);
echo("PCB standoff 2 user XY =", [Box_stand2C_X, Box_stand2C_Y]);
