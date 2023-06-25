{

  https://github.com/wanips7/SteamServerBlocker

}

unit uServerBlocker;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Diagnostics,
  System.Generics.Collections, System.JSON, System.Net.HttpClient, System.Win.ComObj,
  Winapi.ActiveX, System.JSON.Serializers, REST.Json, System.IOUtils;

type
  TRelay = record
    IPv4: string;
    PortRange: TArray<Word>;
  end;

type
  TRelayList = TArray<TRelay>;

type
  PServerData = ^TServerData;
  TServerData = record
    Name: string;
    RelayList: TRelayList;
    Ping: Integer;
    IsBlocked: Boolean;
  end;

type
  TServerBlocker = class
  private
    class procedure SetIsBlocked(const List: TList<TServerData>; Value: Boolean); static;
  public
    class procedure Block(const ServerData: PServerData); overload; static;
    class procedure Block(const List: TList<TServerData>); overload; static;
    class procedure Unblock(const ServerData: PServerData); overload; static;
    class procedure Unblock(const List: TList<TServerData>); overload; static;
  end;

type
  TServerDataUpdater = class
  private const
    NETWORK_CONFIG_URL = 'https://api.steampowered.com/ISteamApps/GetSDRConfig/v1?appid=730';
    DEFAULT_TIMEOUT = 1000;
  private
    FHttpClient: THTTPClient;
    FList: TList<TServerData>;
  public
    property List: TList<TServerData> read FList;
    constructor Create;
    destructor Destroy; override;
    procedure Update;
    procedure LoadFromFile(const FileName: string);
    procedure SaveToFile(const FileName: string);
    procedure PingServers;
    function GetServerDataByName(const Name: string; out Output: PServerData): Boolean;
  end;

implementation

uses
  uPing;

type
  TFirewallRules = class
  private const
    NET_FW_PROFILE2_DOMAIN  = 1;
    NET_FW_PROFILE2_PRIVATE = 2;
    NET_FW_PROFILE2_PUBLIC  = 4;
    NET_FW_IP_PROTOCOL_TCP = 6;
    NET_FW_IP_PROTOCOL_UDP = 17;
    NET_FW_IP_PROTOCOL_ICMPv4 = 1;
    NET_FW_IP_PROTOCOL_ICMPv6 = 58;
    NET_FW_RULE_DIR_IN = 1;
    NET_FW_RULE_DIR_OUT = 2;
    NET_FW_ACTION_BLOCK = 0;
    NET_FW_ACTION_ALLOW = 1;
    FIREWALL_NAME_PREFIX = 'SteamServerBlocker_';
  public
    class procedure Add(const Caption, Ip: String); static;
    class procedure Remove(const Name: string); static;
    class procedure RemoveAll; static;
  end;

{ TServerBlocker }

class procedure TServerBlocker.SetIsBlocked(const List: TList<TServerData>; Value: Boolean);
var
  P: PServerData;
  i: Integer;
begin
  if List.Count > 0 then
    for i := 0 to List.Count - 1 do
    begin
      P := @List.List[i];
      P.IsBlocked := Value;

      if Value then
        Block(P);
    end;
end;

class procedure TServerBlocker.Block(const ServerData: PServerData);
var
  IpList: string;
  Relay: TRelay;
begin
  if ServerData.IsBlocked then
    Exit;

  ServerData.IsBlocked := True;

  IpList := '';

  for Relay in ServerData.RelayList do
  begin
    IpList := IpList + Relay.IPv4 + ',';
  end;

  if IpList.Length > 0 then
    SetLength(IpList, IpList.Length - 1);

  TFirewallRules.Add(ServerData.Name, IpList);
end;

class procedure TServerBlocker.Block(const List: TList<TServerData>);
var
  P: PServerData;
  i: Integer;
begin
  if List.Count > 0 then
    for i := 0 to List.Count - 1 do
    begin
      P := @List.List[i];
      Block(P);
    end;
end;

class procedure TServerBlocker.Unblock(const ServerData: PServerData);
begin
  ServerData.IsBlocked := False;

  TFirewallRules.Remove(ServerData.Name);
end;

class procedure TServerBlocker.Unblock(const List: TList<TServerData>);
begin
  SetIsBlocked(List, False);

  TFirewallRules.RemoveAll;
end;

{ TServerDataUpdater }

constructor TServerDataUpdater.Create;
begin
  FHttpClient := THTTPClient.Create;
  FList := TList<TServerData>.Create;
end;

destructor TServerDataUpdater.Destroy;
begin
  FHttpClient.Free;
  FList.Free;

  inherited;
end;

function TServerDataUpdater.GetServerDataByName(const Name: string; out Output: PServerData): Boolean;
var
  i: Integer;
begin
  Result := False;

  if FList.Count > 0 then
    for i := 0 to FList.Count - 1 do
    begin
      Output := @FList.List[i];

      if Output.Name = Name then
      begin
        Result := True;
        Break;
      end;
    end;

end;

procedure TServerDataUpdater.LoadFromFile(const FileName: string);
var
  Text: string;
