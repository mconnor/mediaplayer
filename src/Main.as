/*

Complete thumb grid

Create toggle icon states for
thubnail
fullscreen

Add basic preloader for images

Consider overlay centered video controls while in fullscreen

Offer defaults and overrides for configuration

*/

package
{
	
	import flash.display.*;
	import flash.utils.*;
	import flash.net.*;
	import flash.events.*;
	import flash.text.*;
	import flash.system.Capabilities;
	import flash.ui.Keyboard;
	import flash.geom.Rectangle;
	
	import com.a12.util.*;
	import com.a12.modules.mediaplayback.*;
	
	import com.gs.TweenLite;
	
	import ThumbGrid;
	
	import com.carlcalderon.arthropod.Debug;
	
	final public class Main extends Sprite
	{
		
		private var _ref:MovieClip;
		public var Layout:Object;
		
		//private var flagFullscreen:Boolean;
		private var flagPlaying:Boolean;
		private var flagThumbs:Boolean;
		
		public var slideIndex:int;
		public var slideMax:int;
		private var slideA:Array;
		
		private var slideInterval:Number;
		private var uiInterval:Number;
		
		private var progressOffset:Number;
		private var progressInterval:Number;
		
		private var configObj:Object;
		private var myTimer:Timer;	
		private var timestamp:Number;	
		
		private var MP:com.a12.modules.mediaplayback.MediaPlayback;
		private var thumbClass:ThumbGrid;
		
		public function Main()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			configObj = 
			{
				thumbgrid:true,
				fullscreen:true,
				duration:5000,
				slideshow:true,
				scalestage:true
			}
			
			Layout = 
			{
				marginX:0,
				marginY:0
			}
			
			
			var xml;
			
			if(Capabilities.playerType == "External"){
				xml = '../xml/gallery.xml';
			}
			else {
				
			}
			
			//root.loaderInfo.parameters.src = '/assets/img/final_reel.flv';
			
			if(root.loaderInfo.parameters.src){
				slideA = [{id:0,file:root.loaderInfo.parameters.src}];
				slideMax = 1;
				init();
			}else{
			
				if(root.loaderInfo.parameters.xml){
					xml = root.loaderInfo.parameters.xml;
				}
				new XMLLoader(xml,parseXML,this);
			}
			
			
			
			
			//slideA = [{id:0,file:'/assets/img/final_reel.flv'}];
			//slideMax = 1;
			//init();
			
			
			//Debug.clear();
			
			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
		}
		
		private function parseXML(xml:String):void
		{
			var tXML:XML = new XML(xml);
			//parse config information
			
			//var snip:XMLList = tXML.RecordSet.(@Type == "Slides");
			var snip:XMLList = tXML.slides;
			var i:int=0;
			slideA = [];			
			for each(var node:XML in snip..slide){
				slideA.push(
					{
						id		: i,
						file	: node.file,
						thumb	: node.thumb
					}
				);
				i++;
			}			
			slideMax = i;
			
			
			init();
			
			
		}
		
		private function init():void
		{
			flagThumbs = false;
			
			if(slideMax > 1){
								
				flagPlaying = true;
				slideIndex = -1;
				buildUI();
				advanceSlide(1);
						
			}else{
				flagPlaying = false;
				configObj.slideshow = false;
				configObj.thumbgrid = false;
				slideIndex = -1;
				buildUI();
				advanceSlide(1);
			}
			
			//listen to the mouse event to hide or show ui
			stage.addEventListener(Event.MOUSE_LEAVE, mouseListener);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseListener);
			//track keyboard navigation
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyListener);
		}
		
		private function mouseListener(e:Event):void
		{
			if(e.type == MouseEvent.MOUSE_MOVE){
				showUI();
			}
			if(e.type == Event.MOUSE_LEAVE){
				hideUI();
			}
		}
		
		private function showUI():void
		{
			//start timer to hideUI
			clearTimeout(uiInterval);
			uiInterval = setTimeout(hideUI,3000);
			TweenLite.to(MovieClip(this.stage.getChildByName('ui')),0.5,{alpha:1.0});
			
			if(MP != null){
				var mc = Utils.$(MP._view.ref,'controls');
				TweenLite.to(MovieClip(mc),0.5,{alpha:1.0});
			}
		}
		
		private function hideUI():void
		{
			clearTimeout(uiInterval);
			TweenLite.to(MovieClip(this.stage.getChildByName('ui')),0.5,{alpha:0.0});
			
			if(MP != null){
				var mc = Utils.$(MP._view.ref,'controls');
				TweenLite.to(MovieClip(mc),0.5,{alpha:0.0});
			}
		}
		
		private function handleIconsMouse(e:Event):void
		{
			//get the type, process the target
			var mc = DisplayObject(e.target);
			
			if(mc.name == 'nav_prev' || mc.name == 'nav_next'){
				if(e.type == MouseEvent.MOUSE_OVER){
					TweenLite.to(MovieClip(mc),0.2,{scaleX:1.2,scaleY:1.2});
				}
				if(e.type == MouseEvent.MOUSE_OUT){
					TweenLite.to(MovieClip(mc),0.5,{scaleX:1.0,scaleY:1.0});
				}
				if(e.type == MouseEvent.CLICK){
					//TweenLite.to(MovieClip(mc),0.2,{scaleX:1.0,scaleY:1.0});
					advanceSlide(mc.dir);
				}
			}
		}
		
		private function buildUI():void
		{			
			var ui = Utils.createmc(this.stage,'ui',{alpha:0});
			//this.stage.setChildIndex(ui,1);
			//top bar			
			//full screen, thumbnail, timer/toggle, status
			
			
			//handle mouse over generic
			//handle mouse out generic
			
			var i,mc,xPos;
			
			if(configObj.fullscreen == true){
			
				i = new mediaplayer_icons();
				i.gotoAndStop('fullscreen');
				mc = ui.addChild(i);
				mc.name = 'fullscreen';
				mc.buttonMode = true;
				mc.y = 14;
				mc.addEventListener(MouseEvent.ROLL_OVER,handleIconsMouse);
				mc.addEventListener(MouseEvent.ROLL_OUT,handleIconsMouse);
				mc.addEventListener(MouseEvent.CLICK,toggleFullScreen);
				mc.xPos = 14;
				xPos = 14;
			
			}
			
			if(configObj.thumbgrid == true){
				i = new mediaplayer_icons();
				i.gotoAndStop('thumbnail');
				mc = ui.addChild(i);
				mc.name = 'thumbnail';
				mc.buttonMode = true;
				mc.y = 14;
				mc.addEventListener(MouseEvent.ROLL_OVER,handleIconsMouse);
				mc.addEventListener(MouseEvent.ROLL_OUT,handleIconsMouse);
				mc.addEventListener(MouseEvent.CLICK,toggleThumbs);
				if(xPos == 14){
					mc.xPos = 38;
				}else{
					mc.xPos = 14;
				}
			}
			
			xPos = 6;
			
			if(configObj.slideshow == true){
				i = new icon_timer();
				if(flagPlaying){			
					i.gotoAndStop('pause');
				}else{
					i.gotoAndStop('play');
				}
				mc = ui.addChild(i);
				mc.name = 'toggle';
				mc.buttonMode = true;	
				mc.x = 14;
				mc.y = 14;
				mc.addEventListener(MouseEvent.ROLL_OVER,handleIconsMouse);
				mc.addEventListener(MouseEvent.ROLL_OUT,handleIconsMouse);
				mc.addEventListener(MouseEvent.CLICK,toggleSlideShow);
				xPos = 28;
			}		
				
			
			
			if(slideMax > 1){
			
				var tf = new TextFormat();
				tf.font = 'Akzidenz Grotesk';
				tf.size = 10;
				tf.color = 0xFFFFFF;
			
				mc = Utils.createmc(ui,'label');
				Utils.makeTextfield(mc,'',tf,{width:100});
				mc.x = xPos;
				mc.y = 7;
				
				//nav 
				//left, right
				i = new mediaplayer_icons();
				i.gotoAndStop('nav_arrow');
				mc = ui.addChild(i);
				mc.dir = -1;
				mc.name = 'nav_prev';
				mc.x = 15;
				mc.y = 100;
				mc.alpha = 0.75;
				mc.buttonMode = true;
				mc.addEventListener(MouseEvent.MOUSE_OVER,handleIconsMouse);
				mc.addEventListener(MouseEvent.MOUSE_OUT,handleIconsMouse);
				mc.addEventListener(MouseEvent.CLICK,handleIconsMouse);
			
				i = new mediaplayer_icons();
				i.gotoAndStop('nav_arrow');
				mc = ui.addChild(i);
				mc.dir = 1;
				mc.name = 'nav_next';
				mc.rotation = 180;
				mc.x = 575;
				mc.y = 100;
				mc.alpha = 0.75;
				mc.buttonMode = true;
				mc.addEventListener(MouseEvent.MOUSE_OVER,handleIconsMouse);
				mc.addEventListener(MouseEvent.MOUSE_OUT,handleIconsMouse);
				mc.addEventListener(MouseEvent.CLICK,handleIconsMouse);
			
			}
			
			onResize();
			
		}
		
		private function advanceSlide(dir:int):void
		{
			clearTimeout(slideInterval);
			switch(true)
			{
				case slideIndex + dir > slideMax - 1:
					slideIndex = 0;
				break;

				case slideIndex + dir < 0:
					slideIndex = slideMax - 1;
				break;

				default:
					slideIndex += dir;
				break;
			}
						
			viewSlide();
						
		}
		
		private function onResize(e:Event = null):void
		{
			var ui = Utils.$(this.stage,'ui');
			var mc;
			
			mc = Utils.$(ui,'fullscreen');
			if(mc){
				mc.x = stage.stageWidth - mc.xPos;
			}
			
			mc = Utils.$(ui,'thumbnail');
			if(mc){
				mc.x = stage.stageWidth - mc.xPos;
			}
			
			if(slideMax > 1){
				mc = Utils.$(ui,'nav_prev');
				mc.y = Math.floor(stage.stageHeight/2);
			
				mc = Utils.$(ui,'nav_next');
				mc.y = Math.floor(stage.stageHeight/2);
				mc.x = stage.stageWidth - 15;
			}
			
			scaleSlide();
			
		}
		
		private function onFullScreen(e:FullScreenEvent):void
		{
			var mc = Utils.$(Utils.$(stage,'ui'),'fullscreen');
			if(stage.displayState == "fullScreen"){
				mc.gotoAndStop('fullscreen_off');
			}else{
				mc.gotoAndStop('fullscreen');
			}
		}
		
		private function keyListener(e:KeyboardEvent):void
		{
			switch(e.keyCode)
			{
				case Keyboard.LEFT:
					if(slideMax>1){
						advanceSlide(-1);
					}
				break;
				
				case Keyboard.RIGHT:
					if(slideMax>1){
						advanceSlide(1);
					}
				break;
				
				case 38:
					if(slideMax>1){
						advanceSlide(-1);
					}
				break;
				
				case 40:
					if(slideMax>1){
						advanceSlide(1);
					}
				break;
				
				case Keyboard.SPACE:
					if(MP){
						MP.toggle();
					}
				break;
				/*
				case 70:
					toggleFullScreen();
				break;
				
				case 83:
					toggleSlideShow();				
				break;
				
				case 84:			
					toggleThumbs();
				break;
				*/
			}
		}
		
		
		
		private function toggleFullScreen(e:Event = null):void
		{					
			switch(true){
			
				case stage.displayState == "fullScreen":
					stage.displayState = "normal";
				break;
				
				case stage.displayState == "normal":
					stage.displayState = "fullScreen";
				break;
				
			}	
					
		}
		
		public function toggleThumbs(e:Event = null):void
		{
			flagThumbs = !flagThumbs;
			var ui = Utils.$(stage,'ui');
			var mc = Utils.$(ui,'thumbnail');
			
			var c = Utils.$(this.stage,'thumbs');
				
			
			if(flagThumbs){
				//tell it to activate
				
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyListener);
				
				if(c){
					this.stage.removeChild(c);
				}
				c = Utils.createmc(stage,'thumbs');
				//swap depth with ui
				stage.setChildIndex(c,stage.numChildren - 2);
				thumbClass = new ThumbGrid(c,this,slideA);
				
				//deactivate majority of ui controls
				/*
				c = Utils.$(ui,'toggle');
				c.mouseEnabled = false;
				c.alpha = 0.2;
				*/
				
				c = Utils.$(ui,'nav_prev');
				c.mouseEnabled = false;
				c.alpha = 0.2;
				
				c = Utils.$(ui,'nav_next');
				c.mouseEnabled = false;
				c.alpha = 0.2;
				
				//toggle icon
				mc.gotoAndStop('thumbnail_off');
				
				
				//kill slideshow
				flagPlaying = false;
				clearInterval(progressInterval);
				clearTimeout(slideInterval);			
				updateSlideShowState();
				
				
				//pause video
				if(MP){
					MP.pause();
				}
				
			}else{
				
				thumbClass.onKill();
				thumbClass = null;
				
				if(c){
					this.stage.removeChild(c);
				}
				
				if(slideMax > 1){
					stage.addEventListener(KeyboardEvent.KEY_DOWN, keyListener);
				}
				
				//toggle icon
				mc.gotoAndStop('thumbnail');
				
				//reactivate stuffs
				c = Utils.$(ui,'toggle');
				c.mouseEnabled = true;
				c.alpha = 1.0;
				
				c = Utils.$(ui,'nav_prev');
				c.mouseEnabled = true;
				c.alpha = 1.0;
				
				c = Utils.$(ui,'nav_next');
				c.mouseEnabled = true;
				c.alpha = 1.0;
			}
		}
		
		private function updateSlideShowState():void
		{
			var ui = Utils.$(this.stage,'ui');
			var l = Utils.$(ui,'toggle');
			if(l){
				var mc = Utils.$(l,'circ')
						
				if(flagPlaying){
					l.gotoAndStop('pause');
					TweenLite.to(mc,0.5,{alpha:1.0});
				}else{
					l.gotoAndStop('play');
					TweenLite.to(mc,0.5,{alpha:0.0});
				}
			}
		}
		
		private function toggleSlideShow(e:Event = null):void
		{
			showUI();
			flagPlaying = !flagPlaying;
			if(flagPlaying){
				advanceSlide(1);
			}else{
				clearInterval(progressInterval);
			}
			clearTimeout(slideInterval);			
			updateSlideShowState();
		}
		
		private function initVideo(e:Event)
		{
			var mc = Utils.$(MP._view.ref,'controls');
			mc.alpha = 0.0;
			onResize();
		}
		
		public function viewSlideByIndex(value:Number):void
		{
			slideIndex = value;
			viewSlide();
		}
		
		private function viewSlide():void
		{
			var s = Utils.$(this.stage,'slide');
			if(s){
				this.stage.removeChild(s);
			}
			var slide = Utils.createmc(this.stage,'slide',{alpha:0});
			this.stage.setChildIndex(slide,0);
			var holder = Utils.createmc(slide,'holder');
			
			clearInterval(progressInterval);
			
			var file:String = slideA[slideIndex].file;
			var ext = file.substring(file.lastIndexOf('.')+1,file.length).toLowerCase();
			
			if(MP){
				MP._view.removeEventListener('updateSize', initVideo, false);
				MP.kill();
				MP = null;
			}
									
			if(ext == 'flv' || ext == 'mov' || ext == 'mp4' || ext == 'mp3' || ext == 'm4v'){
				MP = new com.a12.modules.mediaplayback.MediaPlayback(holder,file,{hasView:true});
				MP._view.addEventListener('updateSize', onResize, false, 0, true);
				flagPlaying = false;
				updateSlideShowState();
				revealSlide();
			}
			
			if(ext == 'jpg' || ext == 'gif' || ext == 'png' || ext == 'swf'){
				var movie = new LoadMovie(holder,file);
				movie.loader.contentLoaderInfo.addEventListener(Event.COMPLETE,revealSlide);				
			}
			
			//update the text
			var ui = Utils.$(this.stage,'ui');
			
			if(slideMax > 1){
				var l = Utils.$(ui,'label');
				var tf = Utils.$(l,'displayText');
				tf.text = (slideIndex+1) + '/' + slideMax;
			}
			//kick back the listener
			
						
			
		}
		
		//display preloading of next image?
		private function slideProgressListener(e:ProgressEvent):void
		{
			//renderProgress(p);
		}
		
		private function slideProgressSegment():void
		{
			renderProgress((timestamp - getTimer())/configObj.duration);
		}
		
		private function renderProgress(p:Number):void
		{
			var dO = 3.6;
			var r = 20;
									
			if(progressOffset < 360){
				progressOffset = Math.abs(p * 360);
			}else{
				progressOffset = 0;
			}
			
			var x1 = r*Math.sin(progressOffset*Math.PI/180);
			var x2 = r*Math.sin((progressOffset+dO)*Math.PI/180);
			var y1 = r*Math.cos((progressOffset)*Math.PI/180);
			var y2 = r*Math.cos((progressOffset+dO)*Math.PI/180);
			
			//stage
			var mc = Utils.$(Utils.$(Utils.$(this.stage,'ui'),'toggle'),'circ');			

			mc.graphics.moveTo(0,0);
			mc.graphics.beginFill(0x222222,0.75);//404040
			mc.graphics.lineTo(x1,y1);
			mc.graphics.lineTo(x2,y2);
			mc.graphics.endFill();
			
		}
		
		private function revealSlide(e:Event=null):void
		{
			var slide = Utils.$(this.stage,'slide');
			TweenLite.to(MovieClip(slide),1.0,{alpha:1.0});
			if(flagPlaying){
				
				
				
				if(configObj.slideshow == true){
										
					timestamp = getTimer();

					clearTimeout(slideInterval);
					slideInterval = setTimeout(advanceSlide,configObj.duration,1);

					//
					var mc = Utils.$(Utils.$(Utils.$(this.stage,'ui'),'toggle'),'circ');
					mc.graphics.clear();
					mc.scaleY = -1.0;
					
					
					progressOffset = 0;
					
					if(flagPlaying){
						progressInterval = setInterval(slideProgressSegment,configObj.duration/100);
						slideProgressSegment();
					}
					
				}
			}
			
			slide._width = slide.width;
			slide._height = slide.height;
			
			//set the height and width properties yea?
			
			scaleSlide();
		}	
		
		private function scaleSlide():void
		{
			
			var slide = Utils.$(this.stage,'slide');
			if(slide){			
				var imgX = slide._width;
				var imgY = slide._height;
			
				if(MP != null)
				{
					var tA = MP.getDimensions();
					imgX = tA.width;
					imgY = tA.height;
				}

				var m = 100;
				if(MP != null && configObj.scalestage){
					m = undefined;
				}
				var scale = Utils.getScale(imgX,imgY,stage.stageWidth-(Layout.marginX*2),stage.stageHeight-(Layout.marginY*2),'scale',m).x;
												
				scale = scale/100;
				//if we're a image
				if(MP == null){	
					slide.scaleX = scale;
					slide.scaleY = scale;
					slide.x = stage.stageWidth/2 - slide.width/2;
					slide.y = (stage.stageHeight)/2 - slide.height/2;
				}
				
				//if we're a video
				if(MP != null){
					
					MP.setScale(scale*100);
					tA = MP.getDimensions();
					
					slide.x = 0;
					slide.y = 0;
					
					var mc = Utils.$(MP._view.ref,'myvideo');
					if(mc != null){
						mc.width = Math.ceil(tA.width*scale);
						mc.height = Math.ceil(tA.height*scale);
					
						mc.x = stage.stageWidth/2 - mc.width/2;
						mc.y = (stage.stageHeight)/2 - mc.height/2;
					}
					
					//do overlay icon
					mc = Utils.$(MP._view.ref,'video_overlay_play');
					if(mc != null){
						mc.x = stage.stageWidth/2;
						mc.y = stage.stageHeight/2;
					}
					
					mc = Utils.$(MP._view.ref,'cover');
					if(mc != null){
						mc.x = stage.stageWidth/2 - tA.width/2;
						mc.y = (stage.stageHeight)/2 - tA.height/2;					
					}
					MP.setWidth(stage.stageWidth);
					if(MP._view._controls != null){
						MP._view._controls.y = stage.stageHeight - 20;
					}
					
					
				}
			
				//scaleStage();
			
			}
			
			
		
		}
		
		private function scaleStage():void
		{
			//Optionally use hardware acceleration
			/*
			if(MP){
				var mc = Utils.$(MP._view.ref,'myvideo');
				var screenRectangle:Rectangle = new Rectangle();
				screenRectangle.x = 0;
				screenRectangle.y = 0;
				screenRectangle.width=mc.width;
				screenRectangle.height=mc.height;
				stage.fullScreenSourceRect = screenRectangle;			
			}else{
				stage.fullScreenSourceRect = null;
			}
			*/
		}	
		
	}
	
}