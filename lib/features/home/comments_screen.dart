import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../core/services/photos_service.dart';
import '../../models/comment.dart';
import '../../components/layout/bottom_action_bar_surface.dart';
import '../../components/navigation/standard_screen_app_bar.dart';

/// Comments thread screen
class CommentsScreen extends StatefulWidget {
  const CommentsScreen({
    super.key,
    required this.photoId,
    this.initialComments,
  });

  final String photoId;
  final List<Comment>? initialComments;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  int? get _photoIdInt => int.tryParse(widget.photoId);

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final photoId = _photoIdInt;
    if (photoId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await PhotosService.instance.getComments(photoId);

    if (mounted) {
      setState(() {
        _comments = result.comments
            .map((pc) => Comment(
                  id: pc.id,
                  username: pc.username,
                  avatarUrl: pc.avatarUrl,
                  content: pc.content,
                  createdAt: pc.createdAt,
                  likeCount: 0,
                ))
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    final photoId = _photoIdInt;
    if (photoId == null) return;

    setState(() => _isSending = true);
    VHaptics.light();

    final result = await PhotosService.instance.addComment(photoId, text);

    if (mounted) {
      if (result.isSuccess) {
        final newComment = Comment(
          id: result.commentId ?? DateTime.now().millisecondsSinceEpoch,
          username: 'common.you'.tr(),
          avatarUrl: null,
          content: text,
          createdAt: DateTime.now(),
          likeCount: 0,
        );
        setState(() {
          _comments.insert(0, newComment);
          _isSending = false;
        });
        _commentController.clear();
        _focusNode.unfocus();
        VHaptics.success();
      } else {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('comments.add_failed'.tr()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: VColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId, int index) async {
    final success = await PhotosService.instance.deleteComment(commentId);
    if (success && mounted) {
      setState(() => _comments.removeAt(index));
      VHaptics.success();
    }
  }

  Future<void> _reportComment(int commentId) async {
    await PhotosService.instance.reportComment(commentId, 'inappropriate');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('comments.reported'.tr()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: VColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'comments.title'.tr(),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_comments.length}',
              style: VType.label.copyWith(color: VColors.textSec(context)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: VSpace.screenH,
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          return _CommentItem(
                            comment: _comments[index],
                            onDelete: () => _deleteComment(_comments[index].id, index),
                            onReport: () => _reportComment(_comments[index].id),
                            onReply: () => _replyToComment(index),
                          );
                        },
                      ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            VIcons.comment,
            size: 48,
            color: VColors.textTer(context),
          ),
          VSpace.v4,
          Text(
            'comments.empty_title'.tr(),
            style: VType.screenSectionTitle.copyWith(
              color: VColors.text(context),
            ),
          ),
          VSpace.v2,
          Text(
            'comments.empty_desc'.tr(),
            style: VType.body.copyWith(color: VColors.textSec(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return BottomActionBarSurface(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'comments.add_comment'.tr(),
                hintStyle: VType.body.copyWith(color: VColors.textTer(context)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: VType.body.copyWith(color: VColors.text(context)),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
            ),
          ),
          VSpace.h2,
          GestureDetector(
            onTap: _sendComment,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: VColors.accentPrimary,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      VIcons.up,
                      size: 20,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _replyToComment(int index) {
    _focusNode.requestFocus();
    _commentController.text = '@${_comments[index].username} ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({
    required this.comment,
    required this.onDelete,
    required this.onReport,
    required this.onReply,
  });

  final Comment comment;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
            ),
            child: comment.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      comment.avatarUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    VIcons.user,
                    size: 20,
                    color: VColors.textTer(context),
                  ),
          ),
          VSpace.h3,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '@${comment.username}',
                      style: VType.label.copyWith(color: VColors.text(context)),
                    ),
                    VSpace.h2,
                    Text(
                      _formatTime(comment.createdAt),
                      style: VType.caption.copyWith(color: VColors.textTer(context)),
                    ),
                  ],
                ),
                VSpace.v1,
                Text(
                  comment.content,
                  style: VType.body.copyWith(color: VColors.text(context)),
                ),
                VSpace.v2,
                Row(
                  children: [
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        'comments.reply'.tr(),
                        style: VType.caption.copyWith(color: VColors.textTer(context)),
                      ),
                    ),
                    VSpace.h4,
                    GestureDetector(
                      onTap: onReport,
                      child: Icon(
                        VIcons.flag,
                        size: 14,
                        color: VColors.textTer(context),
                      ),
                    ),
                    if (comment.username == 'you') ...[
                      VSpace.h4,
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          VIcons.trash,
                          size: 14,
                          color: VColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'common.just_now'.tr();
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.month}/${dateTime.day}';
  }
}
