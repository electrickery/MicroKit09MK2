// tapeFrame3

$fn = 16;

keyTopWidth = 8.0 + 0.3;
keyTopHeight = 5.0 + 0.3;
keyTopDepth = 5.0;
rimSize = 0.5 + 0.2;

frameWidth = 13.0;
frameHeight = 6.0;
frameDepth = keyTopDepth;
frameBase = 2.0;
rowOffset = 3.0;
columnXOffset = 5.0;
columnYOffset = 6.0;

tapeWidth = 12.2;
sideWallWidth = 1.5;

module key() {
    translate([-keyTopHeight / 2 - rimSize, -keyTopWidth / 2 - rimSize, -0.01]) 
        cube([keyTopHeight + rimSize * 2, keyTopWidth + rimSize * 2, rimSize]);
    translate([-keyTopHeight / 2, -keyTopWidth / 2, rimSize-0.01]) 
   //     #cube([keyTopHeight, keyTopWidth, keyTopDepth - rimSize]);
    pyramidoid();
}

module pyramidoid() {
    height = keyTopDepth - rimSize + 0.01;
    hull() {
        translate([0,0, 0]) 
            cylinder(r1 = rimSize, r2 = 0.1, h = height);
        translate([0, keyTopWidth, 0]) 
            cylinder(r1 = rimSize, r2 = 0.1, h = height);
        translate([keyTopHeight, 0, 0]) 
            cylinder(r1 = rimSize, r2 = 0.1, h = height);
        translate([keyTopHeight, keyTopWidth, 0]) 
            cylinder(r1 = rimSize, r2 = 0.1, h = height);
    }
}

module frameRow() {
    minkowski() {
        cube([frameWidth, 0.1, 0.1]);
        cylinder(d1 = frameBase, d2 = 0.2, h = frameDepth - 0.12);
    }
}

module frameColumn() {
    minkowski() {
        cube([0.1, frameHeight * 2, 0.1]);
        cylinder(d1 = frameBase, d2 = 0.2, h = frameDepth - 0.12);
    }
}

module frame() {
difference() {
    union() {
        translate([0, -rowOffset, 0]) frameRow();
        translate([0, 0, 0]) frameRow();
        translate([0, rowOffset, 0]) frameRow();
        translate([columnXOffset-0.5, -columnYOffset, 0]) frameColumn();
        translate([columnXOffset+2.7, -columnYOffset, 0]) frameColumn();
        // base plate
        translate([0, -frameHeight, 0])
           cube([frameWidth + 1, frameHeight * 2, 0.4]);
    }
    translate([tapeWidth / 2, 0, -0.01]) key();
}

translate([-sideWallWidth, -frameHeight, 0])
    cube([sideWallWidth, frameHeight * 2, frameDepth + 1.0]);
translate([tapeWidth, -frameHeight, 0])
    cube([sideWallWidth, frameHeight * 2, frameDepth + 1.0]);
}

frame();