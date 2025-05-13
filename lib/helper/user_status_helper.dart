class UserStatusHelper {
  static String normalizeStatus(dynamic status) {
    if (status == null) return 'pending';

    final String statusString = status.toString().toLowerCase().trim();

    switch (statusString) {
      case 'pending':
      case 'new':
        return 'pending';
      case 'approved':
      case 'active':
        return 'approved';
      case 'rejected':
      case 'reject':
      case 'inactive':
        return 'rejected';
      default:
        return 'pending';
    }
  }

  static int safeIntConvert(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  static String mapStatusToFrontend(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'active':
        return 'Approved';
      case 'reject':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }
}