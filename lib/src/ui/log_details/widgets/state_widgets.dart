import 'package:flutter/material.dart';
import 'package:monitor/src/ui/theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          style: const TextStyle(color: CustomColors.outline, fontSize: 13),
        ),
      ),
    );
  }
}

class PendingState extends StatelessWidget {
  const PendingState({required this.url, super.key});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Waiting for response…',
              style: TextStyle(
                color: CustomColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              url,
              style: const TextStyle(
                color: CustomColors.outline,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingBlock extends StatelessWidget {
  const LoadingBlock({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CustomColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: CustomColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorBlock extends StatelessWidget {
  const ErrorBlock({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: CustomColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: SelectableText(
        message,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          height: 1.5,
          color: CustomColors.error,
        ),
      ),
    );
  }
}
