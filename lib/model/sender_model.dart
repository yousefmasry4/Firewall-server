
class SenderModel{
  final String? sourceIP;
  final int? mask,sourcePort;
  final Flag? flag;
  bool ans=false;

  SenderModel({this.sourceIP,this.mask, this.sourcePort, this.flag});
}
enum Flag{
  Start,Continue,End
}