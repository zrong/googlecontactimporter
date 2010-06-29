package google
{
	public class EntryItemVO
	{
		public var name:String;			//条目的名称
		public var prefix:String;		//条目的命名空间名称
		public var attributeName:String;	//条目使用属性保存值，那么这个变量保存属性名称
		public var parentName:String;	//上级条目的名称
		public var scheme:String;		//条目的模式，邮箱、im、电话都需要
		public var schemeName:String;	//条目的模式的名称
		
		public function EntryItemVO($name:String, $prefix:String, $parent:String=null, $attributeName:String=null, $scheme:String=null, $schemeName:String='rel')
		{
			name = $name;
			prefix = $prefix;
			parentName = $parent;
			attributeName = $attributeName;
			scheme = $scheme;
			schemeName = $schemeName;
		}
		
		public function toString():String
		{
			return 'google:EntryItemVO{name:'+name+',prefix:'+prefix+',parentName:'+parentName+'attributeName:'+attributeName+',scheme:'+scheme+',schemeName:'+schemeName+'}';
		}
	}
}