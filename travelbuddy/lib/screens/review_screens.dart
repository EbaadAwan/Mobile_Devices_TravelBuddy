//   AllReviewsScreen  - every review for one attraction, with rating summary, star filter, sorting and deleting your own reviews.
//   WriteReviewScreen - choose stars, write text, attach photos (camera or gallery) and post.
//   PhotoViewerScreen - full-screen, pinch-to-zoom view of review photos.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/review_service.dart';
import '../widgets/review_widgets.dart';

class AllReviewsScreen extends StatefulWidget {
  const AllReviewsScreen({
    super.key,
    required this.attractionName,
    required this.fallbackRating,
    this.showPostedMessage = false,
  });

  final String attractionName;
  final double fallbackRating;

  final bool showPostedMessage;

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  final ReviewService _service = ReviewService.instance;
  ReviewSort _sort = ReviewSort.newest;
  int? _starFilter; 

  @override
  void initState() {
    super.initState();
    if (widget.showPostedMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSnack('Thanks! Your review was posted.');
      });
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _writeReview() async {
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WriteReviewScreen(attractionName: widget.attractionName)),
    );
    if (posted == true && mounted) {
      setState(() {
        _starFilter = null;
        _sort = ReviewSort.newest; 
      });
      _showSnack('Thanks! Your review was posted.');
    }
  }

  Future<void> _confirmDelete(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('This will permanently remove your review and its photos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteReview(review);
      if (mounted) _showSnack('Review deleted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reviews'),
            Text(
              widget.attractionName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _writeReview,
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Write a review'),
      ),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          final allReviews = _service.reviewsFor(widget.attractionName, sort: _sort);
          final summary = RatingSummary.fromReviews(allReviews);
          final shown = _starFilter == null
              ? allReviews
              : allReviews.where((r) => r.rating == _starFilter).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
            children: [
              RatingSummaryCard(
                summary: summary,
                fallbackRating: widget.fallbackRating,
                selectedStars: _starFilter,
                onStarsTap: (stars) =>
                    setState(() => _starFilter = _starFilter == stars ? null : stars),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _starFilter == null,
                      onSelected: (_) => setState(() => _starFilter = null),
                    ),
                    for (var stars = 5; stars >= 1; stars--) ...[
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text('$stars ★'),
                        selected: _starFilter == stars,
                        onSelected: (_) => setState(
                          () => _starFilter = _starFilter == stars ? null : stars,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _starFilter == null
                          ? '${shown.length} review${shown.length == 1 ? '' : 's'}'
                          : '${shown.length} with $_starFilter ★',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  DropdownButton<ReviewSort>(
                    value: _sort,
                    underline: const SizedBox.shrink(),
                    items: ReviewSort.values
                        .map((sort) => DropdownMenuItem(value: sort, child: Text(sort.label)))
                        .toList(),
                    onChanged: (sort) {
                      if (sort != null) setState(() => _sort = sort);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.reviews_outlined, size: 48, color: Colors.black26),
                      const SizedBox(height: 10),
                      Text(
                        allReviews.isEmpty
                            ? 'No reviews yet. Be the first!'
                            : 'No reviews with this rating.',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                )
              else
                for (final review in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ReviewTile(
                      review: review,
                      onDelete: review.isMine ? () => _confirmDelete(review) : null,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key, required this.attractionName});

  final String attractionName;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  static const int _maxPhotos = 4;
  static const int _minTextLength = 10;
  static const List<String> _ratingWords = ['', 'Terrible', 'Poor', 'Okay', 'Good', 'Excellent'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: ReviewService.instance.lastAuthorName);
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _photos = [];
  int _rating = 0;
  bool _ratingMissing = false;
  bool _isPosting = false;

  bool get _hasChanges =>
      _rating > 0 || _textController.text.trim().isNotEmpty || _photos.isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _choosePhotoSource() async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to $_maxPhotos photos.')),
      );
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final remaining = _maxPhotos - _photos.length;
      List<XFile> picked;
      if (source == ImageSource.camera) {
        final photo = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          imageQuality: 75,
        );
        picked = photo == null ? [] : [photo];
      } else if (remaining == 1) {
        final photo = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          imageQuality: 75,
        );
        picked = photo == null ? [] : [photo];
      } else {
        picked = await _picker.pickMultiImage(
          maxWidth: 1600,
          imageQuality: 75,
          limit: remaining,
        );
      }
      if (picked.isNotEmpty && mounted) {
        setState(() => _photos.addAll(picked.take(remaining)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}.')),
        );
      }
    }
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _ratingMissing = _rating == 0);
    if (!formValid || _rating == 0) return;

    setState(() => _isPosting = true);
    try {
      await ReviewService.instance.addReview(
        attractionName: widget.attractionName,
        authorName: _nameController.text,
        rating: _rating,
        text: _textController.text,
        photoPaths: _photos.map((photo) => photo.path).toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your review: $e')),
        );
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard review?'),
        content: const Text('Your rating, text and photos will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: !_hasChanges || _isPosting,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop(false);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Write a review')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              Text(
                widget.attractionName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              const Text('Your rating', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  StarRatingInput(
                    value: _rating,
                    onChanged: (stars) => setState(() {
                      _rating = stars;
                      _ratingMissing = false;
                    }),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _ratingWords[_rating],
                    style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_ratingMissing)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Please choose a star rating.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: 'Your name (optional)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _textController,
                minLines: 4,
                maxLines: 8,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}), 
                decoration: const InputDecoration(
                  labelText: 'Your review',
                  hintText: 'What did you like? Any tips for other travellers?',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < _minTextLength) {
                    return 'Please write at least $_minTextLength characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text('Photos', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Text(
                    '${_photos.length}/$_maxPhotos',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _photos.length; i++)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(_photos[i].path),
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => setState(() => _photos.removeAt(i)),
                            child: const CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_photos.length < _maxPhotos)
                    InkWell(
                      onTap: _choosePhotoSource,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: primary.withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: primary),
                            const SizedBox(height: 4),
                            Text('Add', style: TextStyle(color: primary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _isPosting ? null : _submit,
                icon: _isPosting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_isPosting ? 'Posting...' : 'Post review'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({super.key, required this.photoPaths, this.initialIndex = 0});

  final List<String> photoPaths;
  final int initialIndex;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.photoPaths.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photoPaths.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.file(
              File(widget.photoPaths[index]),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
