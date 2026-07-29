import 'package:flutter/material.dart';
import '../services/event_report_service.dart';
import '../theme/app_colors.dart';

Future<void> showReportEventSheet(
  BuildContext context, {
  required String eventId,
  required String eventName,
}) {
  const reasons = [
    "Falsches Datum",
    "Falsche Adresse",
    "Event existiert nicht mehr",
    "Falsche Beschreibung",
    "Sonstiges",
  ];

  String selectedReason = reasons.first;
  final detailsController = TextEditingController();
  bool isSubmitting = false;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_outlined, color: AppColors.danger),
                    const SizedBox(width: 10),
                    const Text(
                      "Event melden",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Was stimmt bei \"$eventName\" nicht?",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),

                ...reasons.map((reason) {
                  return RadioListTile<String>(
                    value: reason,
                    groupValue: selectedReason,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    title: Text(reason),
                    onChanged: (value) {
                      setSheetState(() => selectedReason = value!);
                    },
                  );
                }),

                const SizedBox(height: 8),

                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Details (optional)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(isSubmitting ? "Wird gesendet..." : "Meldung senden"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setSheetState(() => isSubmitting = true);

                            try {
                              await EventReportService.submitReport(
                                eventId: eventId,
                                eventName: eventName,
                                reason: selectedReason,
                                details: detailsController.text.trim(),
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Danke! Deine Meldung wurde übermittelt.",
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheetState(() => isSubmitting = false);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Fehler: $e"),
                                  ),
                                );
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}