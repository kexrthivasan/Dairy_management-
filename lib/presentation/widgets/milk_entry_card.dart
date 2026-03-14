import 'package:flutter/material.dart';
import '../../data/models/milk_entry.dart';
import 'package:intl/intl.dart';

class MilkEntryCard extends StatelessWidget {
  final MilkEntry record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MilkEntryCard({
    super.key,
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = DateFormat('EEEE, MMM dd').format(record.date);
    final yearStr = DateFormat('yyyy').format(record.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x4D000000) : const Color(0x0D000000), // 0.3 and 0.05 opacity on black
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Date and Delete
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              yearStr,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 26,
                        color: Colors.redAccent,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Delete Record',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 16),

                // Data Rows
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDataColumn(
                      context,
                      'Morning Milk',
                      '${record.morningMilk.toStringAsFixed(3)} L',
                      Icons.wb_sunny_rounded,
                      Colors.orange,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: theme.dividerColor.withOpacity(0.2),
                    ),
                    _buildDataColumn(
                      context,
                      'Evening Milk',
                      '${record.eveningMilk.toStringAsFixed(3)} L',
                      Icons.nights_stay_rounded,
                      Colors.indigo,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: theme.dividerColor.withOpacity(0.2),
                    ),
                    _buildDataColumn(
                      context,
                      'Total Milk',
                      '${record.totalYield.toStringAsFixed(3)} L',
                      Icons.water_drop_rounded,
                      theme.primaryColor,
                      isTotal: true,
                    ),
                  ],
                ),

                if (record.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blueGrey.withOpacity(0.2) : Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes,
                          size: 18,
                          color: Colors.blueGrey.shade400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            record.notes,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor, {
    bool isTotal = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      ],
    );
  }
}
