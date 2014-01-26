﻿/** * <p>Original Author: Daniel Freeman</p> * * <p>Permission is hereby granted, free of charge, to any person obtaining a copy * of this software and associated documentation files (the "Software"), to deal * in the Software without restriction, including without limitation the rights * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell * copies of the Software, and to permit persons to whom the Software is * furnished to do so, subject to the following conditions:</p> * * <p>The above copyright notice and this permission notice shall be included in * all copies or substantial portions of the Software.</p> * * <p>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN * THE SOFTWARE.</p> * * <p>Licensed under The MIT License</p> * <p>Redistributions of files must retain the above copyright notice.</p> */package com.danielfreeman.madcomponents {		import flash.display.Bitmap;	import flash.display.BitmapData;	import flash.display.DisplayObject;	import flash.display.Sprite;	import flash.display.Loader;	import flash.geom.Point;	import flash.geom.Rectangle;	import flash.utils.getDefinitionByName;
/** *  Image placeholder * <pre> * &lt;image *    id = "IDENTIFIER" *    alignH = "left|right|centre|fill" *    alignV = "top|bottom|centre|fill" *    visible = "true|false" *    width = "NUMBER" *    height = "NUMBER" *    clickable = "true|false" *    scale = "true|false" * /&gt; * </pre> */	public class UIImage extends MadSprite {		protected var _width:Number = -1.0;		protected var _height:Number = -1.0;		protected var _attributesWidth:Number;		protected var _attributesHeight:Number;		protected var _image:DisplayObject = null;		protected var _scale:Boolean = true;		protected var _stretch:Boolean;		protected var _alpha:Number = 0.0;		protected var _colour:uint = 0xEEEEEE;		protected var _border:String = "";			public function UIImage(screen:Sprite, xml:XML, attributes:Attributes) {			_attributesWidth = attributes.widthH;			_attributesHeight = attributes.heightV;			_border = xml.@border;			_stretch = xml.@stretch == "true";			_alpha = (_border == "" || _border == "false") ? 0 : 1.0;			if (xml.@background.length() == 1) {				_colour = UI.toColourValue(xml.@background);				_alpha = 1.0;			}			screen.addChild(this);			x=attributes.x;			y=attributes.y;			_scale = xml.@scale!="false";			mouseEnabled=mouseChildren=false;			text = xml.toString();			clickable = false;		}		/** *  Set image by assigning a Class, qualified class name, or bitmap, or displayobject */		public function set text(source:*):void {			if (source is Class || source==null) {				imageClass = source;			}			else if (source is BitmapData || source is DisplayObject) {				image = source;			}			else if (source is String) {				if (source=="") {					imageClass = null;				}				else if (!isNaN(Number(source.charAt(0)))) {					graphics.clear();					graphics.beginFill(_colour, _alpha);					source.replace(/ /gi,"");					var dimensions:Array = source.split(",");					var border:Number = (_border == "" || _border == "false") ? 0 : 2.0;					var curve:Number = (_border == "rounded") ? 6.0 : 0;					if (dimensions.length>1) {						graphics.drawRoundRect(0, 0, (_width=parseFloat(dimensions[0])) + 2 * border, (_height=parseFloat(dimensions[1])) + 2 * border, curve);					}					else {						graphics.drawRoundRect(0, 0, (_width=parseFloat(dimensions[0])) + 2 * border, (_height=parseFloat(dimensions[0])) + 2 * border, curve);					}					if (dimensions.length>2) {						value = dimensions[2];       					}				}				else {					value = source;				}			}		}		/** *  Set image qualified class name */		public function set value(value:String):void {			imageClassName = value;		}		/** *  Set image bitmap or display object */		public function set image(value:*):void {			if (parent) {				if (_image) {					removeChild(_image);				}				_image = (value is BitmapData) ? new Bitmap(value) : value;				_image.x = _image.y = (_border == "" || _border == "false") ? 0 : 2.0;				addChild(_image);				scaleImage();			}		}		/** *  Scale the image */		protected function scaleImage():void {			if (!_image || !_scale) {				return;			}			if (_image is Bitmap) {				Bitmap(_image).smoothing = true;			}			_image.scaleX=_image.scaleY = 1.0;			if (_stretch) {				_image.scaleX = (_width > 0) ? Math.min(_width / _image.width, _attributesWidth/_image.width) : _attributesWidth/_image.width;				_image.scaleY = (_height > 0) ? Math.min(_height / _image.height, _attributesWidth/_image.height) : _attributesHeight/_image.height;							}			else {				if (_width>0) {					_image.scaleX=_image.scaleY = Math.min(_width / _image.width, _height/_image.height, _attributesWidth/_image.width, 1.0);				}				else {					_image.scaleX=_image.scaleY = Math.min(_attributesWidth/_image.width, 1.0);				}			}		}				public function set attributesWidth(value:Number):void {			_attributesWidth = value;			scaleImage();		}						public function set attributesHeight(value:Number):void {			_attributesHeight = value;			scaleImage();		}		/** *  Stage rectangle */				public function stageRect(aspectRatio:Number = -1):Rectangle {			var leftTop:Point = localToGlobal(new Point(0,0));			var rightBottom:Point = _width>0 ? localToGlobal(new Point(_width,_height)) : localToGlobal(new Point(_attributesWidth,_attributesHeight));			var result:Rectangle = new Rectangle(leftTop.x, leftTop.y, rightBottom.x - leftTop.x, rightBottom.y - leftTop.y);			var aspectFrame:Number = result.width/result.height;			if (aspectRatio>0) {				if (aspectRatio < aspectFrame) {					result.x = result.x + (1 - aspectRatio / aspectFrame) * result.width / 2;					result.width = (aspectRatio / aspectFrame) * result.width;				}				else {					result.y = result.y + (1 - aspectFrame / aspectRatio) * result.height / 2;					result.height = (aspectFrame / aspectRatio) * result.height;				}			}			return result;		}		/** *  Set image class name */		public function set imageClassName(value:String):void {			imageClass = getDefinitionByName(value) as Class;		}		/** *  Set image class */		public function set imageClass(value:Class):void {			if (_image) {				removeChild(_image);			}			_image = null;			if (value) {				image = new value();			}		}	}}