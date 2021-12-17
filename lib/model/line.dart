// <verb> <prefix> <port> [modifier]
//
// Where:
//
//  <verb> is either "block" or "allow" (without the quotes),
//  <prefix> is a dotted quad (e.g., 1.2.3.4) always followed by a length.
//  <port> is an integer.
//  [modifier] is optional parameter; the only legal value is "established".

class Line {
   verbs verb;
   String? ip;
   int? mask, port;
   bool modifier;
   bool? allIp, allPorts;

  Line(
      {required this.verb,
      this.ip,
      this.mask,
      this.port,
      required this.modifier,
      this.allIp,
      this.allPorts});

  @override
  String toString() {
    return "{"
        "$verb , $ip, $mask, $port} ";

  }
}

enum verbs { block, allow }
