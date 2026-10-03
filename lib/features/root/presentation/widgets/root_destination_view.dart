import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/root_navigation_destination.dart';

class RootDestinationView extends StatelessWidget {
  const RootDestinationView({super.key, required this.destination});

  final RootNavigationDestination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing =
        theme.extension<AppSpacingThemeExtension>() ??
        const AppSpacingThemeExtension.regular();
    final motion =
        theme.extension<AppMotionThemeExtension>() ??
        const AppMotionThemeExtension.regular();

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.label,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: spacing.xxs),
                    Text(
                      _resolveDestinationSubtitle(destination),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(_resolveActionButtonLabel(destination)),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.radiusSm),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          _MetricCardsSection(
            destination: destination,
            spacing: spacing,
            motion: motion,
          ),
          SizedBox(height: spacing.lg),
          Text(
            'Recent updates',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: spacing.sm),
          _RecentItemsSection(destination: destination, spacing: spacing),
        ],
      ),
    );
  }

  String _resolveDestinationSubtitle(RootNavigationDestination destination) {
    switch (destination) {
      case RootNavigationDestination.dashboard:
        return 'Portfolio overview and urgent operational alerts';
      case RootNavigationDestination.properties:
        return 'Manage buildings, multi-family units, and vacant spaces';
      case RootNavigationDestination.tenants:
        return 'Active tenant leases, verifications, and histories';
      case RootNavigationDestination.maintenance:
        return 'Track contractor dispatches and resolve repair requests';
      case RootNavigationDestination.financials:
        return 'Rent collection, operating expenses, and accounts ledger';
    }
  }

  String _resolveActionButtonLabel(RootNavigationDestination destination) {
    switch (destination) {
      case RootNavigationDestination.dashboard:
        return 'New record';
      case RootNavigationDestination.properties:
        return 'Add property';
      case RootNavigationDestination.tenants:
        return 'Register tenant';
      case RootNavigationDestination.maintenance:
        return 'Submit request';
      case RootNavigationDestination.financials:
        return 'Create invoice';
    }
  }
}

class _MetricCardsSection extends StatelessWidget {
  const _MetricCardsSection({
    required this.destination,
    required this.spacing,
    required this.motion,
  });

  final RootNavigationDestination destination;
  final AppSpacingThemeExtension spacing;
  final AppMotionThemeExtension motion;

