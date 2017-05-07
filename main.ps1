Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName system.ComponentModel
Add-Type -AssemblyName system.windows.forms
Add-Type -AssemblyName system.drawing
Add-Type -AssemblyName presentationCore
Add-Type -AssemblyName system.data
Get-Job |Stop-Job
Get-Job |Remove-Job
[void] [System.Reflection.Assembly]::LoadWithPartialName("system.data")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

[reflection.assembly]::LoadWithPartialName('system.data')
[reflection.assembly]::LoadWithPartialName('System.Speech')

[System.Windows.Forms.Application]::EnableVisualStyles()

function compile
{
param([string]$inputFile=$null, [string]$outputFile=$null, [switch]$verbose, [switch] $debug, [switch]$runtime20, [switch]$x86, [switch]$x64, [switch]$runtime30, [switch]$runtime40, [int]$lcid, [switch]$sta, [switch]$mta, [switch]$noConsole, [switch]$nested, [string]$iconFile=$null)
[console]::title = "naty ps1 to exe compiler"
[console]::foregroundcolor = "green"
if( !$nested ) {
     ""
     "naty compiler started"
     ""
} else {
     "PowerShell 2.0 environment started..."
     ""
}

if( $runtime20 -eq $true -and $runtime30 -eq $true ) {
     "YOU CANNOT USE SWITCHES -runtime20 AND -runtime30 AT THE SAME TIME!"
    # -1
}

if( $sta -eq $true -and $mta -eq $true ) {
     "YOU CANNOT USE SWITCHES -sta AND -eta AT THE SAME TIME!"
    # -1
}


if( [string]::IsNullOrEmpty($inputFile) -or [string]::IsNullOrEmpty($outputFile) ) {
 "[error]"
}

$psversion = 0

if($PSVersionTable.PSVersion.Major -eq 4) {
    $psversion = 4
     "You are using PowerShell 4.0."
}

if($PSVersionTable.PSVersion.Major -eq 3) {
    $psversion = 3
     "You are using PowerShell 3.0."
}

if($PSVersionTable.PSVersion.Major -eq 2) {
    $psversion = 2
     "You are using PowerShell 2.0."
}

if( $psversion -eq 0 ) {
     "THE POWERSHELL VERSION IS UNKNOWN!"
    ## -1
}

if( [string]::IsNullOrEmpty($inputFile) -or [string]::IsNullOrEmpty($outputFile) ) {
     "INPUT FILE AND OUTPUT FILE NOT SPECIFIED!"
    # -1
}

$inputFile = (new-object System.IO.FileInfo($inputFile)).FullName

$outputFile = (new-object System.IO.FileInfo($outputFile)).FullName


if( !(Test-Path $inputFile -PathType Leaf ) ) {
	 "INPUT FILE $($inputFile) NOT FOUND!"
	# -1
}

if( !([string]::IsNullOrEmpty($iconFile) ) ) {
	if( !(Test-Path (join-path (split-path $inputFile) $iconFile) -PathType Leaf ) ) {
		 "ICON FILE ""$($iconFile)"" NOT FOUND! IT MUST BE IN THE SAME DIRECTORY AS THE PS-SCRIPT (""$($inputFile)"")."
		# -1
	}
}

if( !$runtime20 -and !$runtime30 -and !$runtime40 ) {
    if( $psversion -eq 4 ) {
		$runtime40 = $true
	}  elseif( $psversion -eq 3 ) {
        $runtime30 = $true
    } else {
        $runtime20 = $true
    }
}

if( $psversion -ge 3 -and $runtime20 ) {
     "To create a EXE file for PowerShell 2.0 on PowerShell 3.0/4.0 this script now launces PowerShell 2.0..."
     ""

    $arguments = "-inputFile '$($inputFile)' -outputFile '$($outputFile)' -nested "

    if($verbose) { $arguments += "-verbose "}
    if($debug) { $arguments += "-debug "}
    if($runtime20) { $arguments += "-runtime20 "}
    if($x86) { $arguments += "-x86 "}
    if($x64) { $arguments += "-verbose "}
    if($lcid) { $arguments += "-lcid $lcid "}
    if($sta) { $arguments += "-sta "}
    if($mta) { $arguments += "-mta "}
    if($noconsole) { $arguments += "-noconsole "}

    $jobScript = @"
."$($PSHOME)\powershell.exe" -version 2.0 -command "&'$($MyInvocation.MyCommand.Path)' $($arguments)"
"@
    Invoke-Expression $jobScript

    # 0
}

if( $psversion -lt 3 -and $runtime30 ) {
     "YOU NEED TO RUN PS2EXE IN AN POWERSHELL 3.0 ENVIRONMENT"
     "  TO USE PARAMETER -runtime30"
    
    # -1
}

if( $psversion -lt 4 -and $runtime40 ) {
     "YOU NEED TO RUN PS2EXE IN AN POWERSHELL 4.0 ENVIRONMENT"
     "  TO USE PARAMETER -runtime40"
    
    # -1
}

 ""


Set-Location (Split-Path $MyInvocation.MyCommand.Path)

$type = ('System.Collections.Generic.Dictionary`2') -as "Type"
$type = $type.MakeGenericType( @( ("System.String" -as "Type"), ("system.string" -as "Type") ) )
$o = [Activator]::CreateInstance($type)

if( $psversion -eq 3 -or $psversion -eq 4 ) {
    $o.Add("CompilerVersion", "v4.0")
} else {
    $o.Add("CompilerVersion", "v2.0")
}

$referenceAssembies = @("System.dll")
$referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | ? { $_.ManifestModule.Name -ieq "Microsoft.PowerShell.ConsoleHost" } | select -First 1).location
$referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | ? { $_.ManifestModule.Name -ieq "System.Management.Automation.dll" } | select -First 1).location

if( $runtime30 -or $runtime40 ) {
    $n = new-object System.Reflection.AssemblyName("System.Core, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
    [System.AppDomain]::CurrentDomain.Load($n) | Out-Null
    $referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | ? { $_.ManifestModule.Name -ieq "System.Core.dll" } | select -First 1).location
}

