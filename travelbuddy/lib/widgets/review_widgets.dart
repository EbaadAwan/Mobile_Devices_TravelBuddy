//   StarRatingDisplay   - read-only stars (supports half stars), e.g. 4.5
//   StarRatingInput     - tappable stars for writing a review
//   AggregatedRatingText- "4.3 ★" that updates when reviews change (cards)
//   RatingSummaryCard   - average + count + 1 to 5 star distribution bars
//   ReviewTile          - one review with text and photos
//   ReviewsSection      - the block shown on the attraction details sheet

import 'dart:io';

import 'package:flutter/material.dart';

import '../screens/review_screens.dart';
import '../services/review_service.dart';

class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({super.key, required this.rating, this.size = 18});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final IconData icon;
        if (rating >= starValue - 0.25) {
          icon = Icons.star_rounded;
        } else if (rating >= starValue - 0.75) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, size: size, color: Colors.amber);
      }),
    );
  }
}

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 42,
  });

  /// 0 = nothing chosen yet.
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final stars = index + 1;
        return IconButton(
          onPressed: () => onChanged(stars),
          tooltip: '$stars star${stars == 1 ? '' : 's'}',
          padding: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(),
          icon: Icon(
            stars <= value ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: Colors.amber,
          ),
        );
      }),
    );
  }
}

/// Shows the aggregated rating for an attraction and rebuilds automatically when someone adds or deletes 
/// a review. Falls back to [fallbackRating] (the rating from the attraction data) when there are no reviews yet.
class AggregatedRatingText extends StatelessWidget {
  const AggregatedRatingText({
    super.key,
    required this.attractionName,
    required this.fallbackRating,
    this.style,
    this.showCount = false,
  });

  final String attractionName;
  final double fallbackRating;
  final TextStyle? style;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final service = ReviewService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final summary = service.summaryFor(attractionName);
        final rating = summary.hasReviews ? summary.average : fallbackRating;
        final count = showCount && summary.hasReviews ? ' (${summary.count})' : '';
        return Text('${rating.toStringAsFixed(1)}$count', style: style);
      },
    );
  }
}

class RatingSummaryCard extends StatelessWidget {
  const RatingSummaryCard({
    super.key,
    required this.summary,
    required this.fallbackRating,
    this.selectedStars,
    this.onStarsTap,
  });

  final RatingSummary summary;
  final double fallbackRating;

  /// Highlights a bar and lets the user tap bars to filter.
  final int? selectedStars;
  final ValueChanged<int>? onStarsTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final average = summary.hasReviews ? summary.average : fallbackRating;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 96,
              child: Column(
                children: [
                  Text(
                    average.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, height: 1.1),
                  ),
                  StarRatingDisplay(rating: average, size: 16),
                  const SizedBox(height: 4),
                  Text(
                    summary.hasReviews
                        ? '${summary.count} review${summary.count == 1 ? '' : 's'}'
                        : 'No reviews yet',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  for (var stars = 5; stars >= 1; stars--)
                    InkWell(
                      onTap: onStarsTap == null ? null : () => onStarsTap!(stars),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12,
                              child: Text(
                                '$stars',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selectedStars == stars ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: summary.fractionFor(stars),
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    selectedStars == null || selectedStars == stars
                                        ? Colors.amber
                                        : Colors.amber.shade100,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 22,
                              child: Text(
                                '${summary.starCounts[stars - 1]}',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 11, color: primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review, this.onDelete});

  final Review review;

  /// When set, a menu with "Delete" is shown (only for the user's reviews).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  child: Text(
                    review.authorName.isEmpty ? '?' : review.authorName[0].toUpperCase(),
                    style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              review.authorName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (review.isMine) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('You', style: TextStyle(fontSize: 10, color: primary)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          StarRatingDisplay(rating: review.rating.toDouble(), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            timeAgo(review.createdAt),
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  PopupMenuButton<String>(
                    tooltip: 'Review options',
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.black45),
                    onSelected: (_) => onDelete!(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20),
                            SizedBox(width: 10),
                            Text('Delete review'),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
            if (review.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(review.text, style: const TextStyle(height: 1.35)),
              ),
            ],
            if (review.photoPaths.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.photoPaths.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PhotoViewerScreen(
                          photoPaths: review.photoPaths,
                          initialIndex: index,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(review.photoPaths[index]),
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 76,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image_outlined, color: Colors.black38),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The "Reviews" block on the attraction details sheet: rating summary,
/// the 3 newest reviews, and buttons to write a review or see them all.
class ReviewsSection extends StatelessWidget {
  const ReviewsSection({
    super.key,
    required this.attractionName,
    required this.fallbackRating,
  });

  final String attractionName;
  final double fallbackRating;

  static const int _previewCount = 3;

  Future<void> _writeReview(BuildContext context) async {
    final navigator = Navigator.of(context);
    final posted = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => WriteReviewScreen(attractionName: attractionName)),
    );
    if (posted == true) {
      // Show the full list (with a "Review posted" snackbar) so the user sees
      // their review. A snackbar here would be hidden behind the bottom sheet.
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => AllReviewsScreen(
            attractionName: attractionName,
            fallbackRating: fallbackRating,
            showPostedMessage: true,
          ),
        ),
      );
    }
  }

  void _openAll(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AllReviewsScreen(
          attractionName: attractionName,
          fallbackRating: fallbackRating,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ReviewService.instance;
    final primary = Theme.of(context).colorScheme.primary;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final reviews = service.reviewsFor(attractionName);
        final summary = RatingSummary.fromReviews(reviews);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                TextButton.icon(
                  onPressed: () => _writeReview(context),
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('Write a review'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            RatingSummaryCard(
              summary: summary,
              fallbackRating: fallbackRating,
              onStarsTap: (_) => _openAll(context),
            ),
            const SizedBox(height: 10),
            if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Be the first to review this place!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else ...[
              for (final review in reviews.take(_previewCount))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ReviewTile(review: review),
                ),
              if (reviews.length > _previewCount)
                OutlinedButton(
                  onPressed: () => _openAll(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary),
                  ),
                  child: Text('See all ${reviews.length} reviews'),
                )
              else
                TextButton(
                  onPressed: () => _openAll(context),
                  child: const Text('Open reviews page'),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// "just now", "5 min ago", "3 days ago", "2 months ago" etc.
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  if (diff.inDays < 30) {
    final weeks = diff.inDays ~/ 7;
    return '$weeks week${weeks == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 365) {
    final months = diff.inDays ~/ 30;
    return '$months month${months == 1 ? '' : 's'} ago';
  }
  final years = diff.inDays ~/ 365;
  return '$years year${years == 1 ? '' : 's'} ago';
}
