package google
{
	public class EventVO
	{
		public var type:String;
		public var info:String;
		
		public function EventVO($type:String, $info:String)
		{
			type = $type;
			info = $info;
		}
	}
}