if( $noConsole ) {
	$n = new-object System.Reflection.AssemblyName("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
    if( $runtime30 -or $runtime40 ) {
		$n = new-object System.Reflection.AssemblyName("System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	}
    [System.AppDomain]::CurrentDomain.Load($n) | Out-Null

	$n = new-object System.Reflection.AssemblyName("System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
    if( $runtime30 -or $runtime40 ) {
		$n = new-object System.Reflection.AssemblyName("System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	}
    [System.AppDomain]::CurrentDomain.Load($n) | Out-Null

	
	$referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | ? { $_.ManifestModule.Name -ieq "System.Windows.Forms.dll" } | select -First 1).location
    $referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | ? { $_.ManifestModule.Name -ieq "System.Drawing.dll" } | select -First 1).location
}

$inputFile = [System.IO.Path]::GetFullPath($inputFile) 
$outputFile = [System.IO.Path]::GetFullPath($outputFile) 

$platform = "anycpu"
if( $x64 -and !$x86 ) { $platform = "x64" } else { if ($x86 -and !$x64) { $platform = "x86" }}

$cop = (new-object Microsoft.CSharp.CSharpCodeProvider($o))
$cp = New-Object System.CodeDom.Compiler.CompilerParameters($referenceAssembies, $outputFile)
$cp.GenerateInMemory = $false
$cp.GenerateExecutable = $true

$iconFileParam = ""
if(!([string]::IsNullOrEmpty($iconFile))) {
	$iconFileParam = "/win32icon:$($iconFile)"
}
$cp.CompilerOptions = "/platform:$($platform) /target:$( if($noConsole){'winexe'}else{'exe'}) $($iconFileParam)"

$cp.IncludeDebugInformation = $debug

if( $debug ) {
	$cp.TempFiles.KeepFiles = $true
	
}	

 "Reading input file "  
 $inputFile 
 ""
$content = Get-Content -LiteralPath ($inputFile) -Encoding UTF8 -ErrorAction SilentlyContinue
if( $content -eq $null ) {
	 "unable to find the data (file might be protected)"
	# -2
}
$scriptInp = [string]::Join("`r`n", $content)
$script = [System.Convert]::ToBase64String(([System.Text.Encoding]::UTF8.GetBytes($scriptInp)))

    $culture = ""

    if( $lcid ) {
    $culture = @"
    System.Threading.Thread.CurrentThread.CurrentCulture = System.Globalization.CultureInfo.GetCultureInfo($lcid);
    System.Threading.Thread.CurrentThread.CurrentUICulture = System.Globalization.CultureInfo.GetCultureInfo($lcid);
"@
    }
	
	$forms = @"
		    internal class ReadKeyForm 
		    {
		        public KeyInfo key = new KeyInfo();
				public ReadKeyForm() {}
				public void ShowDialog() {}
			}
			
			internal class CredentialForm
		    {
				public class UserPwd
		        {
		            public string User = string.Empty;
		            public string Password = string.Empty;
		            public string Domain = string.Empty;
		        }

				public static UserPwd PromptForPassword(string caption, string message, string target, string user, PSCredentialTypes credTypes, PSCredentialUIOptions options) { return null;}
			}
"@	
	if( $noConsole ) {
	
		$forms = @"
			internal class CredentialForm
		    {
		        
		        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
		        private struct CREDUI_INFO
		        {
		            public int cbSize;
		            public IntPtr hwndParent;
		            public string pszMessageText;
		            public string pszCaptionText;
		            public IntPtr hbmBanner;
		        }

		        [Flags]
		        enum CREDUI_FLAGS
		        {
		            INCORRECT_PASSWORD = 0x1,
		            DO_NOT_PERSIST = 0x2,
		            REQUEST_ADMINISTRATOR = 0x4,
		            EXCLUDE_CERTIFICATES = 0x8,
		            REQUIRE_CERTIFICATE = 0x10,
		            SHOW_SAVE_CHECK_BOX = 0x40,
		            ALWAYS_SHOW_UI = 0x80,
		            REQUIRE_SMARTCARD = 0x100,
		            PASSWORD_ONLY_OK = 0x200,
		            VALIDATE_USERNAME = 0x400,
		            COMPLETE_USERNAME = 0x800,
		            PERSIST = 0x1000,
		            SERVER_CREDENTIAL = 0x4000,
		            EXPECT_CONFIRMATION = 0x20000,
		            GENERIC_CREDENTIALS = 0x40000,
		            USERNAME_TARGET_CREDENTIALS = 0x80000,
		            KEEP_USERNAME = 0x100000,
		        }

		        public enum CredUIReturnCodes
		        {
		            NO_ERROR = 0,
		            ERROR_CANCELLED = 1223,
		            ERROR_NO_SUCH_LOGON_SESSION = 1312,
		            ERROR_NOT_FOUND = 1168,
		            ERROR_INVALID_ACCOUNT_NAME = 1315,
		            ERROR_INSUFFICIENT_BUFFER = 122,
		            ERROR_INVALID_PARAMETER = 87,
		            ERROR_INVALID_FLAGS = 1004,
		        }

		        [DllImport("credui")]
		        private static extern CredUIReturnCodes CredUIPromptForCredentials(ref CREDUI_INFO creditUR,
		          string targetName,
		          IntPtr reserved1,
		          int iError,
		          StringBuilder userName,
		          int maxUserName,
		          StringBuilder password,
		          int maxPassword,
		          [MarshalAs(UnmanagedType.Bool)] ref bool pfSave,
		          CREDUI_FLAGS flags);

		        public class UserPwd
		        {
		            public string User = string.Empty;
		            public string Password = string.Empty;
		            public string Domain = string.Empty;
		        }

		        internal static UserPwd PromptForPassword(string caption, string message, string target, string user, PSCredentialTypes credTypes, PSCredentialUIOptions options)
		        {
		            // Setup the flags and variables
		            StringBuilder userPassword = new StringBuilder(), userID = new StringBuilder(user);
		            CREDUI_INFO credUI = new CREDUI_INFO();
		            credUI.cbSize = Marshal.SizeOf(credUI);
		            bool save = false;
		            
		            CREDUI_FLAGS flags = CREDUI_FLAGS.DO_NOT_PERSIST;
		            if ((credTypes & PSCredentialTypes.Domain) != PSCredentialTypes.Domain)
		            {
		                flags |= CREDUI_FLAGS.GENERIC_CREDENTIALS;
		                if ((options & PSCredentialUIOptions.AlwaysPrompt) == PSCredentialUIOptions.AlwaysPrompt)
		                {
		                    flags |= CREDUI_FLAGS.ALWAYS_SHOW_UI;
		                }
		            }

		            // Prompt the user
		            CredUIReturnCodes returnCode = CredUIPromptForCredentials(ref credUI, target, IntPtr.Zero, 0, userID, 100, userPassword, 100, ref save, flags);

		            if (returnCode == CredUIReturnCodes.NO_ERROR)
		            {
		                UserPwd ret = new UserPwd();
		                ret.User = userID.ToString();
		                ret.Password = userPassword.ToString();
		                ret.Domain = "";
		                return ret;
		            }

		            return null;
		        }

		    }
"@

		$forms += @"
		    internal class ReadKeyForm 
		    {
		        public KeyInfo key = new KeyInfo();
				public ReadKeyForm() {}
				public void ShowDialog() {}
			}
"@	
		}
		

	$programFrame = @"

	using System;
	using System.Collections.Generic;
	using System.Text;
	using System.Management.Automation;
	using System.Management.Automation.Runspaces;
	using PowerShell = System.Management.Automation.PowerShell;
	using System.Globalization;
	using System.Management.Automation.Host;
	using System.Security;
	using System.Reflection;
	using System.Runtime.InteropServices;

	namespace ik.PowerShell
	{
$forms
		internal class PS2EXEHostRawUI : PSHostRawUserInterface
	    {
			private const bool CONSOLE = $(if($noConsole){"false"}else{"true"});

			public override ConsoleColor BackgroundColor
	        {
	            get
	            {
	                return Console.BackgroundColor;
	            }
	            set
	            {
	                Console.BackgroundColor = value;
	            }
	        }

	        public override Size BufferSize
	        {
	            get
	            {
	                if (CONSOLE)
	                    return new Size(Console.BufferWidth, Console.BufferHeight);
	                else
	                    return new Size(0, 0);
	            }
	            set
	            {
	                Console.BufferWidth = value.Width;
	                Console.BufferHeight = value.Height;
	            }
	        }

	        public override Coordinates CursorPosition
	        {
	            get
	            {
	                return new Coordinates(Console.CursorLeft, Console.CursorTop);
	            }
	            set
	            {
	                Console.CursorTop = value.Y;
	                Console.CursorLeft = value.X;
	            }
	        }

	        public override int CursorSize
	        {
	            get
	            {
	                return Console.CursorSize;
	            }
	            set
	            {
	                Console.CursorSize = value;
	            }
	        }

	        public override void FlushInputBuffer()
	        {
	            throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.FlushInputBuffer");
	        }

	        public override ConsoleColor ForegroundColor
	        {
	            get
	            {
	                return Console.ForegroundColor;
	            }
	            set
	            {
	                Console.ForegroundColor = value;
	            }
	        }

	        public override BufferCell[,] GetBufferContents(Rectangle rectangle)
	        {
	            throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.GetBufferContents");
	        }

	        public override bool KeyAvailable
	        {
	            get
	            {
	                throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.KeyAvailable/Get");
	            }
	        }

	        public override Size MaxPhysicalWindowSize
	        {
	            get { return new Size(Console.LargestWindowWidth, Console.LargestWindowHeight); }
	        }

	        public override Size MaxWindowSize
	        {
	            get { return new Size(Console.BufferWidth, Console.BufferWidth); }
	        }

	        public override KeyInfo ReadKey(ReadKeyOptions options)
	        {
	            if( CONSOLE ) {
		            ConsoleKeyInfo cki = Console.ReadKey();

		            ControlKeyStates cks = 0;
		            if ((cki.Modifiers & ConsoleModifiers.Alt) != 0)
		                cks |= ControlKeyStates.LeftAltPressed | ControlKeyStates.RightAltPressed;
		            if ((cki.Modifiers & ConsoleModifiers.Control) != 0)
		                cks |= ControlKeyStates.LeftCtrlPressed | ControlKeyStates.RightCtrlPressed;
		            if ((cki.Modifiers & ConsoleModifiers.Shift) != 0)
		                cks |= ControlKeyStates.ShiftPressed;
		            if (Console.CapsLock)
		                cks |= ControlKeyStates.CapsLockOn;

		            return new KeyInfo((int)cki.Key, cki.KeyChar, cks, false);
				} else {
					ReadKeyForm f = new ReadKeyForm();
	                f.ShowDialog();
	                return f.key; 
				}
	        }

	        public override void ScrollBufferContents(Rectangle source, Coordinates destination, Rectangle clip, BufferCell fill)
	        {
	            throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.ScrollBufferContents");
	        }

	        public override void SetBufferContents(Rectangle rectangle, BufferCell fill)
	        {
	            throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.SetBufferContents(1)");
	        }

	        public override void SetBufferContents(Coordinates origin, BufferCell[,] contents)
	        {
	            throw new Exception("Not implemented: ik.PowerShell.PS2EXEHostRawUI.SetBufferContents(2)");
	        }

	        public override Coordinates WindowPosition
	        {
	            get
	            {
	                Coordinates s = new Coordinates();
	                s.X = Console.WindowLeft;
	                s.Y = Console.WindowTop;
	                return s;
	            }
	            set
	            {
	                Console.WindowLeft = value.X;
	                Console.WindowTop = value.Y;
	            }
	        }

	        public override Size WindowSize
	        {
	            get
	            {
	                Size s = new Size();
	                s.Height = Console.WindowHeight;
	                s.Width = Console.WindowWidth;
	                return s;
	            }
	            set
	            {
	                Console.WindowWidth = value.Width;
	                Console.WindowHeight = value.Height;
	            }
	        }

	        public override string WindowTitle
	        {
	            get
	            {
	                return Console.Title;
	            }
	            set
	            {
	                Console.Title = value;
	            }
	        }
	    }
	    internal class PS2EXEHostUI : PSHostUserInterface
	    {
			private const bool CONSOLE = $(if($noConsole){"false"}else{"true"});

			private PS2EXEHostRawUI rawUI = null;

	        public PS2EXEHostUI()
	            : base()
	        {
	            rawUI = new PS2EXEHostRawUI();
	        }

	        public override Dictionary<string, PSObject> Prompt(string caption, string message, System.Collections.ObjectModel.Collection<FieldDescription> descriptions)
	        {
				if( !CONSOLE )
					return new Dictionary<string, PSObject>();
					
	            if (!string.IsNullOrEmpty(caption))
	                WriteLine(caption);
	            if (!string.IsNullOrEmpty(message))
	                WriteLine(message);
	            Dictionary<string, PSObject> ret = new Dictionary<string, PSObject>();
	            foreach (FieldDescription cd in descriptions)
	            {
	                Type t = null;
	                if (string.IsNullOrEmpty(cd.ParameterAssemblyFullName))
	                    t = typeof(string);
	                else t = Type.GetType(cd.ParameterAssemblyFullName);


	                if (t.IsArray)
	                {
	                    Type elementType = t.GetElementType();
	                    Type genericListType = Type.GetType("System.Collections.Generic.List"+((char)0x60).ToString()+"1");
	                    genericListType = genericListType.MakeGenericType(new Type[] { elementType });
	                    ConstructorInfo constructor = genericListType.GetConstructor(BindingFlags.CreateInstance | BindingFlags.Instance | BindingFlags.Public, null, Type.EmptyTypes, null);
	                    object resultList = constructor.Invoke(null);

	                    int index = 0;
	                    string data = "";
	                    do
	                    {
	                        try
	                        {
	                            if (!string.IsNullOrEmpty(cd.Name))
	                                Write(string.Format("{0}[{1}]: ", cd.Name, index));
	                            data = ReadLine();

	                            if (string.IsNullOrEmpty(data))
	                                break;
	                            
	                            object o = System.Convert.ChangeType(data, elementType);

	                            genericListType.InvokeMember("Add", BindingFlags.InvokeMethod | BindingFlags.Public | BindingFlags.Instance, null, resultList, new object[] { o });
	                        }
	                        catch (Exception ex)
	                        {
	                            throw new Exception("Exception in ik.PowerShell.PS2EXEHostUI.Prompt*1");
	                        }
	                        index++;
	                    } while (true);

	                    System.Array retArray = (System.Array )genericListType.InvokeMember("ToArray", BindingFlags.InvokeMethod | BindingFlags.Public | BindingFlags.Instance, null, resultList, null);
	                    ret.Add(cd.Name, new PSObject(retArray));
	                }
	                else
	                {

	                    if (!string.IsNullOrEmpty(cd.Name))
	                        Write(string.Format("{0}: ", cd.Name));
	                    object o = null;

	                    string l = null;
	                    try
	                    {
	                        l = ReadLine();

	                        if (string.IsNullOrEmpty(l))
	                            o = cd.DefaultValue;
	                        if (o == null)
	                        {
	                            o = System.Convert.ChangeType(l, t);
	                        }

	                        ret.Add(cd.Name, new PSObject(o));
	                    }
	                    catch
	                    {
	                        throw new Exception("Exception in ik.PowerShell.PS2EXEHostUI.Prompt*2");
	                    }
	                }
	            }
	            return ret;
	        }

	        public override int PromptForChoice(string caption, string message, System.Collections.ObjectModel.Collection<ChoiceDescription> choices, int defaultChoice)
	        {
				if( !CONSOLE )
					return -1;
					
	            if (!string.IsNullOrEmpty(caption))
	                WriteLine(caption);
	            WriteLine(message);
	            int idx = 0;
	            SortedList<string, int> res = new SortedList<string, int>();
	            foreach (ChoiceDescription cd in choices)
	            {

	                string l = cd.Label;
	                int pos = cd.Label.IndexOf('&');
	                if (pos > -1)
	                {
	                    l = cd.Label.Substring(pos + 1, 1);
	                }
	                res.Add(l.ToLower(), idx);

	                if (idx == defaultChoice)
	                {
	                    Console.ForegroundColor = ConsoleColor.Yellow;
	                    Write(ConsoleColor.Yellow, Console.BackgroundColor, string.Format("[{0}]: ", l, cd.HelpMessage));
	                    WriteLine(ConsoleColor.Gray, Console.BackgroundColor, string.Format("{1}", l, cd.HelpMessage));
	                }
	                else
	                {
	                    Console.ForegroundColor = ConsoleColor.White;
	                    Write(ConsoleColor.White, Console.BackgroundColor, string.Format("[{0}]: ", l, cd.HelpMessage));
	                    WriteLine(ConsoleColor.Gray, Console.BackgroundColor, string.Format("{1}", l, cd.HelpMessage));
	                }
	                idx++;
	            }

	            try
	            {
	                string s = Console.ReadLine().ToLower();
	                if (res.ContainsKey(s))
	                {
	                    return res[s];
	                }
	            }
	            catch { }


	            return -1;
	        }

	        public override PSCredential PromptForCredential(string caption, string message, string userName, string targetName, PSCredentialTypes allowedCredentialTypes, PSCredentialUIOptions options)
	        {
	            if (!CONSOLE)
	            {
	                ik.PowerShell.CredentialForm.UserPwd cred = CredentialForm.PromptForPassword(caption, message, targetName, userName, allowedCredentialTypes, options);
	                if (cred != null )
	                {
	                    System.Security.SecureString x = new System.Security.SecureString();
	                    foreach (char c in cred.Password.ToCharArray())
	                        x.AppendChar(c);

	                    return new PSCredential(cred.User, x);
	                }
	                return null;
	            }
					
	            if (!string.IsNullOrEmpty(caption))
	                WriteLine(caption);
	            WriteLine(message);
	            Write("User name: ");
	            string un = ReadLine();
	            SecureString pwd = null;
	            if ((options & PSCredentialUIOptions.ReadOnlyUserName) == 0)
	            {
	                Write("Password: ");
	                pwd = ReadLineAsSecureString();
	            }
	            PSCredential c2 = new PSCredential(un, pwd);
	            return c2;
	        }

	        public override PSCredential PromptForCredential(string caption, string message, string userName, string targetName)
	        {
	            if (!CONSOLE)
	            {
                	ik.PowerShell.CredentialForm.UserPwd cred = CredentialForm.PromptForPassword(caption, message, targetName, userName, PSCredentialTypes.Default, PSCredentialUIOptions.Default);
	                if (cred != null )
	                {
	                    System.Security.SecureString x = new System.Security.SecureString();
	                    foreach (char c in cred.Password.ToCharArray())
	                        x.AppendChar(c);

	                    return new PSCredential(cred.User, x);
	                }
	                return null;
	            }

				if (!string.IsNullOrEmpty(caption))
	                WriteLine(caption);
	            WriteLine(message);
	            Write("User name: ");
	            string un = ReadLine();
	            Write("Password: ");
	            SecureString pwd = ReadLineAsSecureString();
	            PSCredential c2 = new PSCredential(un, pwd);
	            return c2;
	        }

	        public override PSHostRawUserInterface RawUI
	        {
	            get
	            {
	                return rawUI;
	            }
	        }

	        public override string ReadLine()
	        {
	            return Console.ReadLine();
	        }

	        public override System.Security.SecureString ReadLineAsSecureString()
	        {
	            System.Security.SecureString x = new System.Security.SecureString();
	            string l = Console.ReadLine();
	            foreach (char c in l.ToCharArray())
	                x.AppendChar(c);
	            return x;
	        }

	        public override void Write(ConsoleColor foregroundColor, ConsoleColor backgroundColor, string value)
	        {
	            Console.ForegroundColor = foregroundColor;
	            Console.BackgroundColor = backgroundColor;
	            Console.Write(value);
	        }

	        public override void Write(string value)
	        {
	            Console.ForegroundColor = ConsoleColor.White;
	            Console.BackgroundColor = ConsoleColor.Black;
	            Console.Write(value);
	        }

	        public override void WriteDebugLine(string message)
	        {
	            Console.ForegroundColor = ConsoleColor.DarkMagenta;
	            Console.BackgroundColor = ConsoleColor.Black;
	            Console.WriteLine(message);
	        }

	        public override void WriteErrorLine(string value)
	        {
	            Console.ForegroundColor = ConsoleColor.Red;
	            Console.BackgroundColor = ConsoleColor.Black;
	            Console.WriteLine(value);
	        }

	        public override void WriteLine(string value)
	        {
	            Console.ForegroundColor = ConsoleColor.White;
	            Console.BackgroundColor = ConsoleColor.Black;
	            Console.WriteLine(value);
	        }

	        public override void WriteProgress(long sourceId, ProgressRecord record)
	        {

	        }

	        public override void WriteVerboseLine(string message)
	        {
	            Console.ForegroundColor = ConsoleColor.DarkCyan;
	            Console.BackgroundColor = ConsoleColor.Black;
	            Console.WriteLine(message);
	        }

	        public override void WriteWarningLine(string message)
	        {
	            Console.ForegroundColor = ConsoleColor.Yellow;
	            Console.BackgroundColor = ConsoleColor.Black;
	            Console.WriteLine(message);
	        }
	    }



	    internal class PS2EXEHost : PSHost
	    {
			private const bool CONSOLE = $(if($noConsole){"false"}else{"true"});

			private PS2EXEApp parent;
	        private PS2EXEHostUI ui = null;

	        private CultureInfo originalCultureInfo =
	            System.Threading.Thread.CurrentThread.CurrentCulture;

	        private CultureInfo originalUICultureInfo =
	            System.Threading.Thread.CurrentThread.CurrentUICulture;

	        private Guid myId = Guid.NewGuid();

	        public PS2EXEHost(PS2EXEApp app, PS2EXEHostUI ui)
	        {
	            this.parent = app;
	            this.ui = ui;
	        }

	        public override System.Globalization.CultureInfo CurrentCulture
	        {
	            get
	            {
	                return this.originalCultureInfo;
	            }
	        }

	        public override System.Globalization.CultureInfo CurrentUICulture
	        {
	            get
	            {
	                return this.originalUICultureInfo;
	            }
	        }

	        public override Guid InstanceId
	        {
	            get
	            {
	                return this.myId;
	            }
	        }

	        public override string Name
	        {
	            get
	            {
	                return "PS2EXE_Host";
	            }
	        }

	        public override PSHostUserInterface UI
	        {
	            get
	            {
	                return ui;
	            }
	        }

	        public override Version Version
	        {
	            get
	            {
	                return new Version(0, 2, 0, 0);
	            }
	        }

	        public override void EnterNestedPrompt()
	        {
	        }

	        public override void ExitNestedPrompt()
	        {
	        }

	        public override void NotifyBeginApplication()
	        {
	            return;
	        }

	        public override void NotifyEndApplication()
	        {
	            return;
	        }

	        public override void SetShouldExit(int exitCode)
	        {
	            this.parent.ShouldExit = true;
	            this.parent.ExitCode = exitCode;
	        }
	    }



	    internal interface PS2EXEApp
	    {
	        bool ShouldExit { get; set; }
	        int ExitCode { get; set; }
	    }


	    internal class PS2EXE : PS2EXEApp
	    {
			private const bool CONSOLE = $(if($noConsole){"false"}else{"true"});
			
	        private bool shouldExit;

	        private int exitCode;

	        public bool ShouldExit
	        {
	            get { return this.shouldExit; }
	            set { this.shouldExit = value; }
	        }

	        public int ExitCode
	        {
	            get { return this.exitCode; }
	            set { this.exitCode = value; }
	        }

	        $(if($sta){"[STAThread]"})$(if($mta){"[MTAThread]"})
	        private static int Main(string[] args)
	        {
                $culture

	            PS2EXE me = new PS2EXE();

	            bool paramWait = false;
	            string extractFN = string.Empty;

	            PS2EXEHostUI ui = new PS2EXEHostUI();
	            PS2EXEHost host = new PS2EXEHost(me, ui);
	            System.Threading.ManualResetEvent mre = new System.Threading.ManualResetEvent(false);

	            AppDomain.CurrentDomain.UnhandledException += new UnhandledExceptionEventHandler(CurrentDomain_UnhandledException);

	            try
	            {
	                using (Runspace myRunSpace = RunspaceFactory.CreateRunspace(host))
	                {
	                    $(if($sta -or $mta) {"myRunSpace.ApartmentState = System.Threading.ApartmentState."})$(if($sta){"STA"})$(if($mta){"MTA"});
	                    myRunSpace.Open();

	                    using (System.Management.Automation.PowerShell powershell = System.Management.Automation.PowerShell.Create())
	                    {
	                        Console.CancelKeyPress += new ConsoleCancelEventHandler(delegate(object sender, ConsoleCancelEventArgs e)
	                        {
	                            try
	                            {
	                                powershell.BeginStop(new AsyncCallback(delegate(IAsyncResult r)
	                                {
	                                    mre.Set();
	                                    e.Cancel = true;
	                                }), null);
	                            }
	                            catch
	                            {
	                            };
	                        });

	                        powershell.Runspace = myRunSpace;
	                        powershell.Streams.Progress.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
	                            {
	                                ui.WriteLine(((PSDataCollection<ProgressRecord>)sender)[e.Index].ToString());
	                            });
	                        powershell.Streams.Verbose.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
	                            {
	                                ui.WriteVerboseLine(((PSDataCollection<VerboseRecord>)sender)[e.Index].ToString());
	                            });
	                        powershell.Streams.Warning.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
	                            {
	                                ui.WriteWarningLine(((PSDataCollection<WarningRecord>)sender)[e.Index].ToString());
	                            });
	                        powershell.Streams.Error.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
	                            {
	                                ui.WriteErrorLine(((PSDataCollection<ErrorRecord>)sender)[e.Index].ToString());
	                            });

	                        PSDataCollection<PSObject> inp = new PSDataCollection<PSObject>();
	                        inp.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
	                        {
	                            ui.WriteLine(inp[e.Index].ToString());
	                        });

	                        PSDataCollection<PSObject> outp = new PSDataCollection<PSObject>();
	                        outp.DataAdded += new EventHandler<DataAddedEventArgs>(delegate(object sender, DataAddedEventArgs e)
	                        {
	                            ui.WriteLine(outp[e.Index].ToString());
	                        });

	                        int separator = 0;
	                        int idx = 0;
	                        foreach (string s in args)
	                        {
	                            if (string.Compare(s, "-wait", true) == 0)
	                                paramWait = true;
	                            else if (s.StartsWith("-extract", StringComparison.InvariantCultureIgnoreCase))
	                            {
	                                string[] s1 = s.Split(new string[] { ":" }, 2, StringSplitOptions.RemoveEmptyEntries);
	                                if (s1.Length != 2)
	                                {
	                                    Console.WriteLine("If you specify the -extract option you need to add a file for extraction in this way\r\n   -extract:\"<filename>\"");
	                                    return 1;
	                                }
	                                extractFN = s1[1].Trim(new char[] { '\"' });
	                            }
	                            else if (string.Compare(s, "-end", true) == 0)
	                            {
	                                separator = idx + 1;
	                                break;
	                            }
	                            else if (string.Compare(s, "-debug", true) == 0)
	                            {
	                                System.Diagnostics.Debugger.Launch();
	                                break;
	                            }
	                            idx++;
	                        }

	                        string script = System.Text.Encoding.UTF8.GetString(System.Convert.FromBase64String(@"$($script)"));

	                        if (!string.IsNullOrEmpty(extractFN))
	                        {
	                            System.IO.File.WriteAllText(extractFN, script);
	                            return 0;
	                        }

							List<string> paramList = new List<string>(args);

	                        powershell.AddScript(script);
                        	powershell.AddParameters(paramList.GetRange(separator, paramList.Count - separator));
                        	powershell.AddCommand("out-string");
                        	powershell.AddParameter("-stream");


	                        powershell.BeginInvoke<PSObject, PSObject>(inp, outp, null, new AsyncCallback(delegate(IAsyncResult ar)
	                        {
	                            if (ar.IsCompleted)
	                                mre.Set();
	                        }), null);

	                        while (!me.ShouldExit && !mre.WaitOne(100))
	                        {
	                        };

	                        powershell.Stop();
	                    }

	                    myRunSpace.Close();
	                }
	            }
	            catch (Exception ex)
	            {
	                Console.Write("An exception occured: ");
	                Console.WriteLine(ex.Message);
	            }

	            if (paramWait)
	            {
	                Console.WriteLine("[Hit any key to exit]");
	                Console.ReadKey();
	            }
	            return me.ExitCode;
	        }


	        static void CurrentDomain_UnhandledException(object sender, UnhandledExceptionEventArgs e)
	        {
	            throw new Exception("Unhandeled exception in PS2EXE");
	        }
	    }
	}
