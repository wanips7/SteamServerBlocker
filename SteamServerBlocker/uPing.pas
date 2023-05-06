{

  https://github.com/wanips7/SteamServerBlocker

}

unit uPing;

interface

uses
  Winapi.Windows, System.SysUtils, Winapi.WinSock2;

const
  NOT_RESPONDING = -1;

function PingHost(const HostName: AnsiString; const SendData: string; Timeout: Cardinal): Integer; overload;
function PingHost(const HostName: AnsiString; Timeout: Cardinal): Integer; overload;

implementation

const
  IPHLPAPI_LIB = 'iphlpapi.dll';

type
  ip_option_information = packed record
    Ttl: Byte;
    Tos: Byte;
    Flags: Byte;
    OptionsSize: Byte;
    OptionsData: Pointer;
  end;

type
  PIcmpEchoReply = ^TIcmpEchoReply;
  TIcmpEchoReply = packed record
    Address: in_addr;
    Status: DWORD;
    RoundTripTime: DWORD;
    DataSize: u_short;
    Reserved: u_short;
    Data: Pointer;
    Options: ip_option_information;
  end;

function IcmpCreateFile:THandle; stdcall; external IPHLPAPI_LIB;
function IcmpCloseHandle(icmpHandle: THandle): boolean; stdcall; external IPHLPAPI_LIB;
function IcmpSendEcho(IcmpHandle: THandle; DestinationAddress: In_Addr; RequestData:Pointer;
  RequestSize: Smallint; RequestOptions: Pointer; ReplyBuffer: Pointer; ReplySize: DWORD;
  Timeout: DWORD): DWORD; stdcall; external IPHLPAPI_LIB;

function PingHost(const HostName: AnsiString; const SendData: string; Timeout: Cardinal): Integer;
var
  ICMPFile: THandle;
  IpAddress: In_Addr;
  ReplyBuffer: PIcmpEchoReply;
  ReplySize: DWORD;
  RequestSize: SmallInt;
begin
  Result := NOT_RESPONDING;

  if Length(SendData) = 0 then
    raise EArgumentException.Create('Send data is empty.');

  if Timeout = 0 then
    raise EArgumentException.Create('Timeout value must be greater than zero.');

  RequestSize := Length(SendData) * SizeOf(SendData[1]);
  ReplySize := SizeOf(TIcmpEchoReply) + RequestSize;

  IpAddress.S_addr := inet_addr(PAnsiChar(HostName));

  IcmpFile := IcmpCreateFile;
  if IcmpFile <> INVALID_HANDLE_VALUE then
  begin
    try
      GetMem(ReplyBuffer, SizeOf(TIcmpEchoReply) + RequestSize);
      try
        if IcmpSendEcho(IcmpFile, IpAddress, PChar(SendData), RequestSize, nil,
          ReplyBuffer, ReplySize, Timeout) <> 0 then
        begin
          Result := ReplyBuffer.RoundTripTime;
        end;

      finally
        FreeMem(ReplyBuffer);
      end;

    finally
      IcmpCloseHandle(IcmpFile);
    end

  end
    else
  begin
    RaiseLastOSError;
  end;

end;

function PingHost(const HostName: AnsiString; Timeout: Cardinal): Integer;
begin
  Result := PingHost(HostName, 'Ping', Timeout);
end;

end.