  @override
  Widget build(BuildContext context) {
    final metrics = _resolveMetrics(destination);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final cardWidth = isNarrow
            ? (constraints.maxWidth - spacing.sm) / 2
            : (constraints.maxWidth - (spacing.sm * 3)) / 4;

        return Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: cardWidth,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.title,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.slate500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: spacing.xs),
                        Text(
                          metric.value,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: spacing.xxs),
                        Text(
                          metric.subtitle,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: metric.isPositive
                                    ? AppColors.emerald600
                                    : AppColors.slate600,
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<_MetricItem> _resolveMetrics(RootNavigationDestination destination) {
    switch (destination) {
      case RootNavigationDestination.dashboard:
        return const [
          _MetricItem(
            title: 'Occupancy rate',
            value: '96.4%',
            subtitle: '+2.1% this month',
            isPositive: true,
          ),
          _MetricItem(
            title: 'Collected rent',
            value: '\$142,850',
            subtitle: '94% collected',
            isPositive: true,
          ),
          _MetricItem(
            title: 'Active requests',
            value: '6',
            subtitle: '2 urgent priority',
            isPositive: false,
          ),
          _MetricItem(
            title: 'Total units',
            value: '128',
            subtitle: '5 vacant units',
            isPositive: true,
          ),
        ];
      case RootNavigationDestination.properties:
        return const [
          _MetricItem(
            title: 'Total properties',
            value: '8',
            subtitle: 'All active',
            isPositive: true,
          ),
          _MetricItem(
            title: 'Total units',
            value: '128',
            subtitle: '123 occupied',
            isPositive: true,
          ),
          _MetricItem(
            title: 'Vacant units',
            value: '5',
            subtitle: 'Ready for lease',
            isPositive: true,
          ),
          _MetricItem(
            title: 'Average rent',
            value: '\$1,180',
            subtitle: 'Per unit / month',
            isPositive: true,
          ),
        ];
      case RootNavigationDestination.tenants:
        return const [
          _MetricItem(
            title: 'Active tenants',
            value: '121',
            subtitle: 'In good standing',
            isPositive: true,
          ),
          _MetricItem(
            title: 'Leases expiring',
            value: '4',
            subtitle: 'Next 30 days',
            isPositive: false,
          ),
          _MetricItem(
            title: 'Pending renewal',
            value: '3',
            subtitle: 'In review',
            isPositive: true,
          ),
          _MetricItem(
            title: 'New applications',
            value: '8',
            subtitle: 'Screening ready',
            isPositive: true,
          ),
        ];
      case RootNavigationDestination.maintenance:
        return const [
          _MetricItem(
            title: 'Open work orders',
            value: '6',
            subtitle: 'In progress',
            isPositive: false,
          ),
          _MetricItem(
            title: 'Urgent priority',
            value: '2',
            subtitle: 'Dispatch assigned',
            isPositive: false,
          ),
          _MetricItem(
            title: 'Resolved this week',
            value: '14',
            subtitle: 'On time resolution',
            isPositive: true,
          ),
          _MetricItem(
            title: 'Avg resolution',
            value: '18h',
            subtitle: 'SLA target met',
            isPositive: true,
          ),
        ];
      case RootNavigationDestination.financials:
        return const [
          _MetricItem(
            title: 'Monthly revenue',
            value: '\$142,850',
            subtitle: 'Rent roll volume',
            isPositive: true,
          ),
          _MetricItem(
            title: 'Outstanding arrears',
            value: '\$4,200',
            subtitle: '3 accounts overdue',
            isPositive: false,
          ),
          _MetricItem(
            title: 'Net cash flow',
            value: '\$98,400',
            subtitle: 'After operating costs',
            isPositive: true,
          ),
          _MetricItem(
            title: 'Operating expenses',
            value: '\$44,450',
            subtitle: 'Within budget target',
            isPositive: true,
          ),
        ];
    }
  }
}

class _RecentItemsSection extends StatelessWidget {
  const _RecentItemsSection({required this.destination, required this.spacing});

  final RootNavigationDestination destination;
  final AppSpacingThemeExtension spacing;

