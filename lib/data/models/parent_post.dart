import 'package:instegram/data/models/user_personal_info.dart';

class ParentPost {
  String datePublished;
  String caption;
  String publisherId;
  List<dynamic> likes;
  List<dynamic> comments;
  UserPersonalInfo? publisherInfo;
  bool isThatImage;

  ParentPost({
    required this.datePublished,
    required this.publisherId,
    this.publisherInfo,
    this.caption = "",
    required this.comments,
    required this.likes,
    this.isThatImage = true,
  });
}
