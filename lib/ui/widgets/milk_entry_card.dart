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
    final dateStr = DateFormat('MMM dd, yyyy (EEEE)').format(record.date);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Date and Delete
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dateStr,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                      overflow: TextOverflow
                          .ellipsis, // Ensure it truncates if somehow still too big
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 28,
                      color: Colors.grey,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Delete Record',
                  ),
                ],
              ),
              const Divider(thickness: 2),
              const SizedBox(height: 8),

              // Data Rows
              Row(
                children: [
                  _buildDataColumn(
                    context,
                    'Morning',
                    '${record.morningMilk} L',
                    Icons.wb_sunny_outlined,
                  ),
                  _buildDataColumn(
                    context,
                    'Evening',
                    '${record.eveningMilk} L',
                    Icons.nightlight_round,
                  ),
                  _buildDataColumn(
                    context,
                    'Total',
                    '${record.totalYield} L',
                    Icons.water_drop,
                    isTotal: true,
                  ),
                ],
              ),

              if (record.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Note: ${record.notes}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isTotal = false,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: isTotal ? theme.primaryColor : Colors.grey.shade600,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal
                  ? theme.primaryColor
                  : theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