"@
  $configFileForEXE2 = "<?xml version=""1.0"" encoding=""utf-8"" ?>`r`n<configuration><startup><supportedRuntime version=""v2.0.50727""/></startup></configuration>"
  $configFileForEXE3 = "<?xml version=""1.0"" encoding=""utf-8"" ?>`r`n<configuration><startup><supportedRuntime version=""v4.0"" sku="".NETFramework,Version=v4.0"" /></startup></configuration>"
 "Compiling file... " 
$cr = $cop.CompileAssemblyFromSource($cp, $programFrame)
if( $cr.Errors.Count -gt 0 ) {
	 ""
	 ""
	if( Test-Path $outputFile ) {
		Remove-Item $outputFile -Verbose:$false
	}
	  "Could not create the PowerShell .exe file because of compilation errors. Use -verbose parameter to see details."
	$cr.Errors | % { Write-Verbose $_ -Verbose:$verbose}
} else {
	 ""
	 ""
	if( Test-Path $outputFile ) {
		 "Output file "  
		 $outputFile  
		 " written" 
		
		if( $debug) {
			$cr.TempFiles | ? { $_ -ilike "*.cs" } | select -first 1 | % {
				$dstSrc =  ([System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($outputFile), [System.IO.Path]::GetFileNameWithoutExtension($outputFile)+".cs"))
				 "Source file name for debug copied: $($dstSrc)"
				Copy-Item -Path $_ -Destination $dstSrc -Force
			}
			$cr.TempFiles | Remove-Item -Verbose:$false -Force -ErrorAction SilentlyContinue
		}
		if( $runtime20 ) {
			$configFileForEXE2 | Set-Content ($outputFile+".config")
			 "Config file for EXE created."
		}
		if( $runtime30 -or $runtime40 ) {
			$configFileForEXE3 | Set-Content ($outputFile+".config")
			 "Config file for EXE created."
			[console]::foregroundcolor = "gray"
		}
	} else {
		 "Output file "  
		 $outputFile  
		 " not written" 
	}
}

}

