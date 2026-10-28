// - Review: one review (1-5 stars, text, optional photos).
// - RatingSummary: the aggregated rating for an attraction (average, count, how many reviews gave each star value).
// - ReviewService: the single place the app reads/writes reviews. It is a ChangeNotifier, so any 
//   widget wrapped in a ListenableBuilder rebuilds automatically when a review is added or deleted.

// Reviews the user writes are saved on the device with shared_preferences, and their photos are 
// copied into the app's documents folder so they are still there after the app restarts.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Review {
  const Review({
    required this.id,
    required this.attractionName,
    required this.authorName,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.photoPaths = const [],
    this.isSample = false,
  });

  final String id;

  final String attractionName;
  final String authorName;

  final int rating;
  final String text;
  final DateTime createdAt;

  /// Local file paths of photos attached to the review.
  final List<String> photoPaths;

  /// Built-in demo review (can't be deleted, isn't saved).
  final bool isSample;

  bool get isMine => !isSample;

  Map<String, dynamic> toJson() => {
        'id': id,
        'attractionName': attractionName,
        'authorName': authorName,
        'rating': rating,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'photoPaths': photoPaths,
      };

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      attractionName: json['attractionName'] as String,
      authorName: json['authorName'] as String? ?? 'Traveller',
      rating: (json['rating'] as num).toInt().clamp(1, 5),
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      photoPaths: (json['photoPaths'] as List?)?.whereType<String>().toList() ?? const [],
    );
  }
}

class RatingSummary {
  const RatingSummary({required this.average, required this.count, required this.starCounts});

  final double average;
  final int count;

  /// starCounts[0] = number of 1-star reviews, starCounts[4] = 5-star.
  final List<int> starCounts;

  bool get hasReviews => count > 0;

  /// Share (0.0-1.0) of reviews that gave [stars] stars.
  double fractionFor(int stars) => count == 0 ? 0 : starCounts[stars - 1] / count;

  factory RatingSummary.fromReviews(List<Review> reviews) {
    final counts = List<int>.filled(5, 0);
    var total = 0;
    for (final review in reviews) {
      counts[review.rating - 1]++;
      total += review.rating;
    }
    return RatingSummary(
      average: reviews.isEmpty ? 0 : total / reviews.length,
      count: reviews.length,
      starCounts: counts,
    );
  }
}

enum ReviewSort { newest, highest, lowest }

extension ReviewSortLabel on ReviewSort {
  String get label => switch (this) {
        ReviewSort.newest => 'Newest',
        ReviewSort.highest => 'Highest rated',
        ReviewSort.lowest => 'Lowest rated',
      };
}

class ReviewService extends ChangeNotifier {
  // Saved reviews start loading the first time the service is used.
  ReviewService._() {
    load();
  }

  static final ReviewService instance = ReviewService._();

  static const String _reviewsKey = 'travelbuddy_reviews_v1';
  static const String _authorKey = 'travelbuddy_review_author_v1';

  final List<Review> _userReviews = [];
  Future<void>? _loading;
  String _lastAuthorName = '';

  String get lastAuthorName => _lastAuthorName;

  /// Loads saved reviews from the device. Safe to call many times; it only reads storage once.
  Future<void> load() => _loading ??= _loadFromStorage();

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_reviewsKey);
      if (saved != null) {
        final list = jsonDecode(saved) as List;
        _userReviews
          ..clear()
          ..addAll(list.map((item) => Review.fromJson((item as Map).cast<String, dynamic>())));
      }
      _lastAuthorName = prefs.getString(_authorKey) ?? '';
    } catch (e) {
      debugPrint('ReviewService: could not load saved reviews: $e');
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reviewsKey,
      jsonEncode(_userReviews.map((review) => review.toJson()).toList()),
    );
  }

  List<Review> reviewsFor(String attractionName, {ReviewSort sort = ReviewSort.newest}) {
    final reviews = [
      ..._userReviews.where((r) => r.attractionName == attractionName),
    ];
    switch (sort) {
      case ReviewSort.newest:
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ReviewSort.highest:
        reviews.sort((a, b) {
          final byRating = b.rating.compareTo(a.rating);
          return byRating != 0 ? byRating : b.createdAt.compareTo(a.createdAt);
        });
      case ReviewSort.lowest:
        reviews.sort((a, b) {
          final byRating = a.rating.compareTo(b.rating);
          return byRating != 0 ? byRating : b.createdAt.compareTo(a.createdAt);
        });
    }
    return reviews;
  }

  RatingSummary summaryFor(String attractionName) =>
      RatingSummary.fromReviews(reviewsFor(attractionName));

  /// The rating to show on cards: the average of reviews if there are any,
  /// otherwise [fallback] (the rating that came with the attraction data).
  double displayRating(String attractionName, double fallback) {
    final summary = summaryFor(attractionName);
    return summary.hasReviews ? summary.average : fallback;
  }

  Future<Review> addReview({
    required String attractionName,
    required String authorName,
    required int rating,
    required String text,
    List<String> photoPaths = const [],
  }) async {
    await load();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final savedPhotos = await _copyPhotosToAppFolder(id, photoPaths);

    final review = Review(
      id: id,
      attractionName: attractionName,
      authorName: authorName.trim().isEmpty ? 'Traveller' : authorName.trim(),
      rating: rating.clamp(1, 5),
      text: text.trim(),
      createdAt: DateTime.now(),
      photoPaths: savedPhotos,
    );

    _userReviews.add(review);
    _lastAuthorName = authorName.trim();
    notifyListeners();

    await _save();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authorKey, _lastAuthorName);
    return review;
  }

  Future<void> deleteReview(Review review) async {
    if (review.isSample) return;
    _userReviews.removeWhere((r) => r.id == review.id);
    notifyListeners();
    await _save();
    for (final path in review.photoPaths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Not important if a photo file can't be removed.
      }
    }
  }

  /// image_picker gives temporary files that Android/iOS may clean up, so we copy them somewhere permanent.
  Future<List<String>> _copyPhotosToAppFolder(String reviewId, List<String> paths) async {
    if (paths.isEmpty) return const [];
    final docs = await getApplicationDocumentsDirectory();
    final folder = Directory('${docs.path}/review_photos');
    if (!await folder.exists()) await folder.create(recursive: true);

    final saved = <String>[];
    for (var i = 0; i < paths.length; i++) {
      final source = File(paths[i]);
      if (!await source.exists()) continue;
      final dot = source.path.lastIndexOf('.');
      final extension = dot >= 0 ? source.path.substring(dot) : '.jpg';
      final copy = await source.copy('${folder.path}/${reviewId}_$i$extension');
      saved.add(copy.path);
    }
    return saved;
  }
}
