package google
{
	public class MSG
	{
		public static const BAD_AUTHENTICATION:String = 'BadAuthentication';
		public static const NOT_VERIFIED:String = 'NotVerified';
		public static const TERMS_NOT_AGREED:String = 'TermsNotAgreed';
		public static const CAPCHA_REQUIRED:String = 'CaptchaRequired';
		public static const UNKNOWN:String = 'Unknown';
		public static const ACCOUT_DELETED:String = 'AccountDeleted';
		public static const ACCOUNT_DISABLED:String = 'AccountDisabled';
		public static const SERVICE_DISABLED:String = 'ServiceDisabled';
		public static const SERVICE_UNAVAILABLE:String = 'ServiceUnavailable';
		
		public static const ERROR_DESCRIPTION:Object = {	BadAuthentication:'要求使用的登录用户名或密码，但没有得到承认。 ',
															NotVerified:'该帐户的电子邮件地址尚未验证。用户将需要访问他们的谷歌帐户直接解决问题，然后才登录使用非谷歌应用程序。',
															TermsNotAgreed:'该用户没有同意条款。用户将需要访问他们直接向谷歌帐户登录之前解决这个问题使用非谷歌应用程序。', 
															CaptchaRequired:'需要验证码。',
															Unknown:'该错误是未知的或不明确;请求包含无效的输入或者是不完整的数据。',
															AccountDeleted:'用户帐户已被删除。',
															AccountDisabled:'该用户帐户已被禁用。',
															ServiceDisabled:'用户的访问指定的服务已被禁用。 （用户帐户可能仍然有效。）', 
															ServiceUnavailable:'该服务不可用，请稍后再试。'	};
		
		public static const HTTP_STATUS_DESCRIPTION:Object = {	200:'OK,No error.',
																401:'CREATED,Creation of a resource was successful.',
																304:'NOT MODIFIED,The resource hasn\'t changed since the time specified in the request\'s If-Modified-Since header.',
																400:'BAD REQUEST,Invalid request URI or header, or unsupported nonstandard parameter.',
																401:'UNAUTHORIZED,Authorization required.',
																403:'FORBIDDEN,Unsupported standard parameter, or authentication or authorization failed.',
																404:'NOT FOUND,Resource (such as a feed or entry) not found.',
																409:'CONFLICT,Specified version number doesn\'t match resource\'s latest version number.',
																410:'GONE, 	Requested change history is no longer available on the server. Refer to service-specific documentation for more details.',
																500:'INTERNAL SERVER ERROR,nternal error. This is the default code that is used for all unrecognized errors.'	};
																										
		public static function getError($errorID:String):String
		{
			var __str:String = ERROR_DESCRIPTION[$errorID];
			return __str == null ? '未知的错误代码。' : __str;
		}
		
		public static function getHTTPStatus($status:int):String
		{
			var __str:String = HTTP_STATUS_DESCRIPTION[$status];
			return __str == null ? '未知的HTTP状态代码。' : __str;
		}
	}
}