function style ()
{
 $style = New-Object System.Windows.Forms.Form
 $style.Text = "style"
 $style.BackColor = "gray"
 $style.ForeColor = "white"
 $style.FormBorderStyle = 'fixed3D'
 $style.MaximizeBox = $false
 $style.MinimizeBox = $false
 #$style.Icon = New-Object System.Drawing.Icon('C:\Users\naty\Pictures\icons\icon13.ico')
 $style.ControlBox = $false
 $style.Size = New-Object System.Drawing.Size(300,250)
 $style.MinimumSize = New-Object System.Drawing.Size(300,250)
 $style.MaximumSize = New-Object System.Drawing.Size(300,250)
 $style.DesktopLocation = New-Object System.Drawing.Size(300,300)

 $dark = New-Object System.Windows.Forms.Button
 $dark.Text = "dark mode"
 $dark.Location = New-Object System.Drawing.Size(10,20)
 $dark.Size = New-Object System.Drawing.Size(60,30)
 $dark.add_click({
    $uback.selecteditem = "gray"
    $ufore.selecteditem = "white"
    $rtr.BackColor = "gray"
    $rtr.ForeColor = "white"
    })
 $style.Controls.Add($dark)
 $ter = New-Object System.Windows.Forms.Button
 $ter.Text = "Terminal>_"
 $ter.Location = New-Object System.Drawing.Size(10,90)
 $ter.Size = New-Object System.Drawing.Size(60,30)
 $ter.add_click({
    $rtr.Font = New-Object System.Drawing.Font("lucida console" , 10)
    $uback.selecteditem = "black"
    $ufore.selecteditem = "lightgreen"
    $rtr.BackColor = "black"
    $rtr.ForeColor = "lightgreen"
    })
 $style.Controls.Add($ter)

 $light = New-Object System.Windows.Forms.Button
 $light.Text = "light mode"
 $light.Location = New-Object System.Drawing.Size(10,55)
 $light.Size = New-Object System.Drawing.Size(60,30)
 $light.add_click({
    $uback.selecteditem = "white"
    $ufore.selecteditem = "black"
    $rtr.BackColor = "white"
    $rtr.ForeColor = "black"
    })
 $style.Controls.Add($light)

 $trns = New-Object System.Windows.Forms.Button
 $trns.Text = 'transparent'
 $trns.Location = New-Object System.Drawing.Size(10,125)
 $trns.Size = New-Object System.Drawing.Size(60,30)
 $trns.add_click({
        $frm.BackColor = 'black'
        $men.BackColor = 'black'
        $frm.AllowTransparency = $true
        $frm.TransparencyKey = '0'
        })
 $style.Controls.Add($trns)

 $uback = New-Object System.Windows.Forms.ListBox
 $uback.SelectionMode = 'one'
 $uback.Size = New-Object System.Drawing.Size(80,100)
 $uback.Location = New-Object System.Drawing.Size(80,20)
 [void] $uback.Items.Add("black")
 [void] $uback.Items.Add("white")
 [void] $uback.items.Add("red")
 [void] $uback.Items.Add("blue")
 [void] $uback.Items.Add("gray")
 [void] $uback.Items.Add("tan")
 [void] $uback.Items.Add("yellow")
 [void] $uback.Items.Add("green")
 [void] $uback.Items.Add("purple")
 [void] $uback.Items.Add("orange")
 [void] $uback.Items.Add("darkred")
 [void] $uback.Items.Add("darkblue")
 [void] $uback.Items.Add("darkgray")
 [void] $uback.Items.Add("darkgreen")
 [void] $uback.Items.Add("darkorange")
 [void] $uback.Items.Add("lightred")
 [void] $uback.Items.Add("lightblue")
 [void] $uback.Items.Add("lightgray")
 [void] $uback.Items.Add("lightgreen")
 [void] $uback.Items.Add("lightorange")
 $bc = $rtr.backcolor
 $uback.SelectedItem = $bc

 $style.Controls.Add($uback)

 $ubackl = New-Object System.Windows.Forms.Label
 $ubackl.Text = "backcolor"
 $ubackl.BackColor = "gray"
 $ubackl.ForeColor = "white"
 $ubackl.Location = New-Object System.Drawing.Size(80,122)
 $ubackl.Size = New-Object System.Drawing.Size(80,30)
 $style.Controls.Add($ubackl)

 $ufore = New-Object System.Windows.Forms.ListBox
 $ufore.SelectionMode = 'one'
 $ufore.Size = New-Object System.Drawing.Size(80,100)
 $ufore.Location = New-Object System.Drawing.Size(170,20)
 [void] $ufore.Items.Add("black")
 [void] $ufore.Items.Add("white")
 [void] $ufore.items.Add("red")
 [void] $ufore.Items.Add("blue")
 [void] $ufore.Items.Add("gray")
 [void] $ufore.Items.Add("tan")
 [void] $ufore.Items.Add("yellow")
 [void] $ufore.Items.Add("green")
 [void] $ufore.Items.Add("purple")
 [void] $ufore.Items.Add("orange")
 [void] $ufore.Items.Add("darkred")
 [void] $ufore.Items.Add("darkblue")
 [void] $ufore.Items.Add("darkgray")
 [void] $ufore.Items.Add("darkgreen")
 [void] $ufore.Items.Add("darkorange")
 [void] $ufore.Items.Add("lightred")
 [void] $ufore.Items.Add("lightblue")
 [void] $ufore.Items.Add("lightgray")
 [void] $ufore.Items.Add("lightgreen")
 [void] $ufore.Items.Add("lightorange")
 $ufore.SelectedItem = $rtr.forecolor

 $style.Controls.Add($ufore)
 $uforel = New-Object System.Windows.Forms.Label
 $uforel.Text = "forecolor"
 $uforel.BackColor = "gray"
 $uforel.ForeColor = "white"
 $uforel.Location = New-Object System.Drawing.Size(170,122)
 $uforel.Size = New-Object System.Drawing.Size(80,30)
 $style.Controls.Add($uforel)

 $ok = New-Object System.Windows.Forms.Button
 $ok.Text = "OK"
 $ok.Location = New-Object System.Drawing.Size(20,160)
 $ok.Size = New-Object System.Drawing.Size(70,20)
 $ok.add_click({
        $style.Close()
        })
 $style.Controls.Add($ok)

 $apply = New-Object System.Windows.Forms.Button
 $apply.Text = "Apply"
 $apply.Size = New-Object System.Drawing.Size(70,20)
 $apply.Location = New-Object System.Drawing.Size(120,160)
 $apply.add_click({
        $bc = $uback.SelectedItem
        $fc = $ufore.SelectedItem
        $rtr.BackColor = $bc
        $rtr.ForeColor = $fc
        })
 $style.Controls.Add($apply)

 $style.ShowDialog()

}
function share{
    $share = New-Object System.Windows.Forms.Form
    $share.Size = New-Object System.Drawing.Size(300,400)
    $share.Text = "Share"
    $share.FormBorderStyle = 'fixedtoolwindow'

    $wifi = New-Object System.Windows.Forms.Button
    $wifi.Location = New-Object System.Drawing.Size(20,10)
    $wifi.Size = New-Object System.Drawing.Size(160,30)
    $wifi.BackColor = 'tan'
    $wifi.ForeColor = 'white'
    $wifi.Text = "Create wifi network"
    $wifi.FlatStyle = 'flat'
    $wifi.add_click({
        $wi_fi = New-Object System.Windows.Forms.Form
        $wi_fi.Size = New-Object System.Drawing.Size(200,200)
        $wi_fi.FormBorderStyle = 'fixedtoolwindow'
        $wi_fi.Text = "Wifi network"
        $ssid = New-Object System.Windows.Forms.TextBox
        $ssid.Text = "wi-fi name"
        $ssid.Size = New-Object System.Drawing.Size(65,0)
        $ssid.Location = New-Object System.Drawing.Size(5,10)
        $wi_fi.Controls.Add($ssid)
        $pass = New-Object System.Windows.Forms.TextBox
        $pass.Text = "password"
        $pass.UseSystemPasswordChar = $true
        $pass.Location = New-Object System.Drawing.Size(5,40)
        $pass.Size = $ssid.Size
        $wi_fi.Controls.Add($pass)
        $spass = New-Object System.Windows.Forms.CheckBox
        $spass.Checked = $false
        $spass.Location = New-Object System.Drawing.Size(5,65)
        $spass.add_click({
            if ($spass.Checked)
            {
                $pass.UseSystemPasswordChar = $false
            } elseif (!$spass.Checked)
            {
                $pass.UseSystemPasswordChar = $true
            }
        })
        $spass.Text = "show password"
        $wi_fi.Controls.Add($spass)
        $strwi = New-Object System.Windows.Forms.Button
        $strwi.Text = "start"
        $strwi.Location = New-Object System.Drawing.Size(5,80)
        $strwi.Size = New-Object System.Drawing.Size(60,25)
        $strwi.add_click({
            netsh wlan set hostednetwork ssid=$($ssid.Text) key=$($pass.Text) mode=allow
            netsh wlan start hostednetwork
            $wi_fi.Close()
        })
        $wi_fi.Controls.Add($strwi)
        $wi_fi.ShowDialog()
    })
    $share.Controls.Add($wifi)


    $web = New-Object System.Windows.Forms.Button
    $web.Text = "start server"
    $web.Location = New-Object System.Drawing.Size(5,55)
    $web.Size = New-Object System.Drawing.Size(100,30)
    $web.FlatStyle = 'flat'
    $web.add_Click({
        clc .\tmp.ps1
        clc .\tmp
        foreach ($tmp in $rtr.text)
        {
            ac .\tmp $tmp
        }
        sc .\tmp.ps1 "`$filepath="".\tmp"""
        start web.bat
    })
    $share.Controls.Add($web)

    $share.ShowDialog()
}

