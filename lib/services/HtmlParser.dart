import '../Env.dart';
class HtmlParser {

  // removes "full_html" from end of string
  String parseHtmlString(String htmlString) {
    String parsedText = htmlString;

    if (parsedText.endsWith(", full_html")) {
      parsedText = parsedText.substring(0, parsedText.length - 11);
    }
    parsedText = parsedText.replaceAll('"/sites', '"https://' + Env.DRUPAL_URL + '/sites');
    return parsedText.trim();
  }


}