  @override
  Widget build(BuildContext context) {
    final items = _resolveRecentItems(destination);

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.xs),
            child: Material(
              color: Theme.of(context).cardTheme.color,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.slate200),
                borderRadius: BorderRadius.circular(spacing.radiusSm),
              ),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(spacing.radiusSm),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.md,
                    vertical: spacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(spacing.xs),
                        decoration: BoxDecoration(
                          color: item.badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(spacing.radiusSm),
                        ),
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: item.badgeColor,
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: spacing.xxs),
                            Text(
                              item.subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.slate500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      Text(
                        item.trailingText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<_RecentItem> _resolveRecentItems(RootNavigationDestination destination) {
    switch (destination) {
      case RootNavigationDestination.dashboard:
        return const [
          _RecentItem(
            title: 'Unit 4B - Rent received',
            subtitle: 'Payment confirmed via M-Pesa',
            trailingText: '\$1,250',
            badgeColor: AppColors.emerald600,
            icon: Icons.check_circle_outline_rounded,
          ),
          _RecentItem(
            title: 'Unit 12A - Water heater check',
            subtitle: 'Technician dispatched at 10:00 AM',
            trailingText: 'Urgent',
            badgeColor: AppColors.amber600,
            icon: Icons.build_circle_outlined,
          ),
          _RecentItem(
            title: 'Oakwood Court - Lease renewal',
            subtitle: 'Agreement signed by tenant',
            trailingText: 'Completed',
            badgeColor: AppColors.teal600,
            icon: Icons.assignment_turned_in_outlined,
          ),
        ];
      case RootNavigationDestination.properties:
        return const [
          _RecentItem(
            title: 'Highland Heights - Block A',
            subtitle: '32 units • 100% occupied',
            trailingText: 'Active',
            badgeColor: AppColors.teal600,
            icon: Icons.apartment_rounded,
          ),
          _RecentItem(
            title: 'Riverside Gardens - Unit 3C',
            subtitle: '2 bedroom • Vacant and inspected',
            trailingText: 'Available',
            badgeColor: AppColors.emerald600,
            icon: Icons.meeting_room_outlined,
          ),
          _RecentItem(
            title: 'Kilimani Plaza - Suite 104',
            subtitle: 'Commercial unit • Lease active',
            trailingText: 'Active',
            badgeColor: AppColors.teal600,
            icon: Icons.business_rounded,
          ),
        ];
      case RootNavigationDestination.tenants:
        return const [
          _RecentItem(
            title: 'Sarah Jenkins',
            subtitle: 'Unit 3A • Lease ends Nov 2026',
            trailingText: 'Verified',
            badgeColor: AppColors.emerald600,
            icon: Icons.person_outline_rounded,
          ),
          _RecentItem(
            title: 'David Mwangi',
            subtitle: 'Unit 7C • Rent balance clear',
            trailingText: 'Current',
            badgeColor: AppColors.teal600,
            icon: Icons.person_outline_rounded,
          ),
          _RecentItem(
            title: 'Elena Rostova',
            subtitle: 'Unit 12B • Renewal requested',
            trailingText: 'Pending',
            badgeColor: AppColors.amber600,
            icon: Icons.schedule_rounded,
          ),
        ];
      case RootNavigationDestination.maintenance:
        return const [
          _RecentItem(
            title: 'Plumbing leak in Unit 2B',
            subtitle: 'Vendor: Apex Repairs • Scheduled 2 PM',
            trailingText: 'In progress',
            badgeColor: AppColors.amber600,
            icon: Icons.plumbing_rounded,
          ),
          _RecentItem(
            title: 'HVAC filter inspection',
            subtitle: 'Common areas • Routine inspection',
            trailingText: 'Scheduled',
            badgeColor: AppColors.teal600,
            icon: Icons.hvac_rounded,
          ),
          _RecentItem(
            title: 'Intercom unit failure',
            subtitle: 'Gate entrance • Resolved by security tech',
            trailingText: 'Resolved',
            badgeColor: AppColors.emerald600,
            icon: Icons.task_alt_rounded,
          ),
        ];
      case RootNavigationDestination.financials:
        return const [
          _RecentItem(
            title: 'October Rent Batch #1',
            subtitle: '98 units settled to main account',
            trailingText: '\$118,500',
            badgeColor: AppColors.emerald600,
            icon: Icons.payments_outlined,
          ),
          _RecentItem(
            title: 'Elevator Maintenance Contract',
            subtitle: 'Invoice #INV-2026-44 • Paid',
            trailingText: '-\$1,800',
            badgeColor: AppColors.slate700,
            icon: Icons.receipt_long_outlined,
          ),
          _RecentItem(
            title: 'Property Insurance Premium',
            subtitle: 'Quarterly payment processed',
            trailingText: '-\$6,250',
            badgeColor: AppColors.slate700,
            icon: Icons.shield_outlined,
          ),
        ];
    }
  }
}

class _MetricItem {
  const _MetricItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.isPositive,
  });

  final String title;
  final String value;
  final String subtitle;
  final bool isPositive;
}

class _RecentItem {
  const _RecentItem({
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.badgeColor,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String trailingText;
  final Color badgeColor;
  final IconData icon;
}