$frm = New-Object System.Windows.Forms.Form
$frm.Text = "Powershell script to exe compiler"
$frm.size = New-Object System.Drawing.Size(900,700)
$frm.MaximizeBox = $true
$frm.MinimizeBox = $true
$frm.ControlBox = $true
$frm.MaximumSize = New-Object System.Drawing.Size(900,700)
$frm.MinimumSize = New-Object System.Drawing.Size(900,700)
$ico = New-Object System.Drawing.Icon('icons\icon13.ico') 
#$bg = [System.Drawing.Image]::FromFile('C:\Users\naty\Pictures\jpgs\Back.jpg')
$frm.BackgroundImage = $bg
$frm.Icon = $ico
$frm.KeyPreview = $true
$frm.Dock = "fill"
$frm.StartPosition = "manual"




function web ()
{
 $web = New-Object System.Windows.Forms.Form
 $web.Size = New-Object System.Drawing.Size(300,200)
 $web.BackColor = 'gray'
 $web.FormBorderStyle = 'fixedtoolwindow'
 $web.Text = '   clone'

 $ins = New-Object System.Windows.Forms.TextBox
 $ins.Location = New-Object System.Drawing.Size(50,50)
 $ins.Size = New-Object System.Drawing.Size(120,0)
 $ins.BackColor = 'tan'
 $web.Controls.Add($ins)

 $insl = New-Object System.Windows.Forms.Label
 $insl.Location = New-Object System.Drawing.Size(2,50)
 $insl.Text = 'URL/IP:'
 $insl.Size = New-Object System.Drawing.Size(55,20)
 $insl.TextAlign = 'middlecenter'
 $insl.BackColor = 'transparent'
 $web.Controls.Add($insl)

 $ok = New-Object System.Windows.Forms.Button
 $ok.Text = "Clone"
 $ok.Location = New-Object System.Drawing.Size(50,70)
 $ok.Size = New-Object System.Drawing.Size(120,25)
 $ok.FlatStyle = 'system'
 $ok.add_click({
        $uri = $ins.Text
        $web = new-object System.Net.WebClient
        $web.Headers.Add([System.Net.HttpRequestHeader]::UserAgent, "Posh_compiler")
        $web.DownloadString($uri) |Out-File $env:TEMP/rr
        foreach ($tmp in (Get-Content $env:TEMP/rr))
        {
         $rtr.text = "$rtrrr
$tmp"
         $rtrrr = $rtr.text
        }
        })
 $web.Controls.Add($ok)
 $web.ShowDialog()

}

