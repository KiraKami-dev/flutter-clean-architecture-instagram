import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instegram/data/models/comment.dart';
import 'package:instegram/domain/usecases/postUseCase/comments/add_comment_use_case.dart';
import 'package:instegram/domain/usecases/postUseCase/comments/getComment/get_all_comment.dart';

part 'comments_info_state.dart';

class CommentsInfoCubit extends Cubit<CommentsInfoState> {
  final GetPostInfoStreamedUseCase _getSpecificCommentsUseCase;
  final AddCommentUseCase _addCommentUseCase;
  List<Comment> commentsOfThePost = [];

  CommentsInfoCubit(this._getSpecificCommentsUseCase, this._addCommentUseCase)
      : super(CommentsInfoInitial());

  static CommentsInfoCubit get(BuildContext context) =>
      BlocProvider.of(context);

  // Future<void> getSpecificComments({required String postId}) async {
  //   // emit(CubitCommentsInfoLoading());
  //   // await _getSpecificCommentsUseCase.call(params: postId).then((commentsInfo) {
  //   //   commentsOfThePost = commentsInfo;
  //   //   emit(CubitCommentsInfoLoaded(commentsInfo));
  //   // }).catchError((e) {
  //   //   emit(CubitCommentsInfoFailed(e.toString()));
  //   // });
  // }

  Future<void> addComment({required Comment commentInfo}) async {
    emit(CubitCommentsInfoLoading());
    await _addCommentUseCase
        .call(params: commentInfo)
        .then((updatedCommentInfo) {
      commentsOfThePost = [updatedCommentInfo] + commentsOfThePost;
      emit(CubitCommentsInfoLoaded(commentsOfThePost));
    }).catchError((e) {
      emit(CubitCommentsInfoFailed(e.toString()));
    });
  }

}