begin
  if FileExists(FileName) then
  begin
    Text := TFile.ReadAllText(FileName);

    FList.Free;
    FList := TJson.JsonToObject<TList<TServerData>>(Text);
  end;
end;

procedure TServerDataUpdater.PingServers;
var
  P: PServerData;
  i: Integer;
  Host: string;
begin
  if FList.Count > 0 then
    for i := 0 to FList.Count - 1 do
    begin
      P := @FList.List[i];
      Host := P.RelayList[0].IPv4;

      P.Ping := PingHost(Host, DEFAULT_TIMEOUT);
    end;

end;

procedure TServerDataUpdater.SaveToFile(const FileName: string);
var
  Text: string;
begin
  Text := TJson.ObjectToJsonString(FList);

  TFile.WriteAllText(FileName, Text);

end;

procedure TServerDataUpdater.Update;
var
  Response: IHttpResponse;
  Json: TJSONValue;
  Item: TJSONValue;
  JsonArray: TJSONArray;
  i: Integer;
  Pops: TJSONObject;
  ServerData: TServerData;
  Relay: TRelay;
  HasGameServers: Boolean;
begin
  TFirewallRules.RemoveAll;

  FList.Clear;

  Response := FHttpClient.Get(NETWORK_CONFIG_URL);

  if Response.StatusCode = 200 then
  begin
    Json := TJSONObject.ParseJSONValue(Response.ContentAsString);

    try
      Pops := Json.GetValue<TJSONObject>('pops');

      if Pops.Count > 0 then
        for i := 0 to Pops.Count - 1 do
        begin
          Item := Pops.Pairs[i].JsonValue;

          ServerData := Default(TServerData);

          if not Item.TryGetValue<string>('desc', ServerData.Name) then
            Continue;

          if not Item.TryGetValue<TJSONArray>('relays', JsonArray) then
            Continue;

          for Item in JsonArray do
          begin
            Relay := Default(TRelay);
            Relay.IPv4 := Item.GetValue<string>('ipv4');
            Relay.PortRange := Item.GetValue<TArray<Word>>('port_range');

            ServerData.RelayList := ServerData.RelayList + [Relay];
          end;

          FList.Add(ServerData);
        end;

    finally
      Json.Free;
    end;

  end;
end;

{ TFirewallRules }

class procedure TFirewallRules.Add(const Caption, Ip: String);
var
  Profile: Integer;
  Policy2: OleVariant;
  RuleObject: OleVariant;
  NewRule: OleVariant;
begin
  Profile := NET_FW_PROFILE2_PRIVATE or NET_FW_PROFILE2_PUBLIC;
  Policy2 := CreateOleObject('HNetCfg.FwPolicy2');
  RuleObject := Policy2.Rules;
  NewRule := CreateOleObject('HNetCfg.FWRule');
  NewRule.Name := FIREWALL_NAME_PREFIX + Caption;
  NewRule.Description := '';
  NewRule.ApplicationName := '';
  NewRule.Protocol := NET_FW_IP_PROTOCOL_UDP;
  NewRule.Enabled := True;
  Newrule.RemoteAddresses := Ip;
  NewRule.Grouping := Caption;
  NewRule.Profiles := Profile;
  NewRule.Action := NET_FW_ACTION_BLOCK;
  Newrule.Direction := NET_FW_RULE_DIR_OUT;
  RuleObject.Add(NewRule);
end;

class procedure TFirewallRules.Remove(const Name: string);
var
  CurrentProfiles : Integer;
  fwPolicy2: OleVariant;
  RulesObject: OleVariant;
  rule: OleVariant;
  oEnum: IEnumvariant;
  iValue: LongWord;
begin
  fwPolicy2 := CreateOleObject('HNetCfg.FwPolicy2');
  RulesObject := fwPolicy2.Rules;
  CurrentProfiles := fwPolicy2.CurrentProfileTypes;
  oEnum := IUnknown(RulesObject._NewEnum) as IEnumvariant;
  while oEnum.Next(1, rule, iValue) = 0 do
  begin
    if (rule.Profiles And CurrentProfiles) <> 0 then
    begin
      if (rule.Name = FIREWALL_NAME_PREFIX + Name) then
        RulesObject.Remove(rule.Name);
    end;
  end;
end;

class procedure TFirewallRules.RemoveAll;
var
  CurrentProfiles : Integer;
  fwPolicy2: OleVariant;
  RulesObject: OleVariant;
  rule: OleVariant;
  oEnum: IEnumvariant;
  iValue: LongWord;
begin
  fwPolicy2 := CreateOleObject('HNetCfg.FwPolicy2');
  RulesObject := fwPolicy2.Rules;
  CurrentProfiles := fwPolicy2.CurrentProfileTypes;
  oEnum := IUnknown(RulesObject._NewEnum) as IEnumvariant;
  while oEnum.Next(1, rule, iValue) = 0 do
  begin
    if (rule.Profiles And CurrentProfiles) <> 0 then
    begin
      if string(rule.Name).StartsWith(FIREWALL_NAME_PREFIX) then
        RulesObject.Remove(rule.Name);
    end;
  end;
end;



end.
