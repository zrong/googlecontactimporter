package google
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.sampler.getSampleCount;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import org.zengrong.events.InfoEvent;

	public class GoogleContact extends EventDispatcher
	{
		public static const TYPE_AUTH:String = 'authType';
		public static const TYPE_CONTENT:String = 'contentType';
		public static const TYPE_GROUP:String = 'groupType';
		
		public static const EVENT_ERROR:String = 'errorEvent';
		public static const EVENT_AUTH_SUCCESS:String = 'authEvent';
		public static const EVENT_CONTENT_CREATED:String = 'contentCreatedEvent';
		public static const EVENT_CONTENT_GET:String = 'contentGetEvent';
		public static const EVENT_GROUP_CREATED:String = 'groupCreatedEvent';
		public static const EVENT_GROUP_GET:String = 'groupGetEvent';
		
		private static const LOGIN_URL:String = 'https://www.google.com/accounts/ClientLogin';
		private static const CONTACTS_URL:String = 'http://www.google.com/m8/feeds/contacts/default/full';
		private static const CONTACTS_BATCH_URL:String = 'http://www.google.com/m8/feeds/contacts/default/full/batch';
		private static const GROUPS_URL:String = 'http://www.google.com/m8/feeds/groups/default/full';
		private static const GROUPS_BATCH_URL:String = 'http://www.google.com/m8/feeds/groups/default/full/batch';
		
		public static const NO_MATCH:String = '*未选择*';
		public static var CSV_GROUP_FIELD_NAME:String = '群组';		//在CSV文件中的群组字段的名称
		public static var CSV_LINE_BREAK:String = '\n';				//CSV文件的分隔符
		public static var CSV_SEPARATOR:String = ',';				//CSV文件的分隔符
		
		public const NS_ATOM:Namespace = new Namespace('http://www.w3.org/2005/Atom');
		public const NS_GC:Namespace = new Namespace('gContact', 'http://schemas.google.com/contact/2008');
		public const NS_GD:Namespace = new Namespace('gd', 'http://schemas.google.com/g/2005');
		public const NS_BA:Namespace = new Namespace('batch', 'http://schemas.google.com/gdata/batch');
		
		public const ENTRY_DETAIL:Object = {	'全名':	new EntryItemVO('fullName', 'gd', 'name'),
												'名':	new EntryItemVO('givenName', 'gd', 'name'),
												'姓':	new EntryItemVO('familyName', 'gd', 'name'),
												'单位':	new EntryItemVO('orgName', 'gd', 'organization'),
												'部门':	new EntryItemVO('orgDepartment', 'gd', 'organization'),
												'职务':	new EntryItemVO('orgTitle', 'gd', 'organization'),
												'工作电子邮件':	new EntryItemVO('email', 'gd', null, 'address', 'http://schemas.google.com/g/2005#work'),
												'家庭电子邮件':	new EntryItemVO('email', 'gd', null, 'address', 'http://schemas.google.com/g/2005#home'),
												'移动电话':	new EntryItemVO('phoneNumber', 'gd', null, null, 'http://schemas.google.com/g/2005#mobile'),
												'单位电话':	new EntryItemVO('phoneNumber', 'gd', null, null, 'http://schemas.google.com/g/2005#work'),
												'住宅电话':	new EntryItemVO('phoneNumber', 'gd', null, null, 'http://schemas.google.com/g/2005#home'),
												'单位传真':	new EntryItemVO('phoneNumber', 'gd', null, null, 'http://schemas.google.com/g/2005#work_fax'),
												'QQ':	new EntryItemVO('im', 'gd', null, 'address', 'http://schemas.google.com/g/2005#QQ', 'protocol'),
												'MSN':	new EntryItemVO('im', 'gd', null, 'address', 'http://schemas.google.com/g/2005#MSN', 'protocol'),
												'SKYPE':	new EntryItemVO('im', 'gd', null, 'address', 'http://schemas.google.com/g/2005#SKYPE', 'protocol'),
												'GTALK':	new EntryItemVO('im', 'gd', null, 'address', 'http://schemas.google.com/g/2005#GOOGLE_TALK', 'protocol'),
												'国家':	new EntryItemVO('country', 'gd', 'structuredPostalAddress'),
												'省、地区':	new EntryItemVO('region', 'gd', 'structuredPostalAddress'),
												'市':	new EntryItemVO('city', 'gd', 'structuredPostalAddress'),
												'区、县':	new EntryItemVO('subregion', 'gd', 'structuredPostalAddress'),
												'街道':	new EntryItemVO('street', 'gd', 'structuredPostalAddress'),
												'邮政编码':	new EntryItemVO('postcode', 'gd', 'structuredPostalAddress'),
												'地址':	new EntryItemVO('formattedAddress', 'gd', 'structuredPostalAddress'),
												'生日':	new EntryItemVO('birthday ', 'gContact', null, 'when'),
												'主页':	new EntryItemVO('website', 'gContact', null, 'href', 'home-page', 'rel'),
												'博客':	new EntryItemVO('website', 'gContact', null,  'href', 'blog', 'rel'),
												'工作网站':	new EntryItemVO('website', 'gContact', null,  'href', 'work', 'rel'),
												'群组':	new EntryItemVO('groupMembershipInfo', 'gContact', null, 'href'),
												'备注':	new EntryItemVO('content', '')	};
		
		private var auth:URLLoader;		//处理登录相关的提交和返回
		private var contact:URLLoader;	//处理通讯录条目相关的提交和返回
		private var group:URLLoader;	//处理组相关的提交和返回
		private var token:String;		//保存google登录成功返回的令牌
		private var status:int;			//保存每次提交后返回的HTTP代码
		
		private var sampleFile:File;	//样本文件指向
		private var groupSample:XML;	//保存群组样本文件内容
		private var contactSample:XML;	//保存联系人样本文件内容
		private var entrySample:XML;	//保存一个联系人的样本内容，包含所有可用的联系人项目
		private var entryCleanSample:XML;		//一个“干净的”联系人，除了batch:id、batch:opertion、category之外没有其他元素
		
		public function GoogleContact()
		{
			auth = new URLLoader();
			contact = new URLLoader();
			group = new URLLoader();
			
			getSample();
			
			//不可使用HttpStatus事件，如果使用此事件，当返回的http state不为200的时候，载入就不会继续进行，会出现ioerror。
			//使用HTTP_RESPONSE_STATUS事件就可以避免这个问题。
			auth.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, authHttpResponseStatusHandler);
			auth.addEventListener(Event.COMPLETE, authCmpleteHandler);
			
			
			contact.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, contactHttpResponseStatusHandler);
			contact.addEventListener(Event.COMPLETE, contactCmpleteHandler); 
			
			group.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, groupHttpResponseStatusHandler);
			group.addEventListener(Event.COMPLETE, groupCompleteHandler); 
		}
		
		private function getSample():void
		{
			var __stream:FileStream = new FileStream();
			
			sampleFile = File.applicationDirectory.resolvePath('assets/groupBatch.xml');
			__stream.open(sampleFile, FileMode.READ);
			groupSample = new XML(__stream.readUTFBytes(__stream.bytesAvailable));
			__stream.close();
			
			sampleFile = File.applicationDirectory.resolvePath('assets/contactBatch.xml');
			__stream.open(sampleFile, FileMode.READ);
			contactSample = new XML(__stream.readUTFBytes(__stream.bytesAvailable));
			__stream.close();
			
			entrySample = contactSample.NS_ATOM::entry[0];
			entryCleanSample = entrySample.copy();			
			//删除“干净”联系人中除了batch需要的元素之外的所有元素
			for each(var item:XML in entryCleanSample.children())
			{
				var __ns:Namespace = item.namespace();
				if(__ns == NS_GC  ||  __ns == NS_GD || item.localName() == 'content')
				{
					delete entryCleanSample.children()[item.childIndex()];
				}
			}
		}
		
		//根据提供的title数组返回一个批量插入群组的XML
		public function getGroupInsertBatch($title:Array):XML
		{
			var __batch:XML = groupSample.copy();
			var __group:XML = __batch.NS_ATOM::entry[0];
			delete __batch.NS_ATOM::entry[0];
			for(var i:int=0; i<$title.length; i++)
			{
				var __insert:XML = __group.copy();
				__insert.NS_BA::id[0] = i;
				__insert.NS_ATOM::title = $title[i];
				__batch.appendChild(__insert);
			}
			return __batch;
		}
		
		//根据提供的匹配情况数组返回一个批量插入联系人的XML
		public function getContactInsertBatch($match:Array, $csvEntry:Array, $import:Object):XML
		{
			var __batch:XML = contactSample.copy();		//用于插入的总XML
			delete __batch.NS_ATOM::entry[0];			//将唯一的一个联系人删除，便于后面添加
			
			//开始建立需要导入的联系人
			for(var i:int=0; i<$csvEntry.length; i++)
			{
				var __csvEntryObj:Object = $csvEntry[i];
				var __insert:XML = buildEntryXML(i, $match, __csvEntryObj);
				//如果选择了一个所有联系人都属于的群组，就将这个群组添加到所有的联系人的条目中
				if($import)
				{
					__insert.appendChild(buildEntryItemXML(ENTRY_DETAIL[GoogleContact.CSV_GROUP_FIELD_NAME], $import.data));	
				}
				__batch.appendChild(__insert);
			}
			return __batch;
		}
		
		//获取ENTRY_DETAIL的属性名称列表
		public function getEntryNames():Array
		{
			var __arr:Array = [];
			for(var i:String in ENTRY_DETAIL)
			{
				__arr.push(i);
			}
			__arr.unshift(GoogleContact.NO_MATCH);
			return __arr;			
		}
		
		//根据前缀返回对应的命名空间
		public function getNameSpace($prefix:String=''):Namespace
		{
			if($prefix == '')
			{
				return NS_ATOM;
			}
			else if($prefix == NS_BA.prefix)
			{
				return NS_BA;
			}
			else if($prefix == NS_GC.prefix)
			{
				return NS_GC;
			}
			else if($prefix == NS_GD.prefix)
			{
				return NS_GD;
			}
			return null;			
		}
		
		public function login($user:String, $pwd:String):void
		{
			auth.load(buildLoginRequest($user,$pwd));
		}
		
		public function insertGroup($atom:XML, $isBatch:Boolean=false):void
		{
			if($isBatch)
			{
				group.load(buildInsertRequest(GROUPS_BATCH_URL, $atom));
			}
			else
			{
				group.load(buildInsertRequest(GROUPS_URL, $atom));
			}
		}
		
		public function inertContact($atom:XML):void
		{
			contact.load(buildInsertRequest(CONTACTS_BATCH_URL, $atom));
		}
		
		public function getGroups():void
		{
			group.load(buildGetRequest(GROUPS_URL));	
		}
		
		private function buildLoginRequest($user:String, $pwd:String):URLRequest
		{
			var __request:URLRequest = new URLRequest(LOGIN_URL);
			__request.method = URLRequestMethod.POST;
			var __var:URLVariables = new URLVariables();
			__var.accountType = 'GOOGLE';
			__var.Email = $user;
			__var.Passwd = $pwd;
			__var.service = 'cp';
			__var.source = 'zrong-contactImport-1.0';
			__request.data = __var;
			return __request;
		}
		
		private function buildInsertRequest($url:String, $atom:XML):URLRequest
		{
			var __request:URLRequest = new URLRequest($url);                           
			__request.requestHeaders.push(new URLRequestHeader('Authorization', 'GoogleLogin auth='+token));
			__request.requestHeaders.push(new URLRequestHeader('GData-Version', '3.0'));
			__request.requestHeaders.push(new URLRequestHeader('Content-Type', 'application/atom+xml'));
			__request.method = URLRequestMethod.POST;
			var __var:URLVariables = new URLVariables();
			__request.data = $atom;
			return __request;  
		}
		
		private function buildGetRequest($url:String):URLRequest
		{
			var __request:URLRequest = new URLRequest($url);                           
			__request.requestHeaders.push(new URLRequestHeader('Authorization', 'GoogleLogin auth='+token));
			__request.requestHeaders.push(new URLRequestHeader('GData-Version', '3.0'));
			__request.method = URLRequestMethod.GET;
			var __var:URLVariables = new URLVariables();
			//定义一个足够大的值以便于传输所有条目
			__var['max-results'] = 10000;
			__request.data = __var;
			return __request;
		}
		
		//建立联系人中的一个项目
		private function buildEntryItemXML($vo:EntryItemVO, $value:String):XML
		{
			var __ns:Namespace = getNameSpace($vo.prefix);
			var __item:XML = null;
			if($vo.scheme)
			{
				//若提供了scheme值，就同时根据name和scheme进行查询，取出对应的元素
				__item = entrySample..__ns::[$vo.name].(@[$vo.schemeName]==$vo.scheme)[0].copy();
			}
			else
			{
				//否则就仅使用name查询
				__item = entrySample..__ns::[$vo.name][0].copy();
			}
			//根据是否提供属性值来确定是设置属性值还是使用文本元素
			if($vo.attributeName)
			{
				__item.@[$vo.attributeName] = $value;
			}
			else
			{
				__item.appendChild($value);
			}
			return __item;
		}
		
		//填充联系人的大部分项目
		private function buildEntryXML($id:int, $match:Array, $csvEntryObj:Object):XML
		{
			var __insert:XML = entryCleanSample.copy();
			__insert.NS_BA::id[0] = $id;
			for each(var match:Array in $match)
			{
				//获取被映射到的google联系人项目的属性VO
				var __vo:EntryItemVO = ENTRY_DETAIL[match[1]];
				//获取CSV中对应的项目的值
				var __value:String = $csvEntryObj[match[0]];
				//如果__value值为空，就不加入这个项目
				if(__value == null) continue;
				if(__vo == null)
				{
					dispatchEvent(new InfoEvent(EVENT_ERROR, new EventVO(TYPE_CONTENT, '无法获取*'+match[0]+'*的匹配项*'+match[1]+'*的值')));
					continue;
				}
				//建立一个联系人项目
				var __entryItemXML:XML = buildEntryItemXML(__vo, __value);
				//如果该项目是子项目，就在该联系人的XML中检测父项目
				if(__vo.parentName)
				{
					var __ns:Namespace = getNameSpace(__vo.prefix);
					//若父项目XML存在，就在附项目中添加子项目的XML内容
					if(__insert.__ns::[__vo.parentName].length() >0)
					{
						__insert.__ns::[__vo.parentName][0].appendChild(__entryItemXML);
					}
					else
					{
						//从范例中取出父项目
						var __parent:XML = entrySample.__ns::[__vo.parentName][0].copy();
						//清空范例中取出的父项目的所有子项目
						while(__parent.children().length()>0)
						{
							delete __parent.children()[0];
						}
						//在父项目中添加子项目
						__parent.appendChild(__entryItemXML);
						//将父项目添加到联系人
						__insert.appendChild(__parent);
					}
				}
				else
				{
					//不是子项目直接添加到联系人
					__insert.appendChild(__entryItemXML);
				}									
			}
			return __insert;
		}
		
		//========================提交事件
		
		private function authHttpResponseStatusHandler(evt:HTTPStatusEvent):void
		{
			status = evt.status;
//			trace('authHttpResponseStatusHandler', evt);
//			trace('headers:', ObjectUtil.toString(evt.responseHeaders));
//			trace('=================================================='); 
		}
		
		private function authCmpleteHandler(evt:Event):void
		{
			var __arr:Array = String(auth.data).split('\n');
			//默认事件是直接发送data的值
			var __event:EventVO = new EventVO(TYPE_AUTH, auth.data);
			if(status == 200)
			{
				var __thirdLine:Array = String(__arr[2]).split('=');
				if(__thirdLine[0] == 'Auth')
				{
					token = __thirdLine[1];
					__event.info = token;
					dispatchEvent(new InfoEvent(EVENT_AUTH_SUCCESS, __event));
				}
				else
				{
					dispatchEvent(new InfoEvent(EVENT_ERROR, __event));
				}
						
			}
			else
			{				
				var __firstLine:Array = String(__arr[0]).split('=');
				if(__firstLine[0] == 'Error')
				{
					__event.info = MSG.getError(__firstLine[1]);
					dispatchEvent(new InfoEvent(EVENT_ERROR, __event));
				}
				else
				{
					dispatchEvent(new InfoEvent(EVENT_ERROR, __event));
				}
			}
		}
		
		private function groupHttpResponseStatusHandler(evt:HTTPStatusEvent):void
		{
			status = evt.status;
//			trace('groupHttpResponseStatusHandler', evt);
//			trace('headers:', ObjectUtil.toString(evt.responseHeaders));
//			trace('data:', contact.data);
//			trace('=================================================='); 
		}
		
		private function groupCompleteHandler(evt:Event):void
		{
			var __event:EventVO = new EventVO(TYPE_GROUP, MSG.getHTTPStatus(status)+'\r'+group.data);
			if(status == 200)
			{
				__event.info = new XML(group.data);
				//如果结果中有<batch:status>这个属性，说明批量插入操作，就要发送创建事件，而不是获取事件
				if(XML(__event.info)..NS_BA::status.length() > 0)
				{
					dispatchEvent(new InfoEvent(EVENT_GROUP_CREATED, __event));
				}
				else
				{
					dispatchEvent(new InfoEvent(EVENT_GROUP_GET, __event));
				}				
			}
			else if(status == 201)
			{
				__event.info = new XML(group.data);
				dispatchEvent(new InfoEvent(EVENT_GROUP_CREATED, __event));
			}
			else
			{
				dispatchEvent(new InfoEvent(EVENT_ERROR, __event));
			}
//			trace('groupCmpleteHandler', evt);
//			trace('==================================================');
		}
		
		private function contactHttpResponseStatusHandler(evt:HTTPStatusEvent):void
		{
			status = evt.status;
//			trace('contactHttpResponseStatusHandler', evt);
//			trace('headers:', ObjectUtil.toString(evt.responseHeaders));
//			trace('data:', contact.data);
//			trace('=================================================='); 
		}
		
		private function contactCmpleteHandler(evt:Event):void
		{
			var __event:EventVO = new EventVO(TYPE_CONTENT, MSG.getHTTPStatus(status)+'\r'+contact.data);
			if(status == 200 || status == 201)
			{
				__event.info = new XML(contact.data);
				dispatchEvent(new InfoEvent(EVENT_CONTENT_CREATED, __event));
			}
			else
			{
				dispatchEvent(new InfoEvent(EVENT_ERROR, __event));
			}
//			trace('contactCmpleteHandler', evt);
//			trace('==================================================');
		}
	}
}