function runas ()
{
 $run = New-Object System.Windows.Forms.Form
 #$run.Icon = New-Object System.Drawing.Icon('C:\Users\naty\Pictures\icons\icon13.ico')
 $run.ControlBox = $false
 $run.MaximizeBox = $false
 $run.MinimizeBox = $false
 $run.Size = New-Object System.Drawing.Size(400,300)
 $run.DesktopLocation = New-Object System.Drawing.Size(300,300)
 $run.BackColor = "gray"
 $run.ForeColor = "white"
 $run.Text = "run as"
 $run.FormBorderStyle = 'fixed3D'

 $python = New-Object System.Windows.Forms.Button
 $python.Text = "run in new console"
 $python.Location = New-Object System.Drawing.Size(20,20)
 $python.Size = New-Object System.Drawing.Size(210,30)
 $python.add_click({
        sc $env:TEMP/temp.ps1 $rtr.Text
        sc $env:TEMP/temp.bat "@cd /d $env:temp&@powershell -executionpolicy bypass -nologo -noexit -noprofile -file ./temp.ps1"
        start $env:TEMP/temp.bat
        sleep 3
        Remove-Item -Path $env:TEMP/temp.bat;Remove-Item -Path $env:TEMP/temp.ps1
        })
 $run.Controls.Add($python)

 $html = New-Object System.Windows.Forms.Button
 $html.Text = "run on remote"
 $html.Location = New-Object System.Drawing.Size(20,50)
 $html.Size = New-Object System.Drawing.Size(210,30)
 $html.add_click({
        $tmpfrm = New-Object System.Windows.Forms.Form
        $tmpfrm.Size = New-Object System.Drawing.Size(250,130)
        $tmpfrm.Text = "Run at Remote"
        $tmpfrm.FormBorderStyle = 'fixedtoolwindow'

        $ctxt = New-Object System.Windows.Forms.TextBox
        $ctxt.Text = "Domain name"
        $ctxt.Location = New-Object System.Drawing.Size(20,10)
        $ctxt.BackColor = 'tan'
        $ctxt.Size = New-Object System.Drawing.Size(100,20)
        $tmpfrm.Controls.Add($ctxt)
        
        $utxt = New-Object System.Windows.Forms.TextBox
        $utxt.Text = "Username"
        $utxt.Location = New-Object System.Drawing.Size(20,35)
        $utxt.Size = New-Object System.Drawing.Size(100,0)
        $utxt.backColor = 'tan'
        $tmpfrm.Controls.Add($utxt)

        $psrem = New-Object System.Windows.Forms.Button
        $psrem.Location = New-Object System.Drawing.Size(125,10)
        $psrem.Size = New-Object System.Drawing.Size(114,47)
        $psrem.ForeColor = 'white'
        $psrem.BackColor = 'gray'
        $psrem.Text = "Ps Remoting"
        $psrem.FlatStyle = 'flat'
        $psrem.add_click({
            try
            {
                Invoke-Command -ScriptBlock { $($rtr.Text) } -ComputerName "$($ctxt.Text)" -Credential "$($ctxt.Text)\$($utxt.Text)"
                $console.Text += "

                PoSH_Console $((pwd).path)> executed on target

                [result]:$_

                "
                
            } catch {
                $console.Text += "

                PoSH_Console $((pwd).path)> Error to execute on target 
                
                [result]:$_
                "
            
            }
        })
        $tmpfrm.Controls.Add($psrem)

        $tpass = New-Object System.Windows.Forms.TextBox
        $tpass.Location = New-Object System.Drawing.Size(20,75)
        $tpass.Size = $utxt.Size
        $tpass.BackColor = 'tan'
        $tpass.UseSystemPasswordChar = $true
        $tmpfrm.Controls.Add($tpass)

        $ranas = New-Object System.Windows.Forms.Button
        $ranas.Location = New-Object System.Drawing.Size(125,75)
        $ranas.Size = New-Object System.Drawing.Size(100,22)
        $ranas.Text = "Open PoSH"
        $ranas.add_click({
                function Run-As ($cmd, $username, $password, $domain, $arrg ) {
        try{
            $startinfo = new-object System.Diagnostics.ProcessStartInfo
            $startinfo.Arguments = $arrg
            $startinfo.FileName = $cmd
            $startinfo.UseShellExecute = $false

            if(-not ($ShowWindow)) {
                $startinfo.CreateNoWindow = $True
                $startinfo.WindowStyle = "Hidden"
            }
            
            if($UserName) {
                $startinfo.UserName = $username
                $sec_password = convertto-securestring $password -asplaintext -force
                $startinfo.Password = $sec_password
                $startinfo.Domain = $domain
            }
            
            [System.Diagnostics.Process]::Start($startinfo) | out-null
            "1"
        }
        catch {
            "0"
        }

    }
            $errlvl = Run-As -username $($utxt.Text) -domain $($ctxt.Text) -password $($tpass.Text) -cmd "cmd" -arrg "/c start powershell"
            if ($errlvl)
            {
                if ($errlvl -eq 1)
                {
                    $console.Text += "

                PoSH_Console $((pwd).path)> Posh shell opened
                "
                } elseif ($errlvl -eq 0)
                {
                    $console.Text += "

                PoSH_Console $((pwd).path)> Error to open PoSH on target 
                "
                }
            }
        })
        $tpass.Text = "P@`$sW0rd"
        $tmpfrm.Controls.Add($ranas)
        $tmpfrm.ShowDialog()
    })
 $run.Controls.Add($html)

 $bat = New-Object System.Windows.Forms.Button
 $bat.Text = "run in console interactive"
 $bat.Location = New-Object System.Drawing.Size(20,80)
 $bat.Size = New-Object System.Drawing.Size(210,30)
 $bat.add_click({
        Start-Job -ScriptBlock ([scriptblock]::Create($($rtr.Text))) -Name some |Out-Null
            Wait-Job -Name some |Out-Null
            $console.Text += "

PoSH_Console $((pwd).path)> Running... 
                "
            
            foreach ($tmp in $(Receive-Job -Name some 2>&1|Out-String))
            {
                $console.Text += "$tmp" + "
                "
            }
            Get-Job |Remove-Job
            if (($rtr.Text -ieq "cls") -or ($rtr.Text -ieq "clear"))
            {
                $console.Text = "Powershell interactive console
        
"
            }
        })
 $run.Controls.Add($bat)
 $run.ShowDialog()

}


