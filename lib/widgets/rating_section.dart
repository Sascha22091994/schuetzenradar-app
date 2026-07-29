import 'package:flutter/material.dart';
import '../services/rating_service.dart';
import '../theme/app_colors.dart';

class RatingSection extends StatefulWidget {
  final String eventId;

  const RatingSection({super.key, required this.eventId});

  @override
  State<RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<RatingSection> {
  List<EventRating> _ratings = [];
  int? _myRating;
  int _selectedStars = 0;
  final TextEditingController _commentController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  //--------------------------------------------------
  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final ratings = await RatingService.fetchRatings(widget.eventId);
      final myRating = await RatingService.fetchMyRating(widget.eventId);

      if (!mounted) return;

      setState(() {
        _ratings = ratings;
        _myRating = myRating;
        _selectedStars = myRating ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fehler beim Laden der Bewertungen: $e");

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  //--------------------------------------------------
  double get _average {
    if (_ratings.isEmpty) return 0;
    final sum = _ratings.fold<int>(0, (acc, r) => acc + r.stars);
    return sum / _ratings.length;
  }

  //--------------------------------------------------
  Future<void> _submit() async {
    if (_selectedStars == 0) return;

    setState(() => _isSubmitting = true);

    try {
      await RatingService.submitRating(
        eventId: widget.eventId,
        stars: _selectedStars,
        comment: _commentController.text.trim(),
      );

      _commentController.clear();
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Danke für deine Bewertung!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  //--------------------------------------------------
  // ✅ Kompakte, selbstgebaute Sterne-Reihe statt IconButton
  // (IconButton bringt 48x48px Mindestgröße pro Stern mit,
  // das reißt auf schmalen Screens schneller den Platz auf)
  //--------------------------------------------------
  Widget _buildStarRow({
    required int value,
    void Function(int)? onTap,
    double size = 30,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final filled = starIndex <= value;

        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap == null ? null : () => onTap(starIndex),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              color: AppColors.warning,
              size: size,
            ),
          ),
        );
      }),
    );
  }

  //--------------------------------------------------
  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inDays > 30) {
      return "${date.day}.${date.month}.${date.year}";
    }
    if (diff.inDays >= 1) {
      return "vor ${diff.inDays} ${diff.inDays == 1 ? 'Tag' : 'Tagen'}";
    }
    if (diff.inHours >= 1) {
      return "vor ${diff.inHours} Std.";
    }
    if (diff.inMinutes >= 1) {
      return "vor ${diff.inMinutes} Min.";
    }
    return "gerade eben";
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(isDark, secondaryTextColor),
      ),
    );
  }

  //--------------------------------------------------
  Widget _buildBody(bool isDark, Color secondaryTextColor) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.warning),
              const SizedBox(width: 8),
              const Text(
                "Bewertungen",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Bewertungen konnten nicht geladen werden.",
            style: TextStyle(color: secondaryTextColor),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text("Erneut versuchen"),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        //--------------------------------------------------
        // ✅ KOPFZEILE MIT DURCHSCHNITT
        //--------------------------------------------------
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text(
              "Bewertungen",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            if (_ratings.isNotEmpty) ...[
              Text(
                _average.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "(${_ratings.length})",
                style: TextStyle(color: secondaryTextColor, fontSize: 13),
              ),
            ],
          ],
        ),

        const SizedBox(height: 14),

        //--------------------------------------------------
        // ✅ EIGENE BEWERTUNG ABGEBEN/ÄNDERN
        //--------------------------------------------------
        Text(
          _myRating == null
              ? "Wie fandest du dieses Event?"
              : "Deine Bewertung:",
          style: TextStyle(color: secondaryTextColor, fontSize: 13),
        ),

        const SizedBox(height: 6),

        _buildStarRow(
          value: _selectedStars,
          onTap: (value) => setState(() => _selectedStars = value),
        ),

        if (_selectedStars > 0) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _commentController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Kommentar (optional)",
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _myRating == null
                          ? "Bewertung abgeben"
                          : "Bewertung aktualisieren",
                    ),
            ),
          ),
        ],

        //--------------------------------------------------
        // ✅ KOMMENTARE ANDERER NUTZER
        //--------------------------------------------------
        if (_ratings.where((r) => r.comment.isNotEmpty).isNotEmpty) ...[
          const SizedBox(height: 18),
          Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          const SizedBox(height: 8),
          ..._ratings.where((r) => r.comment.isNotEmpty).take(5).map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStarRow(value: r.stars, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(r.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(r.comment),
                ],
              ),
            );
          }),
        ] else if (_ratings.isEmpty) ...[
          const SizedBox(height: 14),
          Text(
            "Sei die erste Person, die dieses Event bewertet.",
            style: TextStyle(color: secondaryTextColor, fontSize: 13),
          ),
        ],
      ],
    );
  }
}