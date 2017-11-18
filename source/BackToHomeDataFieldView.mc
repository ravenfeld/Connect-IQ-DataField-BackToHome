
using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.Math;

class BackToHomeDataFieldView extends Ui.DataField
{   
    hidden var SIZE_DATAFIELD_1 = 218;
    hidden var SIZE_DATAFIELD_2 = 108;
    hidden var SIZE_DATAFIELD_3 = 70;
    hidden var RAY_EARTH = 6378137; 
    hidden var heading_rad = null;
    hidden var isMetric = false;
    hidden var location_current = null;
    hidden var location_lap = null;
    hidden var northStr="";
    hidden var eastStr="";
    hidden var southStr="";
    hidden var westStr="";
    hidden var center_x;
	hidden var center_y;
	hidden var size_max;
	hidden var gps;
		
	function initialize() {
		isMetric = System.getDeviceSettings().distanceUnits == System.UNIT_METRIC;
	
		DataField.initialize();
	}
    
	function compute(info) {
		if( info.currentHeading != null ) {
			heading_rad = info.currentHeading;
		}
		location_current = info.currentLocation;
		if( !App.getApp().getProperty("return_lap_location") ) {
			location_lap = info.startLocation;
		}
		gps = info.currentLocationAccuracy;
	}
    
    function onLayout(dc) {
    	center_x = dc.getWidth() / 2;
		center_y = dc.getHeight() / 2;
		size_max = dc.getWidth() > dc.getHeight() ? dc.getHeight() : dc.getWidth();
		
		var flag = getObscurityFlags();
		if( flag == OBSCURE_BOTTOM|OBSCURE_RIGHT
			||flag == OBSCURE_BOTTOM|OBSCURE_LEFT
			||flag == OBSCURE_TOP|OBSCURE_RIGHT
			||flag == OBSCURE_TOP|OBSCURE_LEFT){
			size_max = size_max/1.25;
		}
		
		if( dc.getWidth() == dc.getHeight() ) {
			if( ( flag & OBSCURE_BOTTOM ) == OBSCURE_BOTTOM ) {
				center_y = center_y-10;
			}                
			if( ( flag & OBSCURE_RIGHT ) == OBSCURE_RIGHT ) {
				center_x = center_x-10;
			} 
			if( ( flag & OBSCURE_TOP ) == OBSCURE_TOP ) {
				center_y = center_y+10;
			}
			if( ( flag & OBSCURE_LEFT ) == OBSCURE_LEFT ) {
				center_x = center_x+10;
			}
		}
		
		northStr = Ui.loadResource(Rez.Strings.north);
		eastStr = Ui.loadResource(Rez.Strings.east);
		southStr = Ui.loadResource(Rez.Strings.south);
		westStr = Ui.loadResource(Rez.Strings.west);
    }
    
