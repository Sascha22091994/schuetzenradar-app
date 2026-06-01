import 'package:flutter/material.dart';
import '../models/festival.dart';
import '../services/favorite_service.dart';
import '../screens/festival_detail_screen.dart';
import '../services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FestivalCard extends StatefulWidget {
  final Festival festival;
  final VoidCallback onFavoriteChanged;

  const FestivalCard({
    super.key,
    required this.festival,
    required this.onFavoriteChanged,
  });

  @override
  State<FestivalCard> createState() => _FestivalCardState();
}

class _FestivalCardState extends State<FestivalCard> {

  late bool isFav;

  //--------------------------------------------------
  @override
  void initState() {
    super.initState();
    isFav = FavoriteService.isFavorite(widget.festival.id);
  }

  //--------------------------------------------------
  DateTime get now => DateTime.now();

  bool _isToday() {
    final today = DateTime(now.year, now.month, now.day);

    final start = DateTime(
        widget.festival.startDate.year,
        widget.festival.startDate.month,
        widget.festival.startDate.day);

    final end = DateTime(
        widget.festival.endDate.year,
        widget.festival.endDate.month,
        widget.festival.endDate.day);

    return !start.isAfter(today) && !end.isBefore(today);
  }

  bool _isFuture() {
    final today = DateTime(now.year, now.month, now.day);
    return widget.festival.startDate.isAfter(today);
  }

  bool _isLive() {
    return _isToday();
  }

  //--------------------------------------------------
  String _formatDate() {
    return "${widget.festival.startDate.day}.${widget.festival.startDate.month}.${widget.festival.startDate.year}";
  }

String _formatDateSimple(DateTime d) {
  return "${d.day}.${d.month}.${d.year}";
}


  //--------------------------------------------------
  String _getCountdown() {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final eventDate = DateTime(
      widget.festival.startDate.year,
      widget.festival.startDate.month,
      widget.festival.startDate.day,
    );

    final diff = eventDate.difference(today).inDays;

    if (diff == 0) {
      return "heute";
    } else if (diff == 1) {
      return "morgen 🎉";
    } else if (diff > 1) {
      return "in $diff Tagen";
    } else {
      return "läuft";
    }
  }

  //--------------------------------------------------
  Future<void> _toggleFavorite() async {

    // ✅ SOFORT UI ändern (wichtig!)
    setState(() {
      isFav = !isFav;
    });

    // ✅ danach speichern
    await FavoriteService.toggleFavorite(widget.festival.id);

    widget.onFavoriteChanged();
  }


void _showEditDialog() {

  final nameController =
      TextEditingController(text: widget.festival.name);

  final addressController =
      TextEditingController(text: widget.festival.address);

  final descController =

    TextEditingController(text: widget.festival.description);

bool isHighlight = widget.festival.isHighlight;

  final latController =
      TextEditingController(text: widget.festival.latitude.toString());

  final lngController =
      TextEditingController(text: widget.festival.longitude.toString());

  DateTime startDate = widget.festival.startDate;
  DateTime endDate = widget.festival.endDate;


  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setDialogState) {

        return AlertDialog(
          title: const Text("Fest bearbeiten"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                //--------------------------------------------------
                // NAME
                //--------------------------------------------------
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),

                //--------------------------------------------------
                // ADRESSE
                //--------------------------------------------------
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Adresse"),
                ),

                //--------------------------------------------------
                // BESCHREIBUNG
                //--------------------------------------------------
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Beschreibung"),
                  maxLines: 3,
                ),

                //--------------------------------------------------
                // DATUM START
                //--------------------------------------------------
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

                //--------------------------------------------------
                // DATUM ENDE
                //--------------------------------------------------
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

                //--------------------------------------------------
                // GEO
                //--------------------------------------------------
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

                //--------------------------------------------------
                // HIGHLIGHT
                //--------------------------------------------------
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
                    .collection('festivals')
                    .doc(widget.festival.id)
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


Future<void> _deleteFestival() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Wirklich löschen?"),
      content: const Text("Dieses Fest wird dauerhaft gelöscht."),
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
        .collection('festivals')
        .doc(widget.festival.id)
        .delete();
  }
}

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    final isToday = _isToday();
    final isLive = _isLive();
    final isFuture = _isFuture();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FestivalDetailScreen(festival: widget.festival),
            ),
          );
        },

        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isLive
                ? (isDark ? Colors.green.shade800 : Colors.green.shade50)
                : (isDark ? Colors.grey.shade900 : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLive ? Colors.green : Colors.grey.shade300,
              width: isLive ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),

          child: Column(
   
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    //--------------------------------------------------
    // ✅ TOP ROW
    //--------------------------------------------------
    Row(
      children: [

        Text(
          _formatDate(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),

        const SizedBox(width: 10),

        if (isLive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "LIVE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "HEUTE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        const Spacer(),

        IconButton(
          onPressed: _toggleFavorite,
          icon: Icon(
            isFav ? Icons.star : Icons.star_border,
            color: isFav ? Colors.amber : Colors.grey,
          ),
        ),

        if (AdminService.isAdmin) ...[
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: _deleteFestival,
          ),
        ],
      ],
    ),

    const SizedBox(height: 10),

    //--------------------------------------------------
    // ✅ NAME
    //--------------------------------------------------
    Text(
      widget.festival.name,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    ),

    //--------------------------------------------------
    // ✅ COUNTDOWN (JETZT RICHTIG!)
    //--------------------------------------------------
    if (isFuture)
      Text(
        "Start ${_getCountdown()}",
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),

    //--------------------------------------------------
    // ✅ LIVE STATUS
    //--------------------------------------------------
    if (isLive)
      const Text(
        "🔥 Läuft gerade",
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),

    const SizedBox(height: 6),

    //--------------------------------------------------
    // ✅ ADRESSE
    //--------------------------------------------------
    Row(
      children: [
        const Icon(Icons.location_on, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.festival.address,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white70
                  : Colors.grey.shade700,
            ),
          ),
        ),
      ],
    ),
  ],
)



              
            
          ),
        ),
      
    );
  }
}
