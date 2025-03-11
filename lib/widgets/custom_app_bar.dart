import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.surfaceVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (Navigator.of(context).canPop())
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.arrow_back),
                ),
              ),
            if (title != null)
              Expanded(
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'Kanit',
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            if (actions != null) ...[
              const SizedBox(width: 16),
              ...actions!.map((action) {
                if (action is IconButton) {
                  return Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: FilledButton.tonal(
                      onPressed: action.onPressed,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        shape: const CircleBorder(),
                      ),
                      child: action.icon,
                    ),
                  );
                }
                return action;
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
