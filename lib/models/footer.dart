import 'package:footer/footer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AllenAppFooter extends Footer {
  final String locale;
  final bool isEnglishUS;

  @override
  AllenAppFooter({
    required this.locale,
    required this.isEnglishUS,
    super.alignment,
    super.backgroundColor,
    super.padding,
  }): super(child: Text(''));

  @override
  State createState() => AllenAppFooterState();
}

class AllenAppFooterState extends State<AllenAppFooter> {

  @override
  Widget build(BuildContext context) {
    var iconcode = ((widget.locale ?? '').contains('EN') ? (widget.locale == 'EN' ? 'us' : 'gb') : widget.locale.toLowerCase());
    return Footer(
      padding: EdgeInsets.all(10.0),
      child: Row(
        children: [
          Text('© 2014 - 2026 Claudia Kay Allen'),
          Spacer(),
          Image.asset('icons/flags/png100px/$iconcode.png', package: 'country_icons', height: 15),
        ]
      ),
    );
  }
}
