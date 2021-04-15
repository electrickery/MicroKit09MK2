// microKitKeyboardOverlayFrame2

keyDistX = 12.065; // 4.8 * inch;
keyDistY = 8.890; // 3.5 * inch;
keyTopHeight = 5.0 + 0.3;
panelThick = 3.0;
panelWidth = 99.568; //keyDistX * 8 + keyTopWidth + 2.0;
panelHeight = keyDistY * 5 + keyTopHeight + 2.0;

frameRim = 1.2;

frameTopHeight = 0.5;
frameWidth  = panelWidth + frameRim * 2;
frameHeight = panelHeight + frameRim * 2;
frameDepth = 3.0;

difference() {
    taperFrame(frameWidth, frameHeight, frameDepth, 0.99);
    translate([frameRim * 2, frameRim * 2, -0.01])
        cube([panelWidth - frameRim * 2, panelHeight - frameRim * 2, panelThick]);
    translate([frameRim, frameRim, frameTopHeight])
        cube([panelWidth, panelHeight, panelThick]);
    translate([0,0,-0.01]) cube([frameWidth, 0.5, frameDepth + 0.1]);
}

module taperFrame(width, height, thickness, tapering) {
    translate([width / 2, height / 2, 0]) {
      linear_extrude(height = thickness, scale = tapering) 
        square([width, height], center = true);
    }
}