function save ($initialDirectory)
{
 [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") |  Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.SaveFileDialog
 #$OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = "Any files| *.*|text|*.txt|batch files|*.bat|PowerShell Script|*.ps1|Hyper Text MarkUp Language|*.html"
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
}

function mksave ()
{
 $tosave = save -initialDirectory $env:USERPROFILE\BAK.PS1
 
  Set-Content $tosave $rtr.text
 
}

function compiler
{
    $cfrm = New-Object System.Windows.Forms.Form
    $cfrm.Text = "Compile"
    $cfrm.FormBorderStyle = 'fixedtoolwindow'
    $cfrm.Size = New-Object System.Drawing.Size(400,400)
    
    $runl = New-Object System.Windows.Forms.Label
    $runl.Location = New-Object System.Drawing.Size(20,0)
    $runl.Text = "Runtime:"
    $runl.Size = New-Object System.Drawing.Size(55,20)
    $cfrm.Controls.Add($runl)

    $runlst = New-Object System.Windows.Forms.ListBox
    $runlst.Location = New-Object System.Drawing.Size(20,20)
    $runlst.Size = New-Object System.Drawing.Size(100,70)
    $runlst.SelectionMode = 'One'
    [void] $runlst.Items.Add("runtime20")
    [void] $runlst.Items.Add("runtime30")
    [void] $runlst.Items.Add("runtime40")
    [void] $runlst.Items.Add("default")
    $runlst.SelectedItem = "default"
    $cfrm.Controls.Add($runlst)

    $artl = New-Object System.Windows.Forms.Label
    $artl.Text = "OS arctecture:"
    $artl.Size = New-Object System.Drawing.Size(80,20)
    $artl.Location = New-Object System.Drawing.Size(150,0)
    $cfrm.Controls.Add($artl)

    $artlst = New-Object System.Windows.Forms.ListBox
    $artlst.Location = New-Object System.Drawing.Size(150,20)
    $artlst.Size = New-Object System.Drawing.Size(100,50)
    $artlst.SelectionMode = 'One'
    [void] $artlst.Items.Add("x86")
    [void] $artlst.Items.Add("x64")
    [void] $artlst.Items.Add("Default")
    $artlst.SelectedItem = "Default"
    $cfrm.Controls.Add($artlst)
    
    $iconl = New-Object System.Windows.Forms.Label
    $iconl.Location = New-Object System.Drawing.Size(20,110)
    $iconl.Text = "Icon:"
    $iconl.Size = New-Object System.Drawing.Size(30,20)
    $cfrm.Controls.Add($iconl)
    
    $icontxt = New-Object System.Windows.Forms.TextBox
    $icontxt.Location = New-Object System.Drawing.Size(50,110)
    $icontxt.ReadOnly = $true
    $icontxt.Size = New-Object System.Drawing.Size(104,0)
    $cfrm.Controls.Add($icontxt)

    $iconbrw = New-Object System.Windows.Forms.Button
    $iconbrw.Location = New-Object System.Drawing.Size(155,110)
    $iconbrw.Text = "Browse"
    $iconbrw.Size = New-Object System.Drawing.Size(50,22)
    $iconbrw.FlatStyle = 'system'
    $iconbrw.add_click({
        $obj = New-Object System.Windows.Forms.OpenFileDialog
        $obj.Filter = "Icon|*.ico"
        $obj.ShowDialog()
        if ($obj.FileName)
        {
            if (Test-Path $($obj.FileName))
            {
                $icontxt.Text = $obj.FileName
            }
        }
    })
    $cfrm.Controls.Add($iconbrw)

    $scrl = New-Object System.Windows.Forms.Label
    $scrl.Location = New-Object System.Drawing.Size(20,140)
    $scrl.Text = "Script:"
    $scrl.Size = New-Object System.Drawing.Size(55,20)
    $cfrm.Controls.Add($scrl)

    $scrtxt = New-Object System.Windows.Forms.TextBox
    $scrtxt.Location = New-Object System.Drawing.Size(75,140)
    $scrtxt.ReadOnly = $true
    $scrtxt.Size = $icontxt.Size
    $cfrm.Controls.Add($scrtxt)

    $scrbrw = New-Object System.Windows.Forms.Button
    $scrbrw.Location = New-Object System.Drawing.Size(175,140)
    $scrbrw.Size = $iconbrw.Size
    $scrbrw.Text = "Browse"
    $scrbrw.add_click({
        $obj = New-Object System.Windows.Forms.SaveFileDialog
        $obj.Filter = "PoSH script|*.ps1"
        $obj.ShowDialog()
        if ($obj.FileName)
        {
            if (Test-Path $($obj.FileName))
            {
                $scrtxt.Text = $obj.FileName
            }
        }
    })
    $cfrm.Controls.Add($scrbrw)

    $tarl = New-Object System.Windows.Forms.Label
    $tarl.Location = New-Object System.Drawing.Size(20,175)
    $tarl.Text = "target:"
    $tarl.Size = New-Object System.Drawing.Size(55,20)
    $cfrm.Controls.Add($tarl)

    $tartxt = New-Object System.Windows.Forms.TextBox
    $tartxt.Location = New-Object System.Drawing.Size(75,175)
    $tartxt.ReadOnly = $true
    $tartxt.Size = $icontxt.Size
    $cfrm.Controls.Add($tartxt)

    $tarbrw = New-Object System.Windows.Forms.Button
    $tarbrw.Location = New-Object System.Drawing.Size(175,175)
    $tarbrw.Size = $iconbrw.Size
    $tarbrw.Text = "Browse"
    $tarbrw.add_click({
        $obj = New-Object System.Windows.Forms.SaveFileDialog
        $obj.Filter = "Executable|*.exe"
        $obj.ShowDialog()
        if ($obj.FileName)
        {
            if (Test-Path $($obj.FileName))
            {
                $tartxt.Text = $obj.FileName
            }
        }

    })
    $cfrm.Controls.Add($tarbrw)

    $nconsole = New-Object System.Windows.Forms.CheckBox
    $nconsole.Text = "No console"
    $nconsole.Location = New-Object System.Drawing.Size(20,235)
    $nconsole.Checked = $false
    $cfrm.Controls.Add($nconsole)

    $compile = New-Object System.Windows.Forms.Button
    $compile.Location = New-Object System.Drawing.Size(20,205)
    $compile.Text = "Compile"
    $compile.FlatStyle = 'flat'
    $compile.add_click({
        if ($nconsole.Checked)
        {
            $con = "-noconsole"
        } else {
            $con = $null
        }
        if (!$artlst.SelectedItem -eq "Default")
        {
            $arc = Write-Output "-$($artlst.SelectedItem)"
        } else {
            $arc = $null
        }
        if (!$runlst.SelectedItem -eq "default")
        {
            $run = Write-Output "-$($runlst.SelectedItem)"
        } else {
            $run = $null
        }
        if ($icontxt.Text)
        {
            $ico = Write-Output "-iconFile $($icontxt.Text)"
        } else {
            $ico = $null
        }
        $console.Text += "

PoSH_Console $((pwd).path)> compiling
                "
        $console.text += "
        $(
            compile -inputFile $($scrtxt.Text) -outputFile $($tartxt.Text) $con $ico $run $arc
        
        )
        "
    })
    $cfrm.Controls.Add($compile)
    $cfrm.ShowDialog()
}

function font () 
{
 $font = New-Object System.Windows.Forms.Form
 $font.Size = New-Object System.Drawing.Size(300,200)
 $font.MaximizeBox = $false
 $font.MaximumSize = New-Object System.Drawing.Size(300,200)
 $font.MinimizeBox = $false
 #$font.Icon = New-Object System.Drawing.Icon('C:\Users\naty\Pictures\icons\icon13.ico')
 $font.MinimumSize = New-Object System.Drawing.Size(300,200)
 $font.Text = "font"
 $font.ControlBox = $false
 $font.FormBorderStyle = 'fixed3D'
 $font.BackColor = "darkgray"
 $font.ForeColor = "black"

 $flist = New-Object System.Windows.Forms.ListBox
 $flist.SelectionMode = 'one'
 $flist.BackColor = "gray"
 $flist.ForeColor = "white"
 $selected = $rtr.Font.Name
 $flist.Location = New-Object System.Drawing.Size(1,10)
 $flist.Size = New-Object System.Drawing.Size(100,100)
 foreach ($tmp in ([System.Drawing.FontFamily]::Families).name)
 {
    [void] $flist.Items.Add("$tmp")
 }
 $flist.SelectedItem = $selected
 $font.Controls.Add($flist)

 $fsize = New-Object System.Windows.Forms.ListBox
 $fsize.SelectionMode = 'one'
 $fsize.BackColor = "gray"
 $fsize.ForeColor = "white"
 $sislct = $rtr.Font.Size
 $fsize.Location = New-Object System.Drawing.Size(120,10)
 $fsize.size = New-Object System.Drawing.Size(70,100)
 $i = 0
 while ($i -lt 90)
 {
  $i=$i+1
  [void] $fsize.Items.Add("$i")
 }
 $fsize.SelectedItem = "11" 
 $font.controls.Add($fsize)

 $fk = New-Object System.Windows.Forms.Button
 $fk.Text = "Apply"
 $fk.Size = New-Object System.Drawing.Size(60,20)
 $fk.Location = New-Object System.Drawing.Size(185,130)
 $fk.add_click({
    $fnt = $flist.SelectedItem
    $fnts = $fsize.SelectedItem
    $rtr.Font = New-Object System.Drawing.Font("$fnt", $fnts)    
    })

 $font.Controls.Add($fk)
 $fo = New-Object System.Windows.Forms.Button
 $fo.Text = "Ok"
 $fo.Size = New-Object System.Drawing.Size(60,20)
 $fo.Location = New-Object System.Drawing.Size(35,130)
 $fo.add_click({
    $fnt = $flist.SelectedItem
    $fnts = $fsize.SelectedItem
    $rtr.Font = New-Object System.Drawing.Font("$fnt", $fnts)
     "$fnt recrce"
    $font.Close()
    })
 $fc = New-Object System.Windows.Forms.Button
 $fc.Text = "Cancel"
 $fc.Size = New-Object System.Drawing.Size(60,20)
 $fc.Location = New-Object System.Drawing.Size(110,130)
 $fc.add_click({
    $font.Close()
    
    })

 $font.Controls.Add($fc)
 $font.Controls.Add($fo)
 $bold = New-Object System.Windows.Forms.Button
 $bold.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",9 , [System.Drawing.FontStyle]::Bold)
 $bold.Text = "Bold"
 $bold.Location  = New-Object System.Drawing.Size(210,10)
 $bold.Size = New-Object System.Drawing.Size(60,30)
 $bold.add_click({
        $bldstyle = $rtr.Font = New-Object System.Drawing.Font($rtr.Font.FontFamily, $rtr.Font.Size ,[System.Drawing.FontStyle]::Bold)
        })
 $font.Controls.Add($bold)
 
 $italy = New-Object System.Windows.Forms.Button
 $italy.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",10 , [System.Drawing.FontStyle]::Italic)
 $italy.Text = "italic"
 $italy.Location  = New-Object System.Drawing.Size(210,45)
 $italy.Size = New-Object System.Drawing.Size(60,30)
 $italy.add_click({
        $rtr.Font = New-Object System.Drawing.Font($rtr.Font.FontFamily, $rtr.Font.Size ,[System.Drawing.FontStyle]::italic)
        })
 $font.Controls.Add($italy)

 $und = New-Object System.Windows.Forms.Button
 $und.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",8 , [System.Drawing.FontStyle]::Underline)
 $und.Text = "underline"
 $und.Location  = New-Object System.Drawing.Size(210,80)
 $und.Size = New-Object System.Drawing.Size(60,30)
 $und.add_click({
        $rtr.Font = New-Object System.Drawing.Font($rtr.Font.FontFamily, $rtr.Font.Size ,[System.Drawing.FontStyle]::Underline)
        })
 $font.Controls.Add($und)
 $font.ShowDialog()
}

function add-menu ()
{
 $menu = New-Object System.Windows.Forms.MenuStrip
 $menu.Location = New-Object System.Drawing.Size(100,1)
 $menu.Size = New-Object System.Drawing.Size(140,30)
 $frm.Controls.Add($menu)
 $m1 = New-Object System.Windows.Forms.ToolStripMenuItem
 $m1.Text = "open"
$m1.add_click({
    $rt = brwse -initialDirectory $env:USERPROFILE
    $bt = $rt.text
    $frm.Size = New-Object System.Drawing.Size(900,700)
    $frm.Text = "write pad - $rt"
    $frm.MaximizeBox = $true
    $frm.MinimizeBox = $true
    $frm.ControlBox = $true
    $exist = Test-Path $rt
    if ($exist -eq $true)
    {
     $i=0
     $rtr.Text = ""
     $rtrt = ""
     foreach ($cont in Get-Content $rt) 
     {
      
      $rtr.Text = "$rtrt
 $cont"
      $i=$i+1
      $rtrt = $rtr.Text
     }
     }

})



}
$rtr = New-Object System.Windows.Forms.TextBox
        $rtr.AcceptsReturn = $true
        $rtr.Multiline = $true
        $rtr.ScrollBars = "both"
        $rtr.AcceptsTab = $true
        $rtr.BackColor = "white"
        $Rtr.Anchor = "bottom"
        $rtr.TabIndex = $true
        $rtr.BackgroundImageLayout = "zoom"
        $rtr.BorderStyle = "none"
        $rtr.Font = New-Object System.Drawing.Font("lucida console", 11)
        $rtr.add_keydown({
            if ($_.KeyCode -eq "shift")
            {
             $rtr.ForeColor = "blue"
            }
        })
        $rtr.WordWrap = $false
        $rtr.AutoSize = $true
        $rtr.ForeColor = "black"
        $rtr.location = New-Object System.Drawing.Size(30,25)
        $rtr.Size = New-Object System.Drawing.Size(850,435)
        $frm.Controls.Remove($brw)
        $rtr.ReadOnly = $false
        $frm.Controls.Add($rtr)
        $console = New-Object System.Windows.Forms.TextBox
        $console.location = New-Object System.Drawing.Size(1,460)
        $console.Multiline = $true
        $console.ScrollBars = 'both'
        $console.Size = New-Object System.Drawing.Size(885,175)
        $console.ForeColor = 'limegreen'
        $console.ReadOnly = $true
        $console.Text = "Powershell interactive console
        
"
        $console.Font = New-Object System.Drawing.Font('lucida console', 10)
        $console.BackColor = "Darkblue"
        $frm.Controls.Add($console)
        $prompt = New-Object System.Windows.Forms.TextBox
        $prompt.location = New-Object System.Drawing.Size(1,635)
        $prompt.ScrollBars = 'both'
        $prompt.Size = New-Object System.Drawing.Size(800,175)
        $prompt.ForeColor = 'limegreen'
        $prompt.Font = New-Object System.Drawing.Font('lucida console', 10)
        $prompt.BackColor = "darkblue"
        $frm.Controls.Add($prompt)
        $inv = New-Object System.Windows.Forms.Button
        $inv.Location = New-Object System.Drawing.Size(801,635)
        $inv.Size = New-Object System.Drawing.Size(65,21)
        $inv.Text = "invoke"
        $inv.add_click({
            Start-Job -ScriptBlock ([scriptblock]::Create($($prompt.Text))) -Name some |Out-Null
            Wait-Job -Name some |Out-Null
            $console.Text += "

PoSH_Console $((pwd).path)> $($prompt.Text) 
                "
            
            foreach ($tmp in $(Receive-Job -Name some 2>&1|Out-String))
            {
                $console.Text += "$tmp" + "
"
            }
            Get-Job |Remove-Job
            if (($prompt.Text -ieq "cls") -or ($prompt.Text -ieq "clear"))
            {
                $console.Text = "Powershell interactive console

"
            }
            $prompt.Text = $null
        })
        $frm.Controls.Add($inv)



Function brwse($initialDirectory)
{
 [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") |  Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = "Any files| *.*|text|*.txt|batch files|*.bat|PowerShell Script|*.ps1|Hyper Text MarkUp Language|*.html"
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
}

Function sav($initialDirectory)
{
 [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") |  Out-Null

 $OpenFilDialog = New-Object System.Windows.Forms.SaveFileDialog
 $OpenFilDialog.ShowDialog() | Out-Null
 $OpenFilDialog.filename
}

 $m1 = New-Object System.Windows.Forms.ToolStripMenuItem
 $m1.Text = "open"
 $m1.add_click({
      add-brmenu
     })

$edifrm = New-Object System.Windows.Forms.Form
$edifrm.text = "write pad - $rt"
$edifrm.MinimizeBox = $true
$edifrm.MaximizeBox = $true
$edifrm.ControlBox = $true
function add-brmenu () 
{
 $menu = New-Object System.Windows.Forms.MenuStrip
 $menu.Location = New-Object System.Drawing.Size(100,1)
 $menu.Size = New-Object System.Drawing.Size(140,30)

 $frm.Controls.Add($menu)
 $m1.add_click({
    $rt = brwse -initialDirectory $env:USERPROFILE
    $bt = $rt.text
    $frm.Size = New-Object System.Drawing.Size(900,700)
    $frm.Text = "write pad - $rt"
    $frm.MaximizeBox = $true
    $frm.MinimizeBox = $true
    $frm.ControlBox = $true
    $exist = Test-Path $rt
    if ($exist -eq $true)
    {
     $frm.Text = "Write pad - $rt"
     $rtrt = ""
     foreach ($cont in Get-Content $rt) 
     {
      $rtr.Text = "$rtrt
$cont"
      $rtrt = $rtr.Text
     }

     $sav = New-Object System.Windows.Forms.Button
     $sav.Text = "save as"
     $sav.Location = New-Object System.Drawing.Size(5,3)
     $sav.Size = New-Object System.Drawing.Size(10,30)
     $sav.add_click({
           mksave
           $init = "$rtr.Text"
            "ayayyayaay ,,,,,,,,,,,,, $init ,,,,,,,,,,,,,,"
            "$rtr.text" |Out-File $sv
           })
     $frm.Controls.Add($sav)
     
    }
    })

 $menu.Items.Add($m1)
 $menu.BackColor = 'darkgray'
 $m2 = New-Object System.Windows.Forms.ToolStripMenuItem
 $m2.Text = "save"
  if ($rtr.Text -eq $null)
 {
  $m2.Enabled = $false
 } else {
         $m2.Enabled = $true
        }
 $m2.add_click({
        Set-Content $env:USERPROFILE/saved.txt $rtr.text
     })
 $menu.Items.Add($m2)
 $m3 = New-Object System.Windows.Forms.ToolStripMenuItem
 $m3.Text = "save as"
  if ($rtr.Text -eq $null)
 {
  $m3.Enabled = $false
 } else {
         $m3.Enabled = $true
        }
 $m3.add_click({
      mksave
     })
 $menu.Items.Add($m3)
 
 $m5 = New-Object System.Windows.Forms.ToolStripMenuItem
 $m5.Text = "font"
  if ($rtr.Text -eq $null)
 {
  $m5.Enabled = $false
 } else {
         $m5.Enabled = $true
        }
 $m5.add_click({
      font
     })
 $menu.Items.Add($m5)
 $mstyle = New-Object System.Windows.Forms.ToolStripMenuItem
 $mstyle.Text = "Style"
 $mstyle.add_click({
    style
 })
 $menu.Items.Add($mstyle)
 $m6 = New-Object System.Windows.Forms.ToolStripMenuItem
 $m6.Text = "run" 
 if ($rtr.Text -eq $null)
 {
  $m6.Enabled = $false
 } else {
         $m6.Enabled = $true
        }
 $m6.add_click({
      runas
     })
 $menu.Items.Add($m6)
 $m7 = New-Object System.Windows.Forms.ToolStripMenuItem
 $m7.Text = "compile"
 if ($rtr.Text -eq $null)
 {
  $m7.Enabled = $false
 } else {
         $m7.Enabled = $true
        }
 $m7.add_click({
      compiler
     })
  $menu.Items.Add($m7)
 $m10 = New-Object System.Windows.Forms.ToolStripMenuItem
 $m10.Text = "clone"
 $m10.add_click({
        web;
        })
 $menu.Items.Add($m10) 
 $m11 = New-Object System.Windows.Forms.ToolStripMenuItem
 $m11.Text = "share"
 $m11.add_click({
        share;
        })
 $menu.Items.Add($m11)
 
 }

$linec = New-Object System.Windows.Forms.TextBox
$linec.Location = New-Object System.Drawing.Size(0,25)
$linec.Size = New-Object System.Drawing.Size(30,800)
$linec.Text = "$(. .\count;$lines)"
$linec.Enabled = $false
$linec.ReadOnly = $true
$linec.Font = $rtr.Font
$linec.Multiline = $true
$frm.Controls.Add($linec)
add-brmenu



$frm.Add_KeyDown({
    write-host "
    ===============
    $($_.keycode)
    =============="
    if ($_.KeyCode -eq "Return")
    {
        Write-Host "hehehe$($rtr.Lines.Count) is it $lines"
        if (!($rtr.Lines.Count -le $lines))
        {
            Write-Host "sdjjds"
            . .\count.ps1
            Write-Host $i
            $b=$lines+1
            Write-Host $i
        
        $linec.Text += "
$b"
        "`$lines=$b">.\count.ps1
        Write-Host "$(cat .\count.ps1) $lines"
        }
    } elseif ($_.KeyCode -eq "Back")
    {
        Write-Host "$($linec.Lines.Count)is gt $($rtr.Lines.Count)"
        if ($($linec.Lines.Count) -gt $rtr.Lines.Count)
        {
            
            $b = 0
            $i=0
            $linec.Text = $null
            while ($i -le $rtr.Lines.Count)
            {
                if ($i -eq 0)
                {
                    $linec.Text += $i
                } else { 
                    $linec.Text += "
$i"
                }
                $i++
                $b++
            }
            
            "`$lines=$b">.\count.ps1
        }

    }
    
})


$frm.ShowDialog()

"`$lines = 0">count.ps1
