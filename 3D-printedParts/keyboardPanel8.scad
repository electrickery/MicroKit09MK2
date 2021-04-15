// keyboardPanel8

inch = 2.54;
$fn =  32;

keyDistX = 12.065; // 4.8 * inch;
keyDistY = 8.890; // 3.5 * inch;
//echo("keyDistX: ", keyDistX);
//echo("keyDistY: ", keyDistY);

//rowOffset = keyTopWidth / 2 + 2.5; // 4.191; // 
//columnOffset = keyTopHeight; // 7.684; // ;


keyTopWidth = 8.0 + 0.3;
keyTopHeight = 5.0 + 0.3;
keyTopThickness = 5.0;
keyTopHoleDepth = 4.0;
keyTopZoffset = keyTopThickness - keyTopHoleDepth;
keyTopRimZOffset = 3.5;
rimSize = 0.5 + 0.2;
keyHoleTaper = 1.05;
skirtWall = 1.5;

panelThick = 3.0;
panelWidth = 99.568; //keyDistX * 8 + keyTopWidth + 2.0;
panelHeight = keyDistY * 5 + keyTopHeight + 2.0;
echo("panelWidth: ", panelWidth); // 99.568
echo("panelHeight:", panelHeight);

standDiam = 4.0;
standHole = 1.9;
standHeight = 7.4;

module panelPcbStand() {
    taper = 0.7;
    taperHeight = standHeight -  taper;
    difference() {
        cylinder(d = standDiam, h = standHeight);
        translate([0, 0, -0.01]) cylinder(d = standHole, h = standHeight + 0.02);
        translate([0, 0, taperHeight]) cylinder(d1 = standHole, d2 = standHole + 0.5, h = taper + 0.01);
    }
}

module keyCutouts() {
    rowLength = 7;
    columnLength = 4;
    rowOffset = keyTopWidth / 2 - 1.15; // + 2.5
    columnOffset = keyTopHeight - 0.85; 
    for (x = [0.0: 1.0: rowLength]) {
        for (y = [0.0: 1.0: columnLength]) {
            translate([keyDistX * x + rowOffset, keyDistY * y + columnOffset, -0.01])
                key();
        }
    }
}

module key() {
    // key proper
    taperKeyHole(keyTopWidth, keyTopHeight, keyTopThickness, keyHoleTaper);
    // key rim
    translate([-rimSize, -rimSize, keyTopRimZOffset])
//         cube([keyTopWidth + rimSize * 2, 
//            keyTopHeight + rimSize * 2, 
//            keyTopThickness - keyTopRimZOffset]);
    taperKeyHole(keyTopWidth + rimSize * 2, 
            keyTopHeight + rimSize * 2, 
            keyTopThickness - keyTopRimZOffset,
            keyHoleTaper);
}

module panel() {
    difference() {
        cube([panelWidth, panelHeight, panelThick]);
        translate([0, 0, -1.3]) keyCutouts();
    }
    // mask most top row holes
    translate([0, 0, 0]) cube([73.0, 12.0, panelThick]);
}

//difference() {
    panel();
//    translate([3, 10, -0.01])
//        color("gray") 
//            microKitText();
//}
translate([0, 0, panelThick]) keyBoardSkirt();

startXOffset = 13.0;
startYOffset = 11.5;
distX1 = 36.068;
distX2 = 36.322;
distY = 36.068;

translate([0, 0, panelThick]) {
    
    translate([startXOffset, startYOffset, 0]) panelPcbStand();
    translate([startXOffset + distX1, startYOffset, 0]) panelPcbStand();
    translate([startXOffset + distX1 + distX2, startYOffset, 0]) panelPcbStand();
    translate([startXOffset, startYOffset + distY, 0]) panelPcbStand();
    translate([startXOffset + distX1, startYOffset + distY, 0]) panelPcbStand();
    translate([startXOffset + distX1 + distX2, startYOffset + distY, 0]) panelPcbStand();
}

module taperKeyHole(width, height, thickness, tapering) {
    translate([width / 2, height / 2, 0]) {
      linear_extrude(height = thickness, scale = tapering) 
        square([width, height], center = true);
    }
}

module keyBoardSkirt() {
  difference() {
    cube([panelWidth, panelHeight, standHeight]);
    translate([skirtWall, skirtWall, -0.01])
      cube([panelWidth - skirtWall * 2, panelHeight - skirtWall * 2, standHeight + 0.02]);
  }
}

module microKitText() {
    mirror([0,1,0])
    minkowski() {
        linear_extrude(height = 0.1) { 
            text("MicroKIT09 MK2", 6);}
        cylinder(d1=0.5, d2=0.01, h=1);
    }
}


