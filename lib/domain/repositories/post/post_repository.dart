import 'package:universal_io/io.dart';
import 'package:instagram/data/models/post.dart';

abstract class FirestorePostRepository {
  Future<String> createPost(
      {required Post postInfo, required List<File> files});
  Future<List<Post>> getPostsInfo(
      {required List<dynamic> postsIds, required int lengthOfCurrentList});
  Future<List<Post>> getAllPostsInfo();
  Future<List> getSpecificUsersPosts(List<dynamic> usersIds);
  Future<void> putLikeOnThisPost(
      {required String postId, required String userId});
  Future<void> removeTheLikeOnThisPost(
      {required String postId, required String userId});
  Future<void> deletePost({required Post postInfo});
  Future<Post> updatePost({required Post postInfo});
}