	function onUpdate(dc) {           
		var return_lap_location = App.getApp().getProperty("return_lap_location");
			
		if( heading_rad != null) {
			var map_declination =  App.getApp().getProperty("map_declination");
			if (map_declination != null ) {	
				if(map_declination instanceof Toybox.Lang.String) {
					map_declination = map_declination.toFloat();
				}
				heading_rad= heading_rad+map_declination*Math.PI/180;
			}
			
			if( heading_rad < 0 ) {
				heading_rad = 2*Math.PI+heading_rad;
			}
            				
			var orientation = null;	
			var distance = null;
			if( location_current !=null && location_lap != null ) {
				var	latitude_point_start;
				var	longitude_point_start;
				var latitude_point_arrive;
				var longitude_point_arrive;
				
				
				latitude_point_arrive = location_lap.toRadians()[0];
				longitude_point_arrive = location_lap.toRadians()[1];
				
				latitude_point_start = location_current.toRadians()[0];
				longitude_point_start = location_current.toRadians()[1];
					
				distance = Math.acos(Math.sin(latitude_point_start)*Math.sin(latitude_point_arrive) + Math.cos(latitude_point_start)*Math.cos(latitude_point_arrive)*Math.cos(longitude_point_start-longitude_point_arrive));
    		
				if( distance > 0) {
					orientation = Math.acos((Math.sin(latitude_point_arrive)-Math.sin(latitude_point_start)*Math.cos(distance))/(Math.sin(distance)*Math.cos(latitude_point_start)));
    		
					if( Math.sin(longitude_point_arrive-longitude_point_start) <= 0 ) {
						orientation = 2*Math.PI-orientation;
					}
				}
			}
			
            if( App.getApp().getProperty("display_logo_orientation") ){
            	if( orientation != null ){
					drawLogoOrientation(dc, center_x, center_y, size_max, -orientation+heading_rad);
				}else{
					drawLogoOrientation(dc, center_x, center_y, size_max, heading_rad);
				}
			}
			
			var display_text_orientation = App.getApp().getProperty("display_text_orientation");
			var display_text_distance = App.getApp().getProperty("display_text_distance");
			var position_text = App.getApp().getProperty("position_text_one");
			
			
			if( display_text_orientation ){
				var y = center_y ;
				if( display_text_distance && distance != null && distance > 0) {
					y = center_y - size_max/4+12;
				}else if( position_text == 1 ){
					y = center_y - size_max/4+12;
				}else if( position_text == 2 ){
					y = center_y;
				}else if( position_text == 3 ){
					y = center_y + size_max/4-22;
				}
				if( orientation !=null ){
					drawTextOrientation(dc, center_x, y, size_max, orientation-heading_rad);
				}else{
					drawTextOrientation(dc, center_x, y, size_max, heading_rad);
				}
			}

			if( display_text_distance && distance != null && distance > 0 ){
				var y = center_y ;
				if( display_text_orientation ) {
					y = center_y + size_max/4-12;
				}else if( position_text == 1 ){
					y = center_y - size_max/4+2;
				}else if( position_text == 2 ){
					y = center_y;
				}else if( position_text == 3 ){
					y = center_y + size_max/4-12;
				}  
				drawTextDistance(dc, center_x, y, size_max, distance*RAY_EARTH);
				
			}
			var display_compass = App.getApp().getProperty("display_compass");
			if( display_compass ){
				drawCompass(dc, center_x, center_y, size_max);
			}
			
			var display_gps = App.getApp().getProperty("display_logo_gps");
			if( display_gps ){
				var x = center_x - size_max/4-4;
				var y = center_y- size_max/4;
				if(dc.getWidth() != dc.getHeight()){
					x = 32;
					y = 32;
				} 
				
				drawGPS(dc,x,y);
			}
		}
	}
    
    function onTimerStart(){
    	if( App.getApp().getProperty("return_lap_location") ) {
    		location_lap=location_current;
    	}
    }
                
	function onTimerLap(){
		if( App.getApp().getProperty("return_lap_location") ) {
			location_lap=location_current;
		}               
	}        
    
