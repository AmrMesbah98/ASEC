/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_status.dart
/// Purpose: Declares `CvStatus` — where a CV stands in the admin's review.
/// Author: ASEC team
/// Created: 20/9/2026

import 'package:flutter/widgets.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/generated/l10n.dart';

/// Set by the ADMIN, never by the owner — the member writes the CV, the admin
/// approves or rejects it.
///
/// 16/11/2026: the four ENGX states (Pending, Reviewed, Shortlisted,
/// Rejected) are now three — a new CV is Pending until the admin taps
/// Approve or Reject. CVs saved before keep working: "Shortlisted" reads as
/// Approved, "Reviewed" as Pending.
enum CvStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const CvStatus(this.key);

  final String key;

  static CvStatus fromKey(String? key) {
    for (final CvStatus status in CvStatus.values) {
      if (status.key == key) return status;
    }
    // The old review steps.
    if (key == 'Shortlisted') return CvStatus.approved;
    return CvStatus.pending;
  }

  Color get color {
    switch (this) {
      case CvStatus.pending:
        return AppColors.statusPending;
      case CvStatus.approved:
        return AppColors.green;
      case CvStatus.rejected:
        return AppColors.red;
    }
  }

  String label(BuildContext context) {
    final S s = S.of(context);
    switch (this) {
      case CvStatus.pending:
        return s.cvPending;
      case CvStatus.approved:
        return s.cvApproved;
      case CvStatus.rejected:
        return s.cvRejected;
    }
  }
}
