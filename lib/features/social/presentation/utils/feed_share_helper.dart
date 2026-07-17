import 'package:flutter/material.dart';

import '../../../food/presentation/utils/meal_share_helper.dart';
import '../providers/feed_provider.dart';
import '../widgets/feed_share_card.dart';

Future<void> shareFeedPostAsImage(
  BuildContext context,
  Post post, {
  Rect? sharePositionOrigin,
}) async {
  final imageBytes = await resolveShareImageBytes(post.imageUrl);
  if (!context.mounted) return;

  final caption = (post.content ?? '').trim();
  final shareText = caption.isEmpty
      ? 'Shared from gojocalories'
      : '$caption — via gojocalories';

  await captureAndShareWidget(
    context,
    builder: (_) => FeedShareCard(
      authorName: post.userName,
      content: post.content,
      imageBytes: imageBytes,
    ),
    cardWidth: FeedShareCard.width,
    filePrefix: 'gojocalories_post',
    shareText: shareText,
    sharePositionOrigin: sharePositionOrigin,
    precacheBytes: imageBytes,
  );
}
