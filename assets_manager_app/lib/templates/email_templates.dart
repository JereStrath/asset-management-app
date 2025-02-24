class EmailTemplates {
  static String maintenanceNotification({
    required String assetName,
    required String maintenanceType,
    required String date,
    String? details,
  }) {
    return '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #2196F3;">Maintenance Notification</h2>
      <p>Scheduled maintenance for: <strong>$assetName</strong></p>
      <div style="background: #f5f5f5; padding: 15px; border-radius: 5px;">
        <p><strong>Type:</strong> $maintenanceType</p>
        <p><strong>Date:</strong> $date</p>
        ${details != null ? '<p><strong>Details:</strong> $details</p>' : ''}
      </div>
      <p style="color: #666;">Please ensure the asset is available for maintenance.</p>
    </div>
    ''';
  }

  static String transferNotification({
    required String assetName,
    required String fromLocation,
    required String toLocation,
    required String date,
  }) {
    return '''
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #2196F3;">Asset Transfer Notification</h2>
      <p>Asset transfer scheduled for: <strong>$assetName</strong></p>
      <div style="background: #f5f5f5; padding: 15px; border-radius: 5px;">
        <p><strong>From:</strong> $fromLocation</p>
        <p><strong>To:</strong> $toLocation</p>
        <p><strong>Date:</strong> $date</p>
      </div>
      <p style="color: #666;">Please ensure the asset is ready for transfer.</p>
    </div>
    ''';
  }
} 