	function drawTextDistance(dc, center_x, center_y, size, distance) {  
		var color = getColor(App.getApp().getProperty("color_text_distance"), getTextColor());
		var fontDist;          
		var fontMetric = Graphics.FONT_SMALL ;
		var display_metric = false;
		var distanceStr;
		var metricStr;
		var step_text_metric = 0;
		
		if( size >= SIZE_DATAFIELD_1 ) {
			fontDist = Graphics.FONT_NUMBER_HOT ;
			display_metric=true;
		}else if( size > SIZE_DATAFIELD_2 ){
			fontDist = Graphics.FONT_NUMBER_MEDIUM ;
			display_metric=true;
		}else if( size >= SIZE_DATAFIELD_2 ){
			fontDist = Graphics.FONT_NUMBER_MILD ;
		}else{
			fontDist = Graphics.FONT_XTINY;
		}
       
		if ( isMetric ) {
			if( distance/1000.0 >= 1 ){
				metricStr="km";
				if( distance/100000.0 >= 1 ){
					distanceStr=(distance/1000.0).format("%d");
				}else if(distance/10000.0>=1){
					distanceStr=(distance/1000.0).format("%.1f");
				}else{
					distanceStr=(distance/1000.0).format("%.2f");
				}
				if( display_metric ){
					step_text_metric = dc.getTextWidthInPixels("m", fontMetric)/2;
				}
			}else{
				metricStr="m";
				distanceStr=distance.format("%d");
			}
		}else{
			if( distance/1609.34 >= 1 ){
				metricStr="M";
				if( distance/160934.0 >= 1 ){
					distanceStr=(distance/1609.34).format("%d");
				}else if(distance/16093.4>=1){
					distanceStr=(distance/1609.34).format("%.1f");
				}else{
					distanceStr=(distance/1609.34).format("%.2f");
				}
			}else{
				metricStr="ft";
				distanceStr=(distance*3.28084).format("%d");
				if( display_metric ){
					step_text_metric = dc.getTextWidthInPixels("t", fontMetric)/2;
				}
			}
		}
		
		var distance_size =  App.getApp().getProperty("distance_size");
		fontDist = setSize(distance_size,fontDist);
		
		var text_width_dist = dc.getTextWidthInPixels(distanceStr, fontDist);
		var text_height_dist = dc.getFontHeight(fontDist);
		
		
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
		dc.drawText(center_x-step_text_metric, center_y, fontDist, distanceStr, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		if( display_metric ){
			dc.drawText(center_x+text_width_dist/2-step_text_metric, center_y+text_height_dist/4+2, fontMetric, metricStr, Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
		}

	}
    
	function drawTextOrientation(dc, center_x, center_y, size, orientation){
		var color = getColor(App.getApp().getProperty("color_text_orientation"), getTextColor());
		var fontOrientaion;
		var fontMetric = Graphics.FONT_TINY;

       	if( orientation < 0 ) {
				orientation = 2*Math.PI+orientation;
		}
		var orientationStr=Lang.format("$1$", [(orientation*180/Math.PI).format("%d")]);

		var display_metric = false;
		if(size >= SIZE_DATAFIELD_1) {
			fontOrientaion = Graphics.FONT_NUMBER_THAI_HOT ;
			display_metric=true;
		}else if( size > SIZE_DATAFIELD_2 ) {
			fontOrientaion = Graphics.FONT_NUMBER_MEDIUM ;	
			display_metric=true;
		}else if( size == SIZE_DATAFIELD_2 ) {
			fontOrientaion = Graphics.FONT_NUMBER_MILD ;
		}else{
			fontOrientaion = Graphics.FONT_XTINY;
		}
		
		var orientation_size =  App.getApp().getProperty("orientation_size");
		
		fontOrientaion=setSize(orientation_size,fontOrientaion);
		
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
		dc.drawText(center_x, center_y, fontOrientaion, orientationStr, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		if( display_metric ){
			var text_width = dc.getTextWidthInPixels(orientationStr, fontOrientaion);
			var text_height =dc.getFontHeight(fontOrientaion);
			dc.drawText(center_x+text_width/2+2, center_y-text_height/4+2, fontMetric, "o", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		}
	}
        
	function drawCompass(dc, center_x, center_y, size) {
		var colorText = getColor(App.getApp().getProperty("color_text_compass"), getTextColor());
		var colorTextNorth = getColor(App.getApp().getProperty("color_text_north"), getTextColor());
		var colorCompass = getColor(App.getApp().getProperty("color_compass"), Graphics.COLOR_RED);
		var radius = size/2-12;
		var font;
		var penWidth = 0;
		var step = 0;
		var detail = false;
		
		if( size >= SIZE_DATAFIELD_1 ) {
			penWidth=8;
			step=12;
			font = Graphics.FONT_MEDIUM;
			detail = true;
		}else if( size >= SIZE_DATAFIELD_2 ) {
			penWidth=6;
			step=20;
			font = Graphics.FONT_TINY;
		}else{
			penWidth=5;
			step=25;
			font = Graphics.FONT_XTINY;
		}

		dc.setColor(colorTextNorth, Graphics.COLOR_TRANSPARENT);
		drawTextPolar(dc, center_x, center_y, heading_rad, radius, font, northStr);
             
		dc.setColor(colorText, Graphics.COLOR_TRANSPARENT);
		drawTextPolar(dc, center_x, center_y, heading_rad + 3*Math.PI/2, radius, font, eastStr);
        
		dc.setColor(colorText, Graphics.COLOR_TRANSPARENT);
		drawTextPolar(dc, center_x, center_y, heading_rad+ Math.PI, radius, font, southStr);

		dc.setColor(colorText, Graphics.COLOR_TRANSPARENT);
		drawTextPolar(dc, center_x, center_y, heading_rad+ Math.PI / 2, radius, font, westStr);
        
		var startAngle = heading_rad*180/Math.PI - step;
		var endAngle = heading_rad*180/Math.PI + 90+ step;
       	dc.setColor(colorCompass, Graphics.COLOR_TRANSPARENT);
		dc.setPenWidth(penWidth);
		for( var i = 0; i < 4; i++ ) {
			dc.drawArc(center_x, center_y, radius, Gfx.ARC_CLOCKWISE, 90+startAngle-i*90, (360-90+endAngle.toLong()-i*90)%360 );
		}
		
		if( detail ) {
			dc.setPenWidth(penWidth/4);
			for( var i = 0; i < 12; i++) {
				if( i % 3 != 0 ) {
					var xy1 = pol2Cart(center_x, center_y, heading_rad+i*Math.PI/6, radius);
					var xy2 = pol2Cart(center_x, center_y, heading_rad+i*Math.PI/6, radius-radius/10);
					dc.drawLine(xy1[0],xy1[1],xy2[0],xy2[1]);
				}
			}  
		}     
	}
    
	function drawLogoOrientation(dc, center_x, center_y, size, orientation){
		var color = getColor(App.getApp().getProperty("color_orientation_logo"), Graphics.COLOR_LT_GRAY);
		var radius;
		
		if( size >= SIZE_DATAFIELD_1 ) {
			radius=size/3.10;
		}else if( size >= SIZE_DATAFIELD_2 ) {
			radius=size/3;
		}else{
			radius=size/2-12;
		}
		
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
	
		var xy1 = pol2Cart(center_x, center_y, orientation, radius);
		var xy2 = pol2Cart(center_x, center_y, orientation+135*Math.PI/180, radius);
		var xy3 = pol2Cart(center_x, center_y, orientation+171*Math.PI/180, radius/2.5);
		var xy4 = pol2Cart(center_x, center_y, orientation, radius/3);
		var xy5 = pol2Cart(center_x, center_y, orientation+189*Math.PI/180, radius/2.5);
		var xy6 = pol2Cart(center_x, center_y, orientation+225*Math.PI/180, radius);
		dc.fillPolygon([xy1, xy2, xy3, xy4, xy5, xy6]);
	}
    
    function drawGPS(dc, center_x,center_y){
    	var icon;
    	var quality = App.getApp().getProperty("gps_quality");
		if(getBackgroundColor() == Graphics.COLOR_BLACK){
			if(gps!=null && gps>=quality){
				icon = Ui.loadResource(Rez.Drawables.GPSFixedIconWhite);
			}else{
				icon = Ui.loadResource(Rez.Drawables.GPSNotFixedIconWhite);
			}
		}else{
			if(gps!=null && gps>=quality){
				icon = Ui.loadResource(Rez.Drawables.GPSFixedIconBlack);
			}else{
				icon = Ui.loadResource(Rez.Drawables.GPSNotFixedIconBlack);
			}
		}
		dc.drawBitmap(center_x-icon.getWidth()/2,center_y-icon.getHeight()/2,icon);	
	}
    
    
	function drawTextPolar(dc, center_x, center_y, radian, radius, font, text) {
		var xy = pol2Cart(center_x, center_y, radian, radius);
		dc.drawText(xy[0], xy[1], font, text, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
	}
    
	function pol2Cart(center_x, center_y, radian, radius) {
		var x = center_x - radius * Math.sin(radian);
		var y = center_y - radius * Math.cos(radian);
		 
		return [Math.ceil(x), Math.ceil(y)];
	}
     
   	function getColor(color_property, color_default){
        if (color_property == 1) {
        	return Gfx.COLOR_BLUE;
        }else if (color_property == 2) {
        	return Gfx.COLOR_DK_BLUE;
        }else if (color_property == 3) {
        	return Gfx.COLOR_GREEN;
        }else if (color_property == 4) {
        	return Gfx.COLOR_DK_GREEN;
        }else if (color_property == 5) {
        	return Gfx.COLOR_LT_GRAY;
        }else if (color_property == 6) {
        	return Gfx.COLOR_DK_GRAY;
        }else if (color_property == 7) {
        	return Gfx.COLOR_ORANGE;
        }else if (color_property == 8) {
        	return Gfx.COLOR_PINK;
        }else if (color_property == 9) {
        	return Gfx.COLOR_PURPLE;
        }else if (color_property == 10) {
        	return Gfx.COLOR_RED;
        }else if (color_property == 11) {
        	return Gfx.COLOR_DK_RED;
        }else if (color_property == 12) {
        	return Gfx.COLOR_YELLOW;
        }
        return color_default;
    }  
        
    function getTextColor(){
    	return (getBackgroundColor() == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
    }  
    
    function setSize(size, default_font){
    	if(size==1){
    		return Graphics.FONT_TINY;
    	}else if(size==2){
    		return Graphics.FONT_NUMBER_MILD;
    	}else if(size==4){
    		return Graphics.FONT_NUMBER_HOT;
    	}else if(size==5){
    		return Graphics.FONT_NUMBER_THAI_HOT;
    	}else{
    		return default_font;
    	}
    }
}
