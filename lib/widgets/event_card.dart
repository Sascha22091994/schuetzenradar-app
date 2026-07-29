import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_category.dart';
import '../services/favorite_service.dart';
import '../screens/event_detail_screen.dart';
import '../services/admin_service.dart';
import '../theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final VoidCallback onFavoriteChanged;

  const EventCard({
    super.key,
    required this.event,
    required this.onFavoriteChanged,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late bool isFav;

  //--------------------------------------------------
  @override
  void initState() {
    super.initState();
    isFav = FavoriteService.isFavorite(widget.event.id);
  }

  //--------------------------------------------------
  DateTime get now => DateTime.now();

  bool _isFuture() {
    final today = DateTime(now.year, now.month, now.day);
    return widget.event.startDate.isAfter(today);
  }

  //--------------------------------------------------
  String _formatDate() {
    return "${widget.event.startDate.day}.${widget.event.startDate.month}.${widget.event.startDate.year}";
  }

  String _formatDateSimple(DateTime d) {
    return "${d.day}.${d.month}.${d.year}";
  }

  //--------------------------------------------------
  String _getCountdown() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final eventDate = DateTime(
      widget.event.startDate.year,
      widget.event.startDate.month,
      widget.event.startDate.day,
    );

    final diff = eventDate.difference(today).inDays;

    if (diff == 0) {
      return "heute";
    } else if (diff == 1) {
      return "morgen";
    } else if (diff > 1) {
      return "in $diff Tagen";
    } else {
      return "läuft";
    }
  }

  //--------------------------------------------------
  String get _headerImage =>
      widget.event.images.isNotEmpty ? widget.event.images.first : '';

  //--------------------------------------------------
  // ✅ KATEGORIE-FARBE (mit Fallback)
  //--------------------------------------------------
  EventCategory? get _category =>
      EventCategoryExtension.fromString(widget.event.category);

  Color get _categoryColor {
    final base = _category?.color ?? AppColors.primary;
    // ✅ leicht abgedunkelt für konsistenten Kontrast mit weißem Text
    return Color.lerp(base, Colors.black, 0.25)!;
  }

  String get _categoryLabel => _category?.label ?? widget.event.category;

  //--------------------------------------------------
  Future<void> _toggleFavorite() async {
    setState(() {
      isFav = !isFav;
    });

    await FavoriteService.toggleFavorite(widget.event.id);
    widget.onFavoriteChanged();
  }

  void _showEditDialog() {
    final nameController =
        TextEditingController(text: widget.event.name);

    final addressController =
        TextEditingController(text: widget.event.address);

    final descController =
        TextEditingController(text: widget.event.description);

    bool isHighlight = widget.event.isHighlight;

    final latController =
        TextEditingController(text: widget.event.latitude.toString());

    final lngController =
        TextEditingController(text: widget.event.longitude.toString());

    DateTime startDate = widget.event.startDate;
    DateTime endDate = widget.event.endDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Veranstaltung bearbeiten"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: "Adresse"),
                  ),
                  TextField(
                    controller: descController,
                    decoration:
                        const InputDecoration(labelText: "Beschreibung"),
                    maxLines: 3,
                  ),
                  ListTile(
                    title: Text("Start: ${_formatDateSimple(startDate)}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    title: Text("Ende: ${_formatDateSimple(endDate)}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
                      }
                    },
                  ),
                  TextField(
                    controller: latController,
                    decoration: const InputDecoration(labelText: "Latitude"),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: lngController,
                    decoration: const InputDecoration(labelText: "Longitude"),
                    keyboardType: TextInputType.number,
                  ),
                  SwitchListTile(
                    value: isHighlight,
                    title: const Text("Highlight anzeigen"),
                    onChanged: (val) {
                      setDialogState(() => isHighlight = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Abbrechen"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("Speichern"),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('events')
                      .doc(widget.event.id)
                      .update({
                    "name": nameController.text,
                    "address": addressController.text,
                    "description": descController.text,
                    "startDate": startDate,
                    "endDate": endDate,
                    "latitude": double.tryParse(latController.text) ?? 0,
                    "longitude": double.tryParse(lngController.text) ?? 0,
                    "isHighlight": isHighlight,
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Wirklich löschen?"),
        content: const Text("Diese Veranstaltung wird dauerhaft gelöscht."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Löschen"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('Events')
          .doc(widget.event.id)
          .delete();
    }
  }

  //--------------------------------------------------
  // ✅ NEU: kompaktes Kategorie-Badge, wiederverwendbar für den
  // bildlosen Fallback (löst UX-Problem: Kategorie war dort unsichtbar).
  //--------------------------------------------------
  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _categoryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _categoryLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isFuture = _isFuture();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final secondaryTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: widget.event),
            ),
          );
        },

        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.event.isHighlight
                  ? AppColors.primary
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              width: widget.event.isHighlight ? 2 : 1,
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              //--------------------------------------------------
              // ✅ TITELBILD MIT SCRIM + BADGES
              //--------------------------------------------------
              if (_headerImage.isNotEmpty)
                Hero(
                  tag: widget.event.id,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Image.network(
                          _headerImage,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),

                        // ✅ Verlauf oben (für Kategorie-Badge + Favoriten-Icon)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 70,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ✅ Verlauf unten (für Countdown-Badge)
                        if (isFuture)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 70,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.45),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                        Positioned(
                          top: 12,
                          left: 12,
                          child: _buildCategoryBadge(),
                        ),

                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            onPressed: _toggleFavorite,
                            icon: Icon(
                              isFav ? Icons.star : Icons.star_border,
                              color: isFav ? AppColors.warning : Colors.white,
                            ),
                          ),
                        ),

                        if (isFuture)
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Start ${_getCountdown()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              //--------------------------------------------------
              // ✅ TEXTBEREICH
              //--------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ✅ NEU: Kategorie-Badge (+ Countdown) auch ohne
                          // Bild sichtbar – vorher komplett unsichtbar in
                          // diesem Fall (das eigentliche Problem aus dem
                          // Screenshot).
                          if (_headerImage.isEmpty) ...[
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildCategoryBadge(),
                                if (isFuture)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Start ${_getCountdown()}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          Text(
                            widget.event.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: secondaryTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.event.address,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_headerImage.isEmpty) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _toggleFavorite,
                              child: Row(
                                children: [
                                  Icon(
                                    isFav ? Icons.star : Icons.star_border,
                                    size: 18,
                                    color: isFav
                                        ? AppColors.warning
                                        : secondaryTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isFav ? "Favorit" : "Merken",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (AdminService.isAdmin) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: _showEditDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: _deleteEvent,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}