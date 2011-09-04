/**
 * <p>Original Author: Daniel Freeman</p>
 *
 * <p>Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:</p>
 *
 * <p>The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.</p>
 *
 * <p>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.</p>
 *
 * <p>Licensed under The MIT License</p>
 * <p>Redistributions of files must retain the above copyright notice.</p>
 */

package com.danielfreeman.madcomponents {
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.NetConnection;
	import flash.net.Responder;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
/**
 * Enables connection to a webserver using XML, JSON, or AMF
 * <pre>
 * &lt;model
 *    url = "URL"
 *    service = "SERVICE"
 *    path = "PATH"
 *    action = "loadXML|loadJSON|loadAMF"
 * /&gt;
 * 
 * &lt;sendModel
 *    url = "URL"
 *    sendBy = "get|post|xml"
 *    action = "send|sendAndLoadXML|sendAndLoadJSON"
 * /&gt;
 * </pre>
 */	
	public class Model extends URLLoader {
		
		public static const LOADED:String = "dataLoaded";
		public static const ERROR:String = "dataError";
		
		protected var _schema:XML = null;
		protected var _sendSchema:XML = null;
		protected var _parent:Sprite;
		protected var _url:String;
		protected var _sendUrl:String;
		protected var _dataString:URLVariables;
		protected var _sendBy:String = "xml";
		protected var _service:String;
		protected var _path:String = "";
		protected var _amfData:Object = null;
		protected var _action:String="";
		
		
		public function Model(parent:Sprite,xml:XML,sendXml:XML = null) {
			_parent = parent;
			if (xml) {
				_schema  = xml.children()[0];
				if (xml.@url.length()>0)
					_url=xml.@url[0];
				if (xml.@service.length()>0)
					_service=xml.@service[0];
				if (xml.@path.length()>0)
					_path=xml.@path[0];
				if (xml.@action.length()>0) {
					_action = xml.@action;
					refresh();
				}
			}
			if (sendXml) {
				_sendSchema = sendXml.children()[0];
				if (sendXml.@url.length()>0)
					_sendUrl=sendXml.@url[0];
				if (sendXml.@sendBy.length()>0)
					_sendBy=sendXml.@sendBy[0];
				if (sendXml.@action.length()>0) {
					if (sendXml.@action[0]=="send")
						sendURL();
					else
						sendURL("",sendXml.@action[0]);
				}
			}
		}
		
/**
 * Repeat the previous server query
 */	
		public function refresh():void {
			if (_action=="load" || _action=="loadXML")
				loadXML();
			else if (_action=="loadAMF")
				loadAMF();
			else if (_action=="loadJSON")
				loadJSON();
		}
		
/**
 * A url request where the returned data is XML
 */	
		public function loadXML(url:String = ""):void {
			if (url == "")
				url = _url;
			else
				_url = url;
			addEventListener(Event.COMPLETE, isLoaded);
			var request:URLRequest = new URLRequest(url);
			try {
				load(request);
			} catch (error:Error) {
				errorFn();
			}
			_action="loadXML";
		}
		
/**
 * A url request where the returned data is JSON
 */	
		public function loadJSON(url:String = ""):void {
			if (url == "")
				url = _url;
			else
				_url = url;
			addEventListener(Event.COMPLETE, jsonIsLoaded);
			var request:URLRequest = new URLRequest(url);
			try {
				load(request);
			} catch (error:Error) {
				errorFn();
			}
			_action="loadJSON";
		}

/**
 * Connect to an AMF service
 */	
		public function loadAMF(url:String = "", service:String = "", parameters:Array = null):void {
			var netConnection:NetConnection = new NetConnection();
			netConnection.addEventListener(NetStatusEvent.NET_STATUS, errorFn);
			netConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorFn);
			
			netConnection.connect(url!="" ? url : _url);
			if (parameters && parameters.length>0)
				netConnection.call(service!="" ? service : _service, new Responder(loadAMFList, errorFn), parameters[0], parameters[1], parameters[2]);
			else
				netConnection.call(service!="" ? service : _service, new Responder(loadAMFList, errorFn));
			_action="loadAMF";
		}

/**
 * A url request where the returned data is JSON
 */	
		protected function loadAMFList(value:*):void {
			dataAMF = value;
			dispatchEvent(new Event(LOADED));
		}

/**
 * Set the data within a list or form to an AMF object
 */	
		public function set dataAMF(value:*):void {
			_amfData = value;
			if (_path!="" && value)
				value = value[_path];
			if (_parent is UIList) {
				if (_schema == null) {
					UIList(_parent).data = value;
				}
				else {
					var arrayOfObjects:Array = [];
					for each (var record:Object in value) {
						arrayOfObjects.push(parseAMFlist(record, _schema.parent(), new Object()));
					}
					UIList(_parent).data = arrayOfObjects;
				}
			}
			else {
				UIForm(_parent).data = (_schema == null) ? value : parseAMFlist(value, _schema.parent(), new Object());
			}
		}

/**
 * Converts an AMF object to an Object
 */	
		protected function parseAMFlist(record:Object, schema:XML, result:Object, path:String = ""):Object {
			var schemaChildren:XMLList = schema.children();
			for each (var child:XML in schemaChildren) {
				var field:String = child.localName().toString();
				var pathChild:String = path+"."+field;
				if (child.hasSimpleContent()) {
					if (child.toString() != "")
						field = child.toString();
					var head:String = result[field];
					result[field] = (head ? head+" " : "") + String(record[pathChild.substr(1)]);
				}
				else {
					result = parseAMFlist(record, child, result, pathChild);
				}
			}
			return result;
		}
		
/**
 * Send data to the server
 */	
		public function sendURL(url:String = "",action:String = ""):void {
			if (url == "")
				url = _sendUrl;
			else
				_sendUrl = url;
			if (action == "sendAndLoadXML")
				addEventListener(Event.COMPLETE, isLoaded);
			else if (action == "sendAndLoadJSON")
				addEventListener(Event.COMPLETE, jsonIsLoaded);
			var request:URLRequest = new URLRequest(url);
			request.data = sendData();
			request.method = (_sendBy=="get") ? URLRequestMethod.GET : URLRequestMethod.POST;
			if (_sendBy=="xml")
				request.contentType = "text/xml";
			try {
				load(request);
			} catch (error:Error) {
				errorFn();
			}
		}

/**
 * Error handler
 */	
		protected function errorFn(event:* = null):void {
			if (!event && event is Event) 
				dispatchEvent(event);
			else
				dispatchEvent(new Event(ERROR));
		}
		
/**
 * XML data loaded handler
 */	
		protected function isLoaded(event:Event):void {
			dataXML = XML(data);
			dispatchEvent(new Event(LOADED));
		}
		
/**
 * JSON data loaded handler
 */	
		protected function jsonIsLoaded(event:Event):void {
			dataAMF = JSON.parse(data);
			dispatchEvent(new Event(LOADED));
		}
		
/**
 * XML data loaded
 */	
		public function set dataXML(xml:XML):void {
			var schema:XML = _schema;
				xml=xmlPath(xml,_path);
				if (_path!="" && _schema!=null)
					schema = _schema.parent();

			if (_parent is UIList) {
				var arrayCollectionList:Array = listData(xml,schema);
				UIList(_parent).data = arrayCollectionList;
			}
			else if (_parent is UIForm) {
				var valuesObject:Object = listValues(xml,schema);
				UIForm(_parent).data = valuesObject;
			}
		}
		
/**
 * AMF object property
 */	
		public function get dataAMF():Object {
			return _amfData;
		}
		
/**
 * Convert XML to an array of objects
 */	
		protected function listData(xml:XML, schema:XML):Array {
			var result:Array = null;
			var items:XMLList = xml.children();
			if (schema == null) {
				result = [];
				for each (var item0:XML in items) {
					result.push(xmlToObject(item0));
				}
			}
			else {
				var schemaName:String = schema.localName().toString();
				var schemaChildren:XMLList = schema.children();
				if (items.length()==1 && schemaChildren.length()==1 && schemaChildren[0].hasComplexContent()) {
					result = listData(items[0].children(), schemaChildren[0]);
					if (result)
						return result;
				}
				if (items.length()>1) {
					result = [];
					schemaChildren = schemaChildren.children();
					for each (var item:XML in items) {
						result.push(listObject(item, schemaChildren));
					}
				}
			}
			return result;
		}
		
/**
 * Convert XML to an array of objects
 */	
		protected function listValues(item:XML, childSchema:XML):Object {
			if (childSchema == null) {
				return xmlToObject(item);
			}
			else if (item.hasSimpleContent()) {
				var result:Object = new Object();
				result[childSchema.localName().toString()] = item.toString();
				return result;
			}
			else {
				return listObject(item, childSchema.children());
			}
		}
		
/**
 * Convert XML branch to an array of objects
 */	
		protected function listObject(item:XML, childSchema:XMLList, result:Object = null):Object {
			if (!result) {
				result = new Object();
			}
			
			for each (var child:XML in childSchema) if (child.nodeKind() != "text") { //?
				var tagName:String = child.localName().toString();
				if (child.hasSimpleContent()) {
					var field:String = child.toString();
					if (field == "")
						field = tagName;
					result[field] = item.child(tagName)[0].toString();
				}
				else {
					result = listObject(item.child(tagName)[0], child.children(), result);
				}
			}
			return result;
		}
		
/**
 * Convert XML to an array of objects, where no model is specified.  Tag names correspond to ids.
 */	
		protected function xmlToObject(xml:XML):Object {
			var result:Object = {};
			var children:XMLList = xml.children();
			for each (var child:XML in children) if (child.nodeKind() != "text") {
				result[child.localName().toString()] = child.hasSimpleContent() ? child.toString() : xmlToObject(child);
			}
			return result;
		}
		
/**
 * Traverse XML tree according to path
 */	
		protected function xmlPath(xml:XML, path:String):XML {
			var pathArray:Array = path.split(".");
			for (var i:int = 1; i < pathArray.length; i++) {
				xml = xml.child(pathArray[i])[0];
			}
			return xml;
		}
		
/**
 * Prepare the data to send to the server
 */	
		public function sendData(sendBy:String = ""):Object {
			if (sendBy!="")
				_sendBy = sendBy;
			var result:XML = _schema.copy();
			_dataString=new URLVariables();
			substitute(result);
			return (_sendBy=="xml") ? result : _dataString;
		}
		
		
		protected function substitute(data:XML):void {
			for each(var item:XML in data.children()) {
				if (item.hasSimpleContent()) {
					var obj:*=UIForm(_parent).findViewById(item.toString());
					if (obj) {
						if (_sendBy=="xml")
							item.replace(0,obj.text);
						else
							_dataString[item.toString()]=obj.text;
					}
				}
				else {
					substitute(item);
				}
			}
		